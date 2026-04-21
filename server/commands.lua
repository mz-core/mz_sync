local cmd = Config.CommandName

local function parseOnOff(value)
    value = tostring(value or ''):lower()
    if value == 'on' then return true end
    if value == 'off' then return false end
    return nil
end

local function boolText(v)
    return v and 'on' or 'off'
end

local function syncNow(target)
    MZSyncRefreshState()
    MZSyncPushSync(target or -1)
end

local function statusText()
    return table.concat({
        ('override=%s'):format(boolText(MZSyncState.override.enabled)),
        ('api=%s'):format(boolText(MZSyncState.api.enabled)),
        ('realtimeTime=%s'):format(boolText(MZSyncState.time.realtime)),
        ('freezeTime=%s'):format(boolText(MZSyncState.time.freeze)),
        ('dynamicWeather=%s'):format(boolText(MZSyncState.weather.dynamic)),
        ('weather=%s'):format(MZSyncState.weather.current),
        ('time=%02d:%02d'):format(MZSyncState.time.hour, MZSyncState.time.minute),
        ('blackout=%s'):format(boolText(MZSyncState.weather.blackout)),
        ('apiStatus=%s'):format(tostring(MZSyncState.api.lastStatus))
    }, ' | ')
end

RegisterCommand(cmd, function(source, args)
    if not MZSyncHasPermission(source) then
        MZSyncNotifyDenied(source)
        return
    end

    local sub = tostring(args[1] or 'help'):lower()

    if sub == 'help' then
        MZSyncReply(source, '/' .. cmd .. ' status')
        MZSyncReply(source, '/' .. cmd .. ' time <hora> <min>')
        MZSyncReply(source, '/' .. cmd .. ' freeze_time <on|off>')
        MZSyncReply(source, '/' .. cmd .. ' realtime_time <on|off>')
        MZSyncReply(source, '/' .. cmd .. ' weather <tipo>')
        MZSyncReply(source, '/' .. cmd .. ' dynamic_weather <on|off>')
        MZSyncReply(source, '/' .. cmd .. ' blackout <on|off>')
        MZSyncReply(source, '/' .. cmd .. ' api <on|off|refresh>')
        MZSyncReply(source, '/' .. cmd .. ' api_location <cidade>')
        MZSyncReply(source, '/' .. cmd .. ' override <on|off>')
        MZSyncReply(source, '/' .. cmd .. ' halloween <on|off>')
        MZSyncReply(source, '/' .. cmd .. ' storm <on|off>')
        return
    end

    if sub == 'status' then
        MZSyncReply(source, statusText())
        return
    end

    if sub == 'time' then
        local hour = tonumber(args[2])
        local minute = tonumber(args[3])

        if not hour or not minute then
            MZSyncReply(source, 'Uso: /' .. cmd .. ' time <hora> <min>')
            return
        end

        MZSyncState.time.realtime = false
        MZSyncClock.Set(hour, minute)
        syncNow()
        MZSyncReply(source, ('Hora definida para %02d:%02d'):format(MZSyncState.time.hour, MZSyncState.time.minute))
        return
    end

    if sub == 'freeze_time' then
        local state = parseOnOff(args[2])
        if state == nil then
            MZSyncReply(source, 'Uso: /' .. cmd .. ' freeze_time <on|off>')
            return
        end

        MZSyncState.time.freeze = state
        syncNow()
        MZSyncReply(source, 'freeze_time: ' .. boolText(state))
        return
    end

    if sub == 'realtime_time' then
        local state = parseOnOff(args[2])
        if state == nil then
            MZSyncReply(source, 'Uso: /' .. cmd .. ' realtime_time <on|off>')
            return
        end

        MZSyncState.time.realtime = state
        syncNow()
        MZSyncReply(source, 'realtime_time: ' .. boolText(state))
        return
    end

    if sub == 'weather' then
        local weather = args[2]
        if not weather then
            MZSyncReply(source, 'Uso: /' .. cmd .. ' weather <tipo>')
            return
        end

        MZSyncState.api.enabled = false
        MZSyncState.weather.dynamic = false
        MZSyncWeather.Set(weather)
        syncNow()
        MZSyncReply(source, 'Weather definido para: ' .. MZSyncState.weather.current)
        return
    end

    if sub == 'dynamic_weather' then
        local state = parseOnOff(args[2])
        if state == nil then
            MZSyncReply(source, 'Uso: /' .. cmd .. ' dynamic_weather <on|off>')
            return
        end

        MZSyncState.weather.dynamic = state
        if state then
            MZSyncState.weather.nextDynamicAt = 0
        end
        syncNow()
        MZSyncReply(source, 'dynamic_weather: ' .. boolText(state))
        return
    end

    if sub == 'blackout' then
        local state = parseOnOff(args[2])
        if state == nil then
            MZSyncReply(source, 'Uso: /' .. cmd .. ' blackout <on|off>')
            return
        end

        MZSyncWeather.SetBlackout(state)
        syncNow()
        MZSyncReply(source, 'blackout: ' .. boolText(state))
        return
    end

    if sub == 'api' then
        local mode = tostring(args[2] or ''):lower()

        if mode == 'on' then
            MZSyncState.api.enabled = true
            MZSyncProviderWeatherApi.Fetch(function(success, result)
                MZSyncRefreshState()
                syncNow()

                if success then
                    MZSyncReply(source, 'API ativada e sincronizada.')
                elseif result ~= 'cooldown' and result ~= 'in_progress' then
                    MZSyncReply(source, 'API ativada, mas a sincronizacao imediata falhou: ' .. tostring(result))
                else
                    MZSyncReply(source, 'API ativada.')
                end
            end, { force = true })
            return
        end

        if mode == 'off' then
            MZSyncState.api.enabled = false
            syncNow()
            MZSyncReply(source, 'API desativada.')
            return
        end

        if mode == 'refresh' then
            MZSyncProviderWeatherApi.Fetch(function(success, result)
                if success then
                    if Config.Weather.enabled then
                        local weather = MZSyncWeather.ResolveFromApiPayload(result)
                        MZSyncWeather.Set(weather)
                    end
                    MZSyncRefreshState()
                    syncNow()
                    MZSyncReply(source, 'API atualizada com sucesso. Weather: ' .. tostring(MZSyncState.weather.current))
                else
                    MZSyncReply(source, 'Falha ao atualizar API: ' .. tostring(result))
                end
            end, { force = true })
            return
        end

        MZSyncReply(source, 'Uso: /' .. cmd .. ' api <on|off|refresh>')
        return
    end

    if sub == 'api_location' then
        local value = table.concat(args, ' ', 2)
        if value == '' then
            MZSyncReply(source, 'Uso: /' .. cmd .. ' api_location <cidade>')
            return
        end

        MZSyncState.api.location = value
        if MZSyncState.api.enabled then
            MZSyncProviderWeatherApi.Fetch(function(success, result)
                MZSyncRefreshState()
                syncNow()

                if success then
                    MZSyncReply(source, 'api_location: ' .. value)
                else
                    MZSyncReply(source, 'api_location atualizado, mas a sincronizacao imediata falhou: ' .. tostring(result))
                end
            end, { force = true })
            return
        end

        syncNow()
        MZSyncReply(source, 'api_location: ' .. value)
        return
    end

    if sub == 'override' then
        local state = parseOnOff(args[2])
        if state == nil then
            MZSyncReply(source, 'Uso: /' .. cmd .. ' override <on|off>')
            return
        end

        MZSyncState.override.enabled = state
        syncNow()
        MZSyncReply(source, 'override: ' .. boolText(state))
        return
    end

    if sub == 'halloween' then
        local state = parseOnOff(args[2])
        if state == nil then
            MZSyncReply(source, 'Uso: /' .. cmd .. ' halloween <on|off>')
            return
        end

        if state then
            MZSyncState.override.enabled = true
            MZSyncState.api.enabled = false
            MZSyncState.weather.dynamic = false
            MZSyncState.time.realtime = false
            MZSyncState.time.freeze = true
            MZSyncClock.Set(23, 0)
            MZSyncWeather.Set('HALLOWEEN')
            syncNow()
            MZSyncReply(source, 'Preset Halloween ativado.')
        else
            MZSyncState.override.enabled = false
            syncNow()
            MZSyncReply(source, 'Preset Halloween desativado.')
        end
        return
    end

    if sub == 'storm' then
        local state = parseOnOff(args[2])
        if state == nil then
            MZSyncReply(source, 'Uso: /' .. cmd .. ' storm <on|off>')
            return
        end

        if state then
            MZSyncState.override.enabled = true
            MZSyncState.api.enabled = false
            MZSyncState.weather.dynamic = false
            MZSyncWeather.Set('THUNDER')
            syncNow()
            MZSyncReply(source, 'Preset Storm ativado.')
        else
            MZSyncState.override.enabled = false
            syncNow()
            MZSyncReply(source, 'Preset Storm desativado.')
        end
        return
    end

    MZSyncReply(source, 'Subcomando inválido. Use /' .. cmd .. ' help')
end, false)
