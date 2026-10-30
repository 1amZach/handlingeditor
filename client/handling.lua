Handling = {}

local CLASS = 'CHandlingData'

-- true when only the front wheels are driven, see FromGame
local function fwdOnly(vehicle)
    local ok, result = pcall(function()
        local front, rear = false, false
        for i = 0, GetVehicleNumberOfWheels(vehicle) - 1 do
            if GetVehicleWheelIsPowered(vehicle, i) then
                if i < 2 then front = true else rear = true end
            end
        end
        return front and not rear
    end)

    return ok and result
end

function Handling.read(vehicle)
    local values = {}
    local fwd = fwdOnly(vehicle)

    for _, field in ipairs(Fields) do
        if field.type == 'vec' then
            local v = GetVehicleHandlingVector(vehicle, CLASS, field.name)
            values[field.name] = { x = FromGame(field, v.x), y = FromGame(field, v.y), z = FromGame(field, v.z) }
        elseif field.type == 'int' then
            values[field.name] = GetVehicleHandlingInt(vehicle, CLASS, field.name)
        else
            values[field.name] = FromGame(field, GetVehicleHandlingFloat(vehicle, CLASS, field.name), fwd)
        end
    end

    return values
end

local engineFields = {
    fInitialDriveForce = true, fInitialDriveMaxFlatVel = true, fDriveInertia = true, nInitialDriveGears = true,
}

function Handling.write(vehicle, values)
    local engine = false

    for name, value in pairs(values) do
        local field = FieldByName[name]

        if field then
            if field.type == 'vec' then
                SetVehicleHandlingVector(vehicle, CLASS, name, vector3(value.x + 0.0, value.y + 0.0, value.z + 0.0))
            elseif field.type == 'int' then
                SetVehicleHandlingInt(vehicle, CLASS, name, math.floor(value))
            else
                SetVehicleHandlingFloat(vehicle, CLASS, name, ToGame(field, value) + 0.0)
            end

            engine = engine or engineFields[name] ~= nil
        end
    end

    -- the game caches its top speed, this makes it pick up the new engine values
    if engine then ModifyVehicleTopSpeed(vehicle, 1.0) end
end
