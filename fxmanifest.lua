fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'mz_sync'
author 'Mazus'
description 'Sincronizacao de horario e clima do ecossistema mz_'
version '1.0.0'

shared_scripts {
    'shared/config.lua',
    'shared/weather_map.lua'
}

server_scripts {
    'server/services/state.lua',
    'server/services/clock.lua',
    'server/services/weather.lua',
    'server/services/provider_weatherapi.lua',
    'server/commands.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}
