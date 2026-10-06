XSE = XSE or {}

function XSE.Trim(value)
    if type(value) ~= 'string' then return '' end
    return value:gsub('^%s+', ''):gsub('%s+$', '')
end

function XSE.ClampString(value, max)
    value = XSE.Trim(value)
    if #value > max then
        return value:sub(1, max)
    end
    return value
end

function XSE.SafeString(value, max)
    if value == nil then return '' end
    return XSE.ClampString(tostring(value), max)
end

function XSE.IsNonEmpty(value)
    return type(value) == 'string' and XSE.Trim(value) ~= ''
end

function XSE.ValidId(value)
    return type(value) == 'string' and value:match('^[%w%-_]+$') ~= nil
end

function XSE.GenerateId(prefix)
    local t = os.time()
    local random = math.random(100000, 999999)
    return ('%s-%d-%d'):format(prefix, t, random)
end

function XSE.Now()
    return os.date('!%Y-%m-%dT%H:%M:%SZ')
end
