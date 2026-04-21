WeatherMap = {}

-- Mapeamento por texto simples
WeatherMap.ByText = {
    ['sunny'] = 'EXTRASUNNY',
    ['clear'] = 'CLEAR',
    ['partly cloudy'] = 'CLOUDS',
    ['cloudy'] = 'CLOUDS',
    ['overcast'] = 'OVERCAST',
    ['mist'] = 'FOGGY',
    ['fog'] = 'FOGGY',
    ['patchy rain nearby'] = 'RAIN',
    ['light rain'] = 'RAIN',
    ['moderate rain'] = 'RAIN',
    ['heavy rain'] = 'THUNDER',
    ['thunder'] = 'THUNDER',
    ['storm'] = 'THUNDER',
}

-- Mapeamento por código do WeatherAPI
WeatherMap.ByCode = {
    [1000] = 'CLEAR',      -- Sunny / Clear
    [1003] = 'CLOUDS',     -- Partly cloudy
    [1006] = 'CLOUDS',     -- Cloudy
    [1009] = 'OVERCAST',   -- Overcast
    [1030] = 'FOGGY',      -- Mist
    [1063] = 'RAIN',
    [1066] = 'XMAS',
    [1069] = 'RAIN',
    [1072] = 'RAIN',
    [1087] = 'THUNDER',
    [1114] = 'XMAS',
    [1117] = 'XMAS',
    [1135] = 'FOGGY',
    [1147] = 'FOGGY',
    [1150] = 'RAIN',
    [1153] = 'RAIN',
    [1168] = 'RAIN',
    [1171] = 'RAIN',
    [1180] = 'RAIN',
    [1183] = 'RAIN',
    [1186] = 'RAIN',
    [1189] = 'RAIN',
    [1192] = 'THUNDER',
    [1195] = 'THUNDER',
    [1198] = 'RAIN',
    [1201] = 'RAIN',
    [1204] = 'RAIN',
    [1207] = 'XMAS',
    [1210] = 'XMAS',
    [1213] = 'XMAS',
    [1216] = 'XMAS',
    [1219] = 'XMAS',
    [1222] = 'XMAS',
    [1225] = 'XMAS',
    [1237] = 'XMAS',
    [1240] = 'RAIN',
    [1243] = 'RAIN',
    [1246] = 'THUNDER',
    [1249] = 'RAIN',
    [1252] = 'RAIN',
    [1255] = 'XMAS',
    [1258] = 'XMAS',
    [1261] = 'XMAS',
    [1264] = 'XMAS',
    [1273] = 'THUNDER',
    [1276] = 'THUNDER',
    [1279] = 'XMAS',
    [1282] = 'XMAS'
}

WeatherMap.ValidWeathers = {
    EXTRASUNNY = true,
    CLEAR = true,
    CLOUDS = true,
    OVERCAST = true,
    RAIN = true,
    CLEARING = true,
    THUNDER = true,
    SMOG = true,
    FOGGY = true,
    XMAS = true,
    HALLOWEEN = true,
    NEUTRAL = true
}