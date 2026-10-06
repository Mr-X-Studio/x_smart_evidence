local DB = {
    cases = {},
    evidence = {},
    audit = {},
    meta = {
        version = 1,
        nextCaseNumber = 1
    }
}

math.randomseed(os.time())

local function now()
    return os.date('!%Y-%m-%dT%H:%M:%SZ')
end

local function notify(src, message)
    TriggerClientEvent('x_smart_evidence:client:notify', src, message)
end

local function playerName(src)
    if src == 0 then return 'CONSOLE' end
    local name = GetPlayerName(src)
    return name or ('Player %s'):format(src)
end

local function authorized(src)
    if src == 0 then return true end
    if not Config.RequireAce then return true end
    return IsPlayerAceAllowed(src, Config.AcePermission)
end

local function ensureAuth(src)
    if not authorized(src) then
        notify(src, 'You do not have permission to use this system.')
        return false
    end
    return true
end

local function save()
    local payload = json.encode(DB)
    SaveResourceFile(GetCurrentResourceName(), Config.StorageFile, payload, -1)
end

local function load()
    local raw = LoadResourceFile(GetCurrentResourceName(), Config.StorageFile)
    if raw and raw ~= '' then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == 'table' then
            DB = decoded
        end
    end

    DB.cases = DB.cases or {}
    DB.evidence = DB.evidence or {}
    DB.audit = DB.audit or {}
    DB.meta = DB.meta or {}
    DB.meta.version = DB.meta.version or 1
    DB.meta.nextCaseNumber = DB.meta.nextCaseNumber or 1

    save()
end

local function audit(src, action, targetType, targetId, details)
    if not Config.Audit.enabled then return end

    table.insert(DB.audit, 1, {
        id = ('AUD-%d-%d'):format(os.time(), math.random(1000, 9999)),
        timestamp = now(),
        actor = {
            source = src,
            name = playerName(src)
        },
        action = action,
        targetType = targetType,
        targetId = targetId,
        details = details or ''
    })

    while #DB.audit > Config.Audit.maxEntries do
        table.remove(DB.audit)
    end
end

local function cleanText(value, max)
    if type(value) ~= 'string' then return '' end
    value = value:gsub('[%c]', ' ')
    value = value:gsub('^%s+', ''):gsub('%s+$', '')
    if #value > max then value = value:sub(1, max) end
    return value
end

local function validEvidenceType(value)
    for _, item in ipairs(Config.EvidenceTypes) do
        if item.value == value then return true end
    end
    return false
end

local function validStatus(value)
    for _, item in ipairs(Config.EvidenceStatuses) do
        if item.value == value then return true end
    end
    return false
end

local function nextCaseNumber()
    local number = DB.meta.nextCaseNumber or 1
    DB.meta.nextCaseNumber = number + 1
    return ('%s-%04d'):format(Config.CaseNumberPrefix, number)
end

local function countEvidenceForCase(caseId)
    local count = 0
    for _, item in pairs(DB.evidence) do
        if item.caseId == caseId then count = count + 1 end
    end
    return count
end

local function sanitizeCase(input)
    return {
        title = cleanText(input.title, Config.MaxTitleLength),
        description = cleanText(input.description, Config.MaxDescriptionLength),
        location = cleanText(input.location, 100),
        priority = cleanText(input.priority, 20)
    }
end

local function sanitizeEvidence(input)
    return {
        caseId = cleanText(input.caseId, 50),
        type = cleanText(input.type, 30),
        title = cleanText(input.title, Config.MaxTitleLength),
        description = cleanText(input.description, Config.MaxDescriptionLength),
        location = cleanText(input.location, 100),
        serial = cleanText(input.serial, 100),
        quantity = math.max(1, math.min(999999, tonumber(input.quantity) or 1)),
        tags = cleanText(input.tags, 200)
    }
end

local function pushCustody(item, src, action, note)
    item.custody = item.custody or {}
    table.insert(item.custody, 1, {
        id = XSE.GenerateId('CUS'),
        timestamp = now(),
        action = action,
        actor = playerName(src),
        source = src,
        note = cleanText(note or '', Config.MaxNoteLength)
    })
    while #item.custody > Config.MaxCustodyEntries do
        table.remove(item.custody)
    end
end

RegisterNetEvent('x_smart_evidence:server:requestOpen', function()
    local src = source
    if not ensureAuth(src) then return end

    TriggerClientEvent('x_smart_evidence:client:open', src, {
        cases = DB.cases,
        evidence = DB.evidence,
        audit = DB.audit,
        types = Config.EvidenceTypes,
        statuses = Config.EvidenceStatuses,
        locations = Config.DefaultLocations,
        brand = Config.Brand,
        permissions = {
            canDelete = IsPlayerAceAllowed(src, Config.AcePermission .. '.admin'),
            canDestroy = IsPlayerAceAllowed(src, Config.AcePermission .. '.destroy')
        }
    })
end)

