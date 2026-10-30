Editor = nil -- { vehicle, stock, edits, focused }

local allowed

local function canUse()
    if allowed == nil then allowed = lib.callback.await('handlingeditor:allowed', false) == true end
    return allowed
end

local function send(action, data)
    SendNUIMessage({ action = action, data = data })
end

local function vehicleName(vehicle)
    local model = GetEntityModel(vehicle)
    local label = GetLabelText(GetDisplayNameFromVehicleModel(model))
    local archetype = GetEntityArchetypeName(vehicle)
    return {
        label = label ~= 'NULL' and label or archetype,
        model = archetype,
    }
end

-- ---------------------------------------------------------------- presets

local function loadPresets()
    local raw = GetResourceKvpString('presets')
    local ok, list = pcall(json.decode, raw or '{}')
    return ok and type(list) == 'table' and list or {}
end

local presets = loadPresets()

local function savePresets()
    SetResourceKvp('presets', json.encode(presets))
end

-- ---------------------------------------------------------------- sync

local pending = false

-- sliders fire constantly, so the server only hears about it once things settle
local function queueSync()
    if not Config.sync or pending then return end
    pending = true

    SetTimeout(350, function()
        pending = false
        if not Editor then return end
        TriggerServerEvent('handlingeditor:set', VehToNet(Editor.vehicle), Editor.stock, Editor.edits)
    end)
end

local function differs(a, b)
    if type(a) == 'table' then
        return math.abs(a.x - b.x) > 1e-4 or math.abs(a.y - b.y) > 1e-4 or math.abs(a.z - b.z) > 1e-4
    end
    return math.abs(a - b) > 1e-4
end

-- apply a set of values and remember which ones now differ from stock
local function apply(values)
    local clean = {}

    for name, value in pairs(values) do
        local field = FieldByName[name]
        local v = field and Clamp(field, value)

        if v ~= nil then
            clean[name] = v
            if differs(v, Editor.stock[name]) then
                Editor.edits[name] = v
            else
                Editor.edits[name] = nil
            end
        end
    end

    Handling.write(Editor.vehicle, clean)
    queueSync()
end

-- ---------------------------------------------------------------- telemetry

local function telemetry()
    local vehicle = Editor.vehicle
    local lastVel = GetEntitySpeedVector(vehicle, true)
    local lastTime = GetGameTimer()
    local launch, best, top = nil, nil, 0.0
    local gLat, gLong = 0.0, 0.0

    while Editor and Editor.vehicle == vehicle and DoesEntityExist(vehicle) do
        Wait(Config.telemetryRate)

        local now = GetGameTimer()
        local dt = math.max((now - lastTime) / 1000, 0.001)
        local vel = GetEntitySpeedVector(vehicle, true)
        local kmh = GetEntitySpeed(vehicle) * 3.6

        -- smoothed so the readout doesn't jitter
        gLat = gLat * 0.7 + ((vel.x - lastVel.x) / dt / 9.81) * 0.3
        gLong = gLong * 0.7 + ((vel.y - lastVel.y) / dt / 9.81) * 0.3
        lastVel, lastTime = vel, now
        top = math.max(top, kmh)

        -- 0-100 km/h: arm when stopped, time it from the moment the car starts moving
        if kmh < 0.5 then
            launch = false
        elseif launch == false and kmh > 0.5 then
            launch = now
        elseif launch and kmh >= 100.0 then
            local time = (now - launch) / 1000
            best = best and math.min(best, time) or time
            send('launch', { time = time, best = best })
            launch = nil
        end

        send('telemetry', {
            kmh = kmh,
            rpm = GetVehicleCurrentRpm(vehicle),
            gear = GetVehicleCurrentGear(vehicle),
            gLat = gLat,
            gLong = gLong,
            top = top,
            timing = launch and (now - launch) / 1000 or nil,
        })
    end
end

-- ---------------------------------------------------------------- open / close

local function close()
    if not Editor then return end
    SetNuiFocus(false, false)
    send('close')
    Editor = nil
end

local function focus(on)
    Editor.focused = on
    SetNuiFocus(on, on)
    send('mode', { driving = not on })
end

local function open()
    if Editor then
        -- already open: the key toggles between editing and driving
        return focus(not Editor.focused)
    end

    if not canUse() then
        return lib.notify({ description = 'You don\'t have access to the handling editor', type = 'error' })
    end

    local vehicle = cache.vehicle
    if not vehicle or cache.seat ~= -1 then
        return lib.notify({ description = 'Get in the driver\'s seat first', type = 'error' })
    end

    local bag = Entity(vehicle).state.handling
    local current = Handling.read(vehicle)

    Editor = {
        vehicle = vehicle,
        stock = bag and bag.stock or current,
        edits = bag and bag.edits or {},
    }

    send('open', {
        fields = Fields,
        vehicle = vehicleName(vehicle),
        stock = Editor.stock,
        values = current,
        presets = presets,
    })

    focus(true)
    CreateThread(telemetry)
end

-- ---------------------------------------------------------------- NUI

RegisterNUICallback('set', function(data, cb)
    if Editor and type(data) == 'table' and type(data.values) == 'table' then apply(data.values) end
    cb(1)
end)

RegisterNUICallback('reset', function(_, cb)
    if Editor then
        Handling.write(Editor.vehicle, Editor.stock)
        Editor.edits = {}
        queueSync()
    end
    cb(1)
end)

RegisterNUICallback('drive', function(_, cb)
    if Editor then focus(false) end
    cb(1)
end)

RegisterNUICallback('close', function(_, cb)
    close()
    cb(1)
end)

RegisterNUICallback('copy', function(data, cb)
    if type(data) == 'table' and type(data.text) == 'string' then
        lib.setClipboard(data.text)
        print(data.text)
        lib.notify({ description = 'handling.meta copied (also printed to F8)', type = 'success' })
    end
    cb(1)
end)

RegisterNUICallback('savePreset', function(data, cb)
    if type(data) == 'table' and type(data.name) == 'string' and data.name ~= '' and type(data.values) == 'table' then
        presets[data.name:sub(1, 40)] = { model = Editor and GetEntityArchetypeName(Editor.vehicle), values = data.values }
        savePresets()
    end
    cb(presets)
end)

RegisterNUICallback('deletePreset', function(data, cb)
    if type(data) == 'table' and type(data.name) == 'string' then
        presets[data.name] = nil
        savePresets()
    end
    cb(presets)
end)

-- left the car or swapped seats
lib.onCache('vehicle', function(vehicle)
    if Editor and vehicle ~= Editor.vehicle then close() end
end)

lib.onCache('seat', function(seat)
    if Editor and seat ~= -1 then close() end
end)

RegisterCommand(Config.command, open, false)

if Config.key then
    RegisterKeyMapping(Config.command, 'Handling editor (press again to drive)', 'keyboard', Config.key)
end

TriggerEvent('chat:addSuggestion', '/' .. Config.command, 'Open the handling editor, run it again to switch to driving')

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource and Editor then SetNuiFocus(false, false) end
end)
