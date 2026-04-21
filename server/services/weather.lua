MZSyncWeather = {}

local function syncSequenceIndex(weather)
    local seq = Config.Weather.sequence

    if not seq or #seq == 0 then
        MZSyncState.weather.sequenceIndex = 0
        return
    end

    for index, weatherType in ipairs(seq) do
        if string.upper(tostring(weatherType)) == weather then
            MZSyncState.weather.sequenceIndex = index
            return
        end
    end

    MZSyncState.weather.sequenceIndex = 0
end

local function normalizeWeather(weather)
    if not weather then
        return Config.Weather.fallbackWeather
    end

    weather = string.upper(tostring(weather))

    if WeatherMap.ValidWeathers[weather] then
        return weather
    end

    return Config.Weather.fallbackWeather
end

function MZSyncWeather.Set(weather)
    MZSyncState.weather.current = normalizeWeather(weather)
    syncSequenceIndex(MZSyncState.weather.current)
end

function MZSyncWeather.SetBlackout(state)
    MZSyncState.weather.blackout = state == true
end

function MZSyncWeather.NextDynamic()
    local seq = Config.Weather.sequence
    if not seq or #seq == 0 then
        return
    end

    local idx = MZSyncState.weather.sequenceIndex + 1
    if idx > #seq then
        idx = 1
    end

    MZSyncState.weather.sequenceIndex = idx
    MZSyncWeather.Set(seq[idx])
end

function MZSyncWeather.Tick()
    if not Config.Weather.enabled then
        return
    end

    if MZSyncState.override.enabled then
        return
    end

    if MZSyncState.api.enabled then
        return
    end

    if not MZSyncState.weather.dynamic then
        return
    end

    local now = os.time()

    if MZSyncState.weather.nextDynamicAt == 0 then
        MZSyncState.weather.nextDynamicAt = now + (Config.Weather.dynamicIntervalMinutes * 60)
        return
    end

    if now >= MZSyncState.weather.nextDynamicAt then
        MZSyncWeather.NextDynamic()
        MZSyncState.weather.nextDynamicAt = now + (Config.Weather.dynamicIntervalMinutes * 60)
        MZSyncDebug(('dynamic weather changed to %s'):format(MZSyncState.weather.current))
    end
end

function MZSyncWeather.ResolveFromApiPayload(payload)
    if not payload or not payload.current or not payload.current.condition then
        return Config.Weather.fallbackWeather
    end

    local code = payload.current.condition.code
    local text = payload.current.condition.text

    local mapped = WeatherMap.ByCode[tonumber(code or -1)]

    if not mapped and text then
        mapped = WeatherMap.ByText[string.lower(text)]
    end

    mapped = mapped or Config.Weather.fallbackWeather

    if mapped == 'THUNDER' and not Config.Weather.allowThunder then
        mapped = 'RAIN'
    end

    if (mapped == 'XMAS') and not Config.Weather.allowSnow then
        mapped = Config.Weather.fallbackWeather
    end

    return normalizeWeather(mapped)
end