RegisterNetEvent('x_smart_evidence:server:createCase', function(input)
    local src = source
    if not ensureAuth(src) then return end

    if #DB.cases >= Config.MaxCases then
        notify(src, 'The configured case limit has been reached.')
        return
    end

    input = input or {}
    local data = sanitizeCase(input)

    if data.title == '' then
        notify(src, 'Case title is required.')
        return
    end

    local id = XSE.GenerateId('CASE')
    local case = {
        id = id,
        caseNumber = Config.AutoCaseNumber and nextCaseNumber() or id,
        title = data.title,
        description = data.description,
        location = data.location,
        priority = data.priority ~= '' and data.priority or 'normal',
        status = 'open',
        createdAt = now(),
        createdBy = playerName(src),
        evidenceCount = 0
    }

    table.insert(DB.cases, 1, case)
    audit(src, 'CASE_CREATED', 'case', id, case.title)
    save()

    notify(src, ('Case %s created.'):format(case.caseNumber))
    TriggerClientEvent('x_smart_evidence:client:open', src, {
        cases = DB.cases,
        evidence = DB.evidence,
        audit = DB.audit,
        types = Config.EvidenceTypes,
        statuses = Config.EvidenceStatuses,
        locations = Config.DefaultLocations,
        brand = Config.Brand
    })
end)

RegisterNetEvent('x_smart_evidence:server:createEvidence', function(input)
    local src = source
    if not ensureAuth(src) then return end

    input = input or {}
    local data = sanitizeEvidence(input)

    if data.caseId == '' or not XSE.IsNonEmpty(data.title) or not validEvidenceType(data.type) then
        notify(src, 'Case, evidence type, and title are required.')
        return
    end

    local case
    for _, c in ipairs(DB.cases) do
        if c.id == data.caseId then case = c break end
    end

    if not case then
        notify(src, 'The selected case does not exist.')
        return
    end

    if countEvidenceForCase(data.caseId) >= Config.MaxEvidencePerCase then
        notify(src, 'This case has reached the evidence limit.')
        return
    end

    local id = XSE.GenerateId('EVD')
    local item = {
        id = id,
        evidenceNumber = ('E-%06d'):format(math.random(100000, 999999)),
        caseId = data.caseId,
        type = data.type,
        title = data.title,
        description = data.description,
        location = data.location ~= '' and data.location or Config.DefaultLocations[1],
        serial = data.serial,
        quantity = data.quantity,
        tags = data.tags,
        status = 'stored',
        createdAt = now(),
        createdBy = playerName(src),
        checkedOutBy = nil,
        checkedOutAt = nil,
        custody = {}
    }

    pushCustody(item, src, 'COLLECTED', 'Evidence created and entered into X Smart Evidence.')

    DB.evidence[id] = item
    case.evidenceCount = countEvidenceForCase(data.caseId)

    audit(src, 'EVIDENCE_CREATED', 'evidence', id, item.title)
    save()

    notify(src, ('Evidence %s added.'):format(item.evidenceNumber))
    TriggerClientEvent('x_smart_evidence:client:open', src, {
        cases = DB.cases,
        evidence = DB.evidence,
        audit = DB.audit,
        types = Config.EvidenceTypes,
        statuses = Config.EvidenceStatuses,
        locations = Config.DefaultLocations,
        brand = Config.Brand
    })
end)

local function getEvidence(id)
    if type(id) ~= 'string' then return nil end
    return DB.evidence[id]
end

RegisterNetEvent('x_smart_evidence:server:updateEvidenceStatus', function(input)
    local src = source
    if not ensureAuth(src) then return end

    local item = getEvidence(input and input.id)
    local status = input and cleanText(input.status, 30) or ''

    if not item or not validStatus(status) then
        notify(src, 'Invalid evidence or status.')
        return
    end

    item.status = status
    pushCustody(item, src, ('STATUS_%s'):format(status:upper()), cleanText(input.note or '', Config.MaxNoteLength))
    audit(src, 'EVIDENCE_STATUS', 'evidence', item.id, status)
    save()
    notify(src, 'Evidence status updated.')
    TriggerClientEvent('x_smart_evidence:client:open', src, {
        cases = DB.cases, evidence = DB.evidence, audit = DB.audit,
        types = Config.EvidenceTypes, statuses = Config.EvidenceStatuses,
        locations = Config.DefaultLocations, brand = Config.Brand
    })
end)

