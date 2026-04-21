# mz_sync

Sincronizacao de horario, clima e blackout para o ecossistema `mz_`.

O recurso trabalha em cima de um estado global no servidor e envia sync para todos os clientes.
Ele suporta:

- hora manual
- hora realtime com `timezoneOffsetHours`
- hora baseada na API, quando `realtime_time` estiver ligado
- clima manual
- clima dinamico local por sequencia
- clima vindo da WeatherAPI
- blackout sincronizado
- presets administrativos como `halloween` e `storm`

## Estrutura

```text
mz_sync/
|-- fxmanifest.lua
|-- shared/
|   |-- config.lua
|   `-- weather_map.lua
|-- server/
|   |-- main.lua
|   |-- commands.lua
|   `-- services/
|       |-- state.lua
|       |-- clock.lua
|       |-- weather.lua
|       `-- provider_weatherapi.lua
`-- client/
    `-- main.lua
```

## Instalacao

1. Coloque o recurso em `resources/[mz]/mz_sync`.
2. Ajuste o arquivo [shared/config.lua](shared/config.lua).
3. Garanta a ordem de boot do seu `server.cfg`.

Exemplo de ordem recomendada:

```cfg
ensure oxmysql
ensure ox_lib

ensure mapmanager
ensure spawnmanager
ensure sessionmanager

ensure pma-voice

