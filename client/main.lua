local isOpen = false

local function notify(message)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(('~r~X Smart Evidence~s~: %s'):format(message))
    EndTextCommandThefeedPostTicker(false, false)
end

local function setOpen(state, payload)
    isOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({
        action = state and 'open' or 'close',
        payload = payload
    })
end

local function requestOpen()
    TriggerServerEvent('x_smart_evidence:server:requestOpen')
end

RegisterCommand(Config.OpenCommand, function()
    requestOpen()
end, false)

RegisterKeyMapping(Config.OpenCommand, 'Open X Smart Evidence', 'keyboard', Config.OpenKey)

RegisterNetEvent('x_smart_evidence:client:open', function(payload)
    setOpen(true, payload)
end)

RegisterNetEvent('x_smart_evidence:client:notify', function(message)
    notify(message)
end)

RegisterNUICallback('close', function(_, cb)
    setOpen(false)
    cb({ ok = true })
end)

RegisterNUICallback('getState', function(_, cb)
    TriggerServerEvent('x_smart_evidence:server:requestOpen')
    cb({ ok = true })
end)

RegisterNUICallback('createCase', function(data, cb)
    TriggerServerEvent('x_smart_evidence:server:createCase', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('createEvidence', function(data, cb)
    TriggerServerEvent('x_smart_evidence:server:createEvidence', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('updateEvidenceStatus', function(data, cb)
    TriggerServerEvent('x_smart_evidence:server:updateEvidenceStatus', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('addNote', function(data, cb)
    TriggerServerEvent('x_smart_evidence:server:addNote', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('checkoutEvidence', function(data, cb)
    TriggerServerEvent('x_smart_evidence:server:checkoutEvidence', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('returnEvidence', function(data, cb)
    TriggerServerEvent('x_smart_evidence:server:returnEvidence', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('releaseEvidence', function(data, cb)
    TriggerServerEvent('x_smart_evidence:server:releaseEvidence', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('destroyEvidence', function(data, cb)
    TriggerServerEvent('x_smart_evidence:server:destroyEvidence', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('search', function(data, cb)
    TriggerServerEvent('x_smart_evidence:server:search', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('getCase', function(data, cb)
    TriggerServerEvent('x_smart_evidence:server:getCase', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('getEvidence', function(data, cb)
    TriggerServerEvent('x_smart_evidence:server:getEvidence', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('deleteCase', function(data, cb)
    TriggerServerEvent('x_smart_evidence:server:deleteCase', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('deleteEvidence', function(data, cb)
    TriggerServerEvent('x_smart_evidence:server:deleteEvidence', data or {})
    cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        SetNuiFocus(false, false)
    end
end)
