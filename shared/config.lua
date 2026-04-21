Config = {}

Config.Debug = true
Config.CommandName = 'msync'

-- Permissões:
-- ajuste depois para integrar 100% com teu mz_core
Config.AllowedAces = {
    'mz_owner',
    'admin'
}

Config.Sync = {
    broadcastIntervalMs = 5000, -- frequência de sync para os clientes
    clockTickSeconds = 5,       -- avanço do relógio manual
    clockStepMinutes = 1        -- quantos minutos avançam por tick
}

Config.Time = {
    enabled = true,
    realtime = true,            -- usa hora real do host
    timezoneOffsetHours = -3,   -- fallback quando realtime=false ou ajuste manual
    freeze = false,
    defaultHour = 12,
    defaultMinute = 0
}

Config.Weather = {
    enabled = true,
    dynamic = true,             -- clima dinâmico local quando API estiver off e sem override
    dynamicIntervalMinutes = 20,
    transitionSeconds = 15.0,
    defaultWeather = 'CLEAR',
    blackout = false,

    -- para evitar maluquice em clima real
    allowThunder = true,
    allowSnow = false,
    fallbackWeather = 'CLEAR',

    sequence = {
        'EXTRASUNNY',
        'CLEAR',
        'CLOUDS',
        'OVERCAST',
        'CLEAR'
    }
}

Config.Api = {
    enabled = false,
    provider = 'weatherapi',
    key = 'SUA API KEY AQUI',
    location = 'Rio de Janeiro',
    endpoint = 'https://api.weatherapi.com/v1/current.json?key=%s&q=%s&lang=pt',
    fetchIntervalMinutes = 15
}
