local function allowed(src)
    return not Config.ace or IsPlayerAceAllowed(src, Config.ace)
end

lib.callback.register('handlingeditor:allowed', allowed)

-- keeps only known fields with sane values
local function clean(values)
    if type(values) ~= 'table' then return nil end

    local out, count = {}, 0
    for name, value in pairs(values) do
        local field = FieldByName[name]
        local v = field and Clamp(field, value)
        if v ~= nil then
            out[name] = v
            count = count + 1
        end
    end

    return out, count
end

local last = {}

RegisterNetEvent('handlingeditor:set', function(netId, stock, edits)
    local src = source
    if not Config.sync or not allowed(src) then return end

    local now = GetGameTimer()
    if last[src] and now - last[src] < 250 then return end
    last[src] = now

    local vehicle = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if vehicle == 0 or not DoesEntityExist(vehicle) or GetEntityType(vehicle) ~= 2 then return end
    if GetPedInVehicleSeat(vehicle, -1) ~= GetPlayerPed(src) then return end

    local cleanEdits, count = clean(edits)
    if not cleanEdits then return end

    local state = Entity(vehicle).state

    if count == 0 then
        state:set('handling', nil, true)
        return
    end

    -- the first stock we see for a car is the one we keep, so it can't be rewritten later
    local existing = state.handling
    local cleanStock = existing and existing.stock or clean(stock)
    if not cleanStock then return end

    state:set('handling', { stock = cleanStock, edits = cleanEdits }, true)
end)

AddEventHandler('playerDropped', function()
    last[source] = nil
end)