RegisterNetEvent('x_smart_evidence:server:addNote', function(input)
    local src = source
    if not ensureAuth(src) then return end

    local item = getEvidence(input and input.id)
    local note = cleanText(input and input.note or '', Config.MaxNoteLength)

    if not item or note == '' then
        notify(src, 'Evidence and note are required.')
        return
    end

    pushCustody(item, src, 'NOTE_ADDED', note)
    audit(src, 'NOTE_ADDED', 'evidence', item.id, note)
    save()
    notify(src, 'Note added.')
    TriggerClientEvent('x_smart_evidence:client:open', src, {
        cases = DB.cases, evidence = DB.evidence, audit = DB.audit,
        types = Config.EvidenceTypes, statuses = Config.EvidenceStatuses,
        locations = Config.DefaultLocations, brand = Config.Brand
    })
end)

RegisterNetEvent('x_smart_evidence:server:checkoutEvidence', function(input)
    local src = source
    if not ensureAuth(src) then return end

    local item = getEvidence(input and input.id)
    if not item then notify(src, 'Evidence not found.'); return end
    if item.status ~= 'stored' then notify(src, 'Only stored evidence can be checked out.'); return end

    item.status = 'checked_out'
    item.checkedOutBy = playerName(src)
    item.checkedOutAt = now()
    pushCustody(item, src, 'CHECKED_OUT', cleanText(input.note or '', Config.MaxNoteLength))
    audit(src, 'EVIDENCE_CHECKOUT', 'evidence', item.id, item.title)
    save()
    notify(src, 'Evidence checked out.')
    TriggerClientEvent('x_smart_evidence:client:open', src, {
        cases = DB.cases, evidence = DB.evidence, audit = DB.audit,
        types = Config.EvidenceTypes, statuses = Config.EvidenceStatuses,
        locations = Config.DefaultLocations, brand = Config.Brand
    })
end)

RegisterNetEvent('x_smart_evidence:server:returnEvidence', function(input)
    local src = source
    if not ensureAuth(src) then return end

    local item = getEvidence(input and input.id)
    if not item then notify(src, 'Evidence not found.'); return end
    if item.status ~= 'checked_out' then notify(src, 'Evidence is not checked out.'); return end

    item.status = 'stored'
    item.checkedOutBy = nil
    item.checkedOutAt = nil
    pushCustody(item, src, 'RETURNED', cleanText(input.note or '', Config.MaxNoteLength))
    audit(src, 'EVIDENCE_RETURNED', 'evidence', item.id, item.title)
    save()
    notify(src, 'Evidence returned to storage.')
    TriggerClientEvent('x_smart_evidence:client:open', src, {
        cases = DB.cases, evidence = DB.evidence, audit = DB.audit,
        types = Config.EvidenceTypes, statuses = Config.EvidenceStatuses,
        locations = Config.DefaultLocations, brand = Config.Brand
    })
end)

RegisterNetEvent('x_smart_evidence:server:releaseEvidence', function(input)
    local src = source
    if not ensureAuth(src) then return end

    local item = getEvidence(input and input.id)
    if not item then notify(src, 'Evidence not found.'); return end
    if item.status == 'destroyed' then notify(src, 'Destroyed evidence cannot be released.'); return end

    item.status = 'released'
    pushCustody(item, src, 'RELEASED', cleanText(input.note or '', Config.MaxNoteLength))
    audit(src, 'EVIDENCE_RELEASED', 'evidence', item.id, item.title)
    save()
    notify(src, 'Evidence marked as released.')
    TriggerClientEvent('x_smart_evidence:client:open', src, {
        cases = DB.cases, evidence = DB.evidence, audit = DB.audit,
        types = Config.EvidenceTypes, statuses = Config.EvidenceStatuses,
        locations = Config.DefaultLocations, brand = Config.Brand
    })
end)

RegisterNetEvent('x_smart_evidence:server:destroyEvidence', function(input)
    local src = source
    if not authorized(src) or not IsPlayerAceAllowed(src, Config.AcePermission .. '.destroy') then
        notify(src, 'You do not have permission to destroy evidence.')
        return
    end

    local item = getEvidence(input and input.id)
    if not item then notify(src, 'Evidence not found.'); return end

    item.status = 'destroyed'
    item.checkedOutBy = nil
    item.checkedOutAt = nil
    pushCustody(item, src, 'DESTROYED', cleanText(input.note or '', Config.MaxNoteLength))
    audit(src, 'EVIDENCE_DESTROYED', 'evidence', item.id, item.title)
    save()
    notify(src, 'Evidence marked as destroyed.')
    TriggerClientEvent('x_smart_evidence:client:open', src, {
        cases = DB.cases, evidence = DB.evidence, audit = DB.audit,
        types = Config.EvidenceTypes, statuses = Config.EvidenceStatuses,
        locations = Config.DefaultLocations, brand = Config.Brand
    })
end)

