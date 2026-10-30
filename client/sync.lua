-- Edits travel in the vehicle's `handling` state bag as { stock = {...}, edits = {...} }.
-- Stock rides along so every client can put the car back when the edits are cleared.

local applied = {} -- bag name -> stock, so we can undo after the bag goes away

local function vehicleFor(bagName)
    local ok, vehicle = pcall(lib.waitFor, function()
        local entity = GetEntityFromStateBagName(bagName)
        if entity ~= 0 then return entity end
    end, nil, 5000)

    return ok and GetEntityType(vehicle) == 2 and vehicle or nil
end

AddStateBagChangeHandler('handling', nil, function(bagName, _, value)
    CreateThread(function()
        local vehicle = vehicleFor(bagName)
        if not vehicle then return end

        -- our own edits are already on the car, no need to apply them twice
        if Editor and Editor.vehicle == vehicle then
            applied[bagName] = value and value.stock or nil
            return
        end

        if value then
            Handling.write(vehicle, value.edits or {})
            applied[bagName] = value.stock
        elseif applied[bagName] then
            Handling.write(vehicle, applied[bagName])
            applied[bagName] = nil
        end
    end)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    -- leave nothing behind on the cars we touched
    for bagName, stock in pairs(applied) do
        local vehicle = GetEntityFromStateBagName(bagName)
        if vehicle ~= 0 then Handling.write(vehicle, stock) end
    end
end)
