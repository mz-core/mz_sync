MZSyncClock = {}

local function getHostTime()
    local offsetHours = tonumber(Config.Time.timezoneOffsetHours) or 0
    local now = os.date('!*t', os.time() + (offsetHours * 3600))
    return now.hour, now.min
end

local function getApiTime()
    local baseHour = MZSyncState.api.timeBaseHour
    local baseMinute = MZSyncState.api.timeBaseMinute
    local capturedAt = MZSyncState.api.timeCapturedAt

    if baseHour == nil or baseMinute == nil or not capturedAt or capturedAt <= 0 then
        return nil, nil
    end

    local elapsedMinutes = math.floor(math.max(0, os.time() - capturedAt) / 60)
    local totalMinutes = ((baseHour * 60) + baseMinute + elapsedMinutes) % (24 * 60)

    return math.floor(totalMinutes / 60), totalMinutes % 60
end

function MZSyncClock.Set(hour, minute)
    hour = tonumber(hour) or 12
    minute = tonumber(minute) or 0

    if hour < 0 then hour = 0 end
    if hour > 23 then hour = 23 end
    if minute < 0 then minute = 0 end
    if minute > 59 then minute = 59 end

    MZSyncState.time.hour = hour
    MZSyncState.time.minute = minute
end

function MZSyncClock.Advance(minutes)
    local total = (MZSyncState.time.hour * 60) + MZSyncState.time.minute + minutes
    total = total % (24 * 60)

    MZSyncState.time.hour = math.floor(total / 60)
    MZSyncState.time.minute = total % 60
end

function MZSyncClock.Tick()
    if not Config.Time.enabled then
        return
    end

    if MZSyncState.time.freeze then
        return
    end

    if MZSyncState.override.enabled and not MZSyncState.time.realtime then
        MZSyncClock.Advance(Config.Sync.clockStepMinutes)
        return
    end

    if MZSyncState.time.realtime and MZSyncState.api.enabled then
        local hour, minute = getApiTime()
        if hour ~= nil and minute ~= nil then
            MZSyncClock.Set(hour, minute)
            return
        end
    end

    if MZSyncState.time.realtime then
        local hour, minute = getHostTime()
        MZSyncClock.Set(hour, minute)
        return
    end

    MZSyncClock.Advance(Config.Sync.clockStepMinutes)
end