ensure mz_notify
ensure mz_sync
ensure mz_core
```

## Dependencias

Obrigatorias para o recurso subir:

- nenhuma dependencia Lua externa

Dependencias praticas recomendadas no ambiente:

- recurso `chat` do FiveM, porque as respostas dos comandos usam `chat:addMessage`
- `mz_notify` e `mz_core` no ecossistema `mz_`, quando fizer parte da base

## Configuracao

Arquivo: [shared/config.lua](shared/config.lua)

### Geral

```lua
Config.Debug = true
Config.CommandName = 'msync'
Config.AllowedAces = {
    'mz_owner',
    'admin'
}
```

- `Debug`: ativa logs extras no servidor.
- `CommandName`: nome base do comando. Se estiver `msync`, os comandos ficam `/msync ...`.
- `AllowedAces`: lista de ACEs aceitas para usar os comandos.

### Sync

```lua
Config.Sync = {
    broadcastIntervalMs = 5000,
    clockTickSeconds = 5,
    clockStepMinutes = 1
}
```

- `broadcastIntervalMs`: intervalo do broadcast global para todos os clientes.
- `clockTickSeconds`: intervalo do tick do relogio no servidor.
- `clockStepMinutes`: quantos minutos o relogio manual avanca a cada tick.

### Tempo

```lua
Config.Time = {
    enabled = true,
    realtime = true,
    timezoneOffsetHours = -3,
    freeze = false,
    defaultHour = 12,
    defaultMinute = 0
}
```

- `enabled`: liga ou desliga a aplicacao de hora no payload e no client.
- `realtime`: quando `true`, usa hora realtime.
- `timezoneOffsetHours`: offset aplicado sobre UTC para o modo realtime local.
- `freeze`: congela a hora atual.
- `defaultHour` e `defaultMinute`: hora inicial do recurso.

### Clima

```lua
Config.Weather = {
    enabled = true,
    dynamic = true,
    dynamicIntervalMinutes = 20,
    transitionSeconds = 15.0,
    defaultWeather = 'CLEAR',
    blackout = false,
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
```

- `enabled`: liga ou desliga aplicacao de clima e blackout no payload/client.
- `dynamic`: ativa o clima dinamico por sequencia local.
- `dynamicIntervalMinutes`: intervalo entre trocas do clima dinamico.
- `transitionSeconds`: duracao da transicao no client.
- `defaultWeather`: clima inicial.
- `blackout`: blackout inicial.
- `allowThunder`: permite ou nao tempestade vinda da API.
- `allowSnow`: permite ou nao neve vinda da API.
- `fallbackWeather`: clima padrao quando o mapeamento falhar.
- `sequence`: sequencia usada no modo dinamico local.

### API

```lua
Config.Api = {
    enabled = false,
    provider = 'weatherapi',
    key = 'SUA API KEY AQUI',
    location = 'Rio de Janeiro',
    endpoint = 'https://api.weatherapi.com/v1/current.json?key=%s&q=%s&lang=pt',
    fetchIntervalMinutes = 15
}
```

- `enabled`: ativa a integracao com a API.
- `provider`: hoje o recurso suporta `weatherapi`.
- `key`: chave da WeatherAPI.
- `location`: cidade/localidade usada na consulta.
- `endpoint`: endpoint formatado com `key` e `location`.
- `fetchIntervalMinutes`: intervalo entre tentativas automaticas.

Observacao importante:

- atualmente a chave fica em `shared/config.lua`, entao ela faz parte de um arquivo compartilhado do recurso
- se voce quiser manter a chave 100% server-side, sera necessario mover esse valor para um ponto somente de servidor

## Tipos de clima aceitos

Os principais tipos aceitos pelo recurso sao:

- `EXTRASUNNY`
- `CLEAR`
- `NEUTRAL`
- `SMOG`
- `FOGGY`
- `OVERCAST`
- `CLOUDS`
- `CLEARING`
- `RAIN`
- `THUNDER`
- `XMAS`
- `HALLOWEEN`

O mapeamento da WeatherAPI fica em [shared/weather_map.lua](shared/weather_map.lua).

## Como o recurso decide a hora

A prioridade atual da hora e:

1. `freeze_time on`
2. `override on` com `realtime_time off`
3. hora da API, quando `api on` e `realtime_time on`
4. hora realtime local com `timezoneOffsetHours`
5. hora manual/local tick, quando `realtime_time off`

Resumo pratico:

- se `freeze_time` estiver ligado, a hora para
- se `realtime_time` estiver ligado e a API estiver ativa com base de hora valida, a hora segue a API
- se `realtime_time` estiver ligado e a API nao estiver servindo hora, usa UTC + offset
- se `realtime_time` estiver desligado, usa a hora manual/local do recurso

## Como o recurso decide o clima

A prioridade pratica do clima e:

1. `Config.Weather.enabled = false` desliga a aplicacao no client
2. `override on` bloqueia clima dinamico local e bloqueia aplicacao automatica de clima vindo da API
3. `api on` bloqueia o tick do clima dinamico local
4. `dynamic_weather on` usa a sequencia local
5. `weather <tipo>` fixa manualmente o clima e desliga `api` e `dynamic`

Observacoes:

- `api refresh` aplica o clima retornado pela API imediatamente, se `Config.Weather.enabled = true`
- `blackout` sempre trabalha junto com a parte de clima, porque vai no mesmo payload de weather

## Permissoes

Os comandos usam ACE.

Exemplo:

```cfg
add_ace group.admin mz_owner allow
add_principal identifier.license:SEU_LICENSE group.admin
```

Ou voce pode trocar a lista em [shared/config.lua](shared/config.lua):

```lua
Config.AllowedAces = {
    'mz_owner',
    'admin'
}
```

## Comandos

O nome base depende de `Config.CommandName`.
Com o padrao atual, todos os comandos abaixo usam `/msync`.

### `/msync help`

- Lista todos os subcomandos disponiveis.
- Nao altera estado.

### `/msync status`

- Mostra o snapshot atual do estado:
  - `override`
  - `api`
  - `realtimeTime`
  - `freezeTime`
  - `dynamicWeather`
  - `weather`
  - `time`
  - `blackout`
  - `apiStatus`

### `/msync time <hora> <min>`

- Define a hora manualmente.
- Desliga `realtime_time`.
- Mantem `api`, `dynamic` e `override` como estao.
- Aplica sync imediato.

Exemplo:

```text
/msync time 12 30
```

### `/msync freeze_time <on|off>`

- Liga ou desliga o congelamento da hora.
- Nao desliga `api`, `dynamic` ou `override`.
- Aplica sync imediato.

Exemplo:

```text
/msync freeze_time on
```

### `/msync realtime_time <on|off>`

- Liga ou desliga o modo realtime.
- Quando `on`, usa API para hora se `api` tambem estiver `on` e houver base valida.
- Quando `off`, volta para tempo manual/local.
- Aplica sync imediato.

Exemplo:

```text
/msync realtime_time off
```

### `/msync weather <tipo>`

- Define manualmente o clima.
- Desliga `api`.
- Desliga `dynamic_weather`.
- Nao mexe em `override`.
- Aplica sync imediato.

Exemplo:

```text
/msync weather CLEAR
/msync weather THUNDER
```

### `/msync dynamic_weather <on|off>`

- Liga ou desliga o clima dinamico local.
- Nao desliga `api` nem `override`.
- Ao ligar, reinicia a agenda da proxima rotacao.
- Aplica sync imediato.

Exemplo:

```text
/msync dynamic_weather on
```

### `/msync blackout <on|off>`

- Liga ou desliga blackout.
- Nao desliga `api`, `dynamic` ou `override`.
- Aplica sync imediato.

Exemplo:

```text
/msync blackout on
```

### `/msync api <on|off|refresh>`

#### `on`

- Liga `api`.
- Faz fetch imediato.
- Aplica sync imediato.
- Nao desliga `dynamic` nem `override`.

Comportamento esperado:

- a hora pode ajustar imediatamente se `realtime_time` estiver `on`
- o clima vindo da API entra naturalmente no tick automatico, ou imediatamente se voce usar `refresh`

#### `off`

- Desliga `api`.
- Aplica sync imediato.

#### `refresh`

- Forca um fetch imediato.
- Se `Config.Weather.enabled = true`, aplica o clima da API imediatamente.
- Tambem atualiza a base de hora da API.
- Aplica sync imediato.

Exemplo:

```text
/msync api on
/msync api refresh
/msync api off
```

### `/msync api_location <cidade>`

- Troca a localizacao usada na API.
- Se `api` estiver `on`, faz fetch imediato.
- Aplica sync imediato.

Exemplo:

```text
/msync api_location Sao Paulo
/msync api_location Rio de Janeiro
```

### `/msync override <on|off>`

- Liga ou desliga o modo override.
- Aplica sync imediato.
- Nao desliga `api` nem `dynamic` por si so.

Comportamento esperado:

- com `override on`, o clima dinamico local para
- com `override on`, a API deixa de aplicar clima automaticamente
- a hora ainda pode vir da API se `realtime_time` estiver `on`

Exemplo:

```text
/msync override on
```

### `/msync halloween <on|off>`

#### `on`

Aplica um preset:

- `override = true`
- `api = false`
- `dynamicWeather = false`
- `realtimeTime = false`
- `freezeTime = true`
- `time = 23:00`
- `weather = HALLOWEEN`

Faz sync imediato.

#### `off`

- Desliga apenas `override`
- nao restaura automaticamente os estados anteriores

Exemplo:

```text
/msync halloween on
```

### `/msync storm <on|off>`

#### `on`

Aplica um preset:

- `override = true`
- `api = false`
- `dynamicWeather = false`
- `weather = THUNDER`

Faz sync imediato.

#### `off`

- Desliga apenas `override`
- nao restaura automaticamente os estados anteriores

Exemplo:

```text
/msync storm on
```

## Status da API

No `/msync status`, o campo `apiStatus` pode assumir valores como:

- `idle`
- `fetching`
- `ok`
- `missing_key`
- `invalid_json`
- `unsupported_provider`
- `http_<status>`

## Comportamento de retry da API

O recurso aplica cooldown entre tentativas automaticas de API.
Esse cooldown tambem vale em casos de:

- chave ausente
- endpoint fora do ar
- erro HTTP
- falha de parse

Isso evita flood de requests e spam de log.

## Fluxo de sync

O recurso sincroniza os clientes nestes momentos:

- quando um jogador entra
- quando um cliente pede sync inicial
- no broadcast periodico
- imediatamente apos comandos administrativos
- imediatamente apos atualizacao automatica da API

## Checklist rapido de teste

1. Suba o servidor com `ensure mz_sync`.
2. Rode `/msync status`.
3. Rode `/msync time 12 30` e confirme a hora.
4. Rode `/msync freeze_time on` e confirme que a hora para.
5. Rode `/msync weather THUNDER` e confirme a troca de clima.
6. Rode `/msync blackout on` e confirme o blackout.
7. Configure `Config.Api.key`, rode `/msync api on` e depois `/msync api refresh`.
8. Rode `/msync dynamic_weather on` e aguarde uma troca automatica.

## Observacoes finais

- Se `Config.Time.enabled = false`, o client deixa de aplicar hora pelo payload.
- Se `Config.Weather.enabled = false`, o client deixa de aplicar clima e blackout pelo payload.
- O recurso nao depende de framework especifico para a logica principal.
- As respostas dos comandos foram feitas via `chat:addMessage`.
