local lastWeather = nil
local lastBlackout = nil

local function clearWeather()
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    lastWeather = nil
end

local function applyWeather(weather, transitionSeconds)
    if not weather then return end
    if lastWeather == weather then return end

    ClearOverrideWeather()
    ClearWeatherTypePersist()

    SetWeatherTypeOvertimePersist(weather, transitionSeconds or 15.0)
    SetWeatherTypeNowPersist(weather)
    SetWeatherTypePersist(weather)

    lastWeather = weather
end

local function applyBlackout(state)
    if lastBlackout == state then return end
    SetBlackout(state == true)
    lastBlackout = state
end

RegisterNetEvent('mz_sync:client:applySync', function(payload)
    if not payload or payload.enabled == false then
        return
    end

    if payload.timeEnabled and payload.hour ~= nil and payload.minute ~= nil then
        NetworkOverrideClockTime(payload.hour, payload.minute, 0)
    end

    if payload.weatherEnabled then
        applyWeather(payload.weather or 'CLEAR', payload.transitionSeconds or 15.0)
        applyBlackout(payload.blackout == true)
    else
        clearWeather()
        applyBlackout(false)
    end
end)

CreateThread(function()
    Wait(2500)
    TriggerServerEvent('mz_sync:server:requestSync')
end)
