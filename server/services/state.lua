local function buildSyncPayload()
    local payload = {
        enabled = MZSyncState.enabled,
        timeEnabled = Config.Time.enabled == true,
        weatherEnabled = Config.Weather.enabled == true
    }

    if payload.timeEnabled then
        payload.hour = MZSyncState.time.hour
        payload.minute = MZSyncState.time.minute
    end

    if payload.weatherEnabled then
        payload.weather = MZSyncState.weather.current
        payload.blackout = MZSyncState.weather.blackout
        payload.transitionSeconds = Config.Weather.transitionSeconds
    end

    return payload
end

MZSyncState = {
    enabled = true,

    time = {
        realtime = Config.Time.realtime,
        freeze = Config.Time.freeze,
        hour = Config.Time.defaultHour,
        minute = Config.Time.defaultMinute
    },

    weather = {
        dynamic = Config.Weather.dynamic,
        current = Config.Weather.defaultWeather,
        blackout = Config.Weather.blackout,
        sequenceIndex = 1,
        nextDynamicAt = 0
    },

    api = {
        enabled = Config.Api.enabled,
        provider = Config.Api.provider,
        location = Config.Api.location,
        lastFetch = 0,
        lastAttempt = 0,
        nextRetryAt = 0,
        lastPayload = nil,
        lastStatus = 'idle',
        inFlight = false,
        timeBaseHour = nil,
        timeBaseMinute = nil,
        timeCapturedAt = 0
    },

    override = {
        enabled = false
    }
}

function MZSyncLog(message)
    print(('[mz_sync] %s'):format(message))
end

function MZSyncDebug(message)
    if Config.Debug then
        print(('[mz_sync][debug] %s'):format(message))
    end
end

function MZSyncHasPermission(source)
    if source == 0 then
        return true
    end

    for _, ace in ipairs(Config.AllowedAces) do
        if IsPlayerAceAllowed(source, ace) then
            return true
        end
    end

    return false
end

function MZSyncNotifyDenied(source)
    TriggerClientEvent('chat:addMessage', source, {
        color = { 255, 80, 80 },
        args = { 'mz_sync', 'Você não tem permissão para usar este comando.' }
    })
end

function MZSyncReply(source, msg)
    if source == 0 then
        print(('[mz_sync] %s'):format(msg))
        return
    end

    TriggerClientEvent('chat:addMessage', source, {
        color = { 90, 200, 255 },
        args = { 'mz_sync', msg }
    })
end

function MZSyncBuildPayload()
    return buildSyncPayload()
end

function MZSyncPushSync(target)
    TriggerClientEvent('mz_sync:client:applySync', target or -1, buildSyncPayload())
end

function MZSyncRefreshState()
    if Config.Time.enabled and MZSyncClock and MZSyncClock.Tick then
        MZSyncClock.Tick()
    end
end
