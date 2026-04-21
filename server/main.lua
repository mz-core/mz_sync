RegisterNetEvent('mz_sync:server:requestSync', function()
    local src = source
    MZSyncRefreshState()
    MZSyncPushSync(src)
end)

CreateThread(function()
    MZSyncLog('resource started')
    MZSyncClock.Set(Config.Time.defaultHour, Config.Time.defaultMinute)
    MZSyncWeather.Set(Config.Weather.defaultWeather)
    MZSyncRefreshState()
end)

CreateThread(function()
    while true do
        Wait(Config.Sync.clockTickSeconds * 1000)
        MZSyncClock.Tick()
    end
end)

CreateThread(function()
    while true do
        Wait(5000)
        MZSyncWeather.Tick()
        MZSyncProviderWeatherApi.Tick()
    end
end)

CreateThread(function()
    while true do
        Wait(Config.Sync.broadcastIntervalMs)
        MZSyncRefreshState()
        MZSyncPushSync()
    end
end)

AddEventHandler('playerJoining', function()
    local src = source
    MZSyncRefreshState()
    MZSyncPushSync(src)
end)
