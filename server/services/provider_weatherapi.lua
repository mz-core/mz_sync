MZSyncProviderWeatherApi = {}

local function getCooldownSeconds()
    local minutes = tonumber(Config.Api.fetchIntervalMinutes) or 15
    return math.max(60, math.floor(minutes * 60))
end

local function urlEncode(str)
    str = tostring(str or '')
    str = str:gsub('\n', '\r\n')
    str = str:gsub('([^%w ])', function(c)
        return string.format('%%%02X', string.byte(c))
    end)
    str = str:gsub(' ', '%%20')
    return str
end

local function scheduleNextAttempt()
    local now = os.time()
    MZSyncState.api.lastAttempt = now
    MZSyncState.api.nextRetryAt = now + getCooldownSeconds()
end

local function setApiClockBase(payload)
    if not payload or not payload.location or not payload.location.localtime then
        return
    end

    local hour, minute = string.match(payload.location.localtime, '(%d+):(%d+)$')
    if not hour or not minute then
        return
    end

    MZSyncState.api.timeBaseHour = tonumber(hour)
    MZSyncState.api.timeBaseMinute = tonumber(minute)
    MZSyncState.api.timeCapturedAt = os.time()
end

function MZSyncProviderWeatherApi.Fetch(cb, opts)
    opts = opts or {}

    local force = opts.force == true
    local now = os.time()
    local provider = tostring(MZSyncState.api.provider or Config.Api.provider or 'weatherapi'):lower()

    if MZSyncState.api.inFlight and not force then
        if cb then cb(false, 'in_progress') end
        return
    end

    if not force and MZSyncState.api.nextRetryAt > now then
        if cb then cb(false, 'cooldown') end
        return
    end

    scheduleNextAttempt()

    if provider ~= 'weatherapi' then
        MZSyncState.api.lastStatus = 'unsupported_provider'
        if cb then cb(false, 'unsupported_provider') end
        return
    end

    if Config.Api.key == 'COLOQUE_SUA_KEY_AQUI' or Config.Api.key == '' then
        MZSyncState.api.lastStatus = 'missing_key'
        MZSyncDebug('api fetch skipped: missing api key')
        if cb then cb(false, 'missing_key') end
        return
    end

    MZSyncState.api.inFlight = true
    local location = MZSyncState.api.location or Config.Api.location
    local endpoint = Config.Api.endpoint:format(Config.Api.key, urlEncode(location))

    MZSyncState.api.lastStatus = 'fetching'

    PerformHttpRequest(endpoint, function(statusCode, body, headers)
        MZSyncState.api.inFlight = false

        if statusCode ~= 200 or not body then
            MZSyncState.api.lastStatus = ('http_%s'):format(statusCode or 'unknown')
            MZSyncDebug(('api fetch failed: status=%s'):format(statusCode or 'nil'))
            if cb then cb(false, MZSyncState.api.lastStatus) end
            return
        end

        local ok, data = pcall(function()
            return json.decode(body)
        end)

        if not ok or not data then
            MZSyncState.api.lastStatus = 'invalid_json'
            MZSyncDebug('api fetch failed: invalid json')
            if cb then cb(false, 'invalid_json') end
            return
        end

        MZSyncState.api.lastFetch = os.time()
        MZSyncState.api.lastPayload = data
        MZSyncState.api.lastStatus = 'ok'
        setApiClockBase(data)

        if cb then cb(true, data) end
    end, 'GET', '', {
        ['Content-Type'] = 'application/json'
    })
end

function MZSyncProviderWeatherApi.Tick()
    if not MZSyncState.api.enabled then
        return
    end

    if not Config.Weather.enabled and not (Config.Time.enabled and MZSyncState.time.realtime) then
        return
    end

    MZSyncProviderWeatherApi.Fetch(function(success, result)
        if not success then
            if result ~= 'cooldown' and result ~= 'in_progress' then
                MZSyncDebug(('api tick fetch failed: %s'):format(result))
            end
            return
        end

        if Config.Weather.enabled and not MZSyncState.override.enabled then
            local weather = MZSyncWeather.ResolveFromApiPayload(result)
            MZSyncWeather.Set(weather)
        end

        MZSyncRefreshState()
        MZSyncPushSync()

        MZSyncDebug(('api updated weather=%s location=%s'):format(
            tostring(MZSyncState.weather.current),
            tostring(MZSyncState.api.location)
        ))
    end)
end