RegisterNetEvent('x_smart_evidence:server:search', function(input)
    local src = source
    if not ensureAuth(src) then return end

    local q = cleanText(input and input.query or '', Config.MaxSearchLength):lower()
    local results = {}

    if q == '' then
        TriggerClientEvent('x_smart_evidence:client:searchResults', src, results)
        return
    end

    for _, c in ipairs(DB.cases) do
        local hay = table.concat({c.caseNumber or '', c.title or '', c.description or '', c.location or ''}, ' '):lower()
        if hay:find(q, 1, true) then
            table.insert(results, { kind = 'case', data = c })
        end
    end

    for _, item in pairs(DB.evidence) do
        local hay = table.concat({
            item.evidenceNumber or '', item.title or '', item.description or '',
            item.serial or '', item.tags or '', item.type or ''
        }, ' '):lower()
        if hay:find(q, 1, true) then
            table.insert(results, { kind = 'evidence', data = item })
        end
    end

    TriggerClientEvent('x_smart_evidence:client:searchResults', src, results)
end)

RegisterNetEvent('x_smart_evidence:server:getCase', function(input)
    local src = source
    if not ensureAuth(src) then return end

    for _, c in ipairs(DB.cases) do
        if c.id == input.id then
            TriggerClientEvent('x_smart_evidence:client:caseResult', src, c)
            return
        end
    end
    notify(src, 'Case not found.')
end)

RegisterNetEvent('x_smart_evidence:server:getEvidence', function(input)
    local src = source
    if not ensureAuth(src) then return end

    local item = getEvidence(input and input.id)
    if item then
        TriggerClientEvent('x_smart_evidence:client:evidenceResult', src, item)
    else
        notify(src, 'Evidence not found.')
    end
end)

RegisterNetEvent('x_smart_evidence:server:deleteCase', function(input)
    local src = source
    if not authorized(src) or not IsPlayerAceAllowed(src, Config.AcePermission .. '.admin') then
        notify(src, 'You do not have permission to delete cases.')
        return
    end

    local id = input and input.id
    local hasEvidence = false
    for _, item in pairs(DB.evidence) do
        if item.caseId == id then hasEvidence = true break end
    end
    if hasEvidence then
        notify(src, 'Remove or reassign evidence before deleting this case.')
        return
    end

    for i, c in ipairs(DB.cases) do
        if c.id == id then
            audit(src, 'CASE_DELETED', 'case', id, c.title)
            table.remove(DB.cases, i)
            save()
            notify(src, 'Case deleted.')
            return
        end
    end
end)

RegisterNetEvent('x_smart_evidence:server:deleteEvidence', function(input)
    local src = source
    if not authorized(src) or not IsPlayerAceAllowed(src, Config.AcePermission .. '.admin') then
        notify(src, 'You do not have permission to delete evidence.')
        return
    end

    local id = input and input.id
    local item = getEvidence(id)
    if not item then notify(src, 'Evidence not found.'); return end
    if item.status ~= 'destroyed' then
        notify(src, 'Evidence must be destroyed before it can be permanently deleted.')
        return
    end

    audit(src, 'EVIDENCE_DELETED', 'evidence', id, item.title)
    DB.evidence[id] = nil
    save()
    notify(src, 'Evidence permanently deleted.')
end)

-- Exports for integrations / custom MDTs.
exports('GetCase', function(caseId)
    for _, c in ipairs(DB.cases) do
        if c.id == caseId then return c end
    end
    return nil
end)

exports('GetEvidence', function(evidenceId)
    return DB.evidence[evidenceId]
end)

exports('GetAllCases', function()
    return DB.cases
end)

exports('GetAllEvidence', function()
    return DB.evidence
end)

exports('CreateCase', function(data, actorName)
    if type(data) ~= 'table' then return nil, 'invalid_data' end
    local title = cleanText(data.title, Config.MaxTitleLength)
    if title == '' then return nil, 'title_required' end

    local id = XSE.GenerateId('CASE')
    local c = {
        id = id,
        caseNumber = Config.AutoCaseNumber and nextCaseNumber() or id,
        title = title,
        description = cleanText(data.description, Config.MaxDescriptionLength),
        location = cleanText(data.location, 100),
        priority = cleanText(data.priority, 20),
        status = 'open',
        createdAt = now(),
        createdBy = actorName or 'Integration',
        evidenceCount = 0
    }
    table.insert(DB.cases, 1, c)
    audit(0, 'CASE_CREATED_EXPORT', 'case', id, title)
    save()
    return c
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    load()
    print(('[X Smart Evidence] %d cases / %d evidence records loaded.'):format(#DB.cases, #DB.evidence))
end)
