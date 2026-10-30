--[[
    Every editable CHandlingData field, in handling.meta units.

    conv says how the game stores it in memory, so we can show and export real
    handling.meta values while reading and writing what the game actually uses:
        deg   degrees in the file, radians in memory
        kmh   divided by 3.6 in memory
        bias  front bias, doubled in memory (rear is 2 - front)
        drive same as bias, except 0 and 1 are stored as-is
        damp  divided by 10 in memory
        drag  divided by 10000 in memory
]]

Fields = {
    { name = 'fMass', group = 'Body', label = 'Mass', unit = 'kg', min = 50, max = 50000, step = 10 },
    { name = 'fInitialDragCoeff', group = 'Body', label = 'Drag', min = 0, max = 120, step = 0.1, conv = 'drag' },
    { name = 'fDownforceModifier', group = 'Body', label = 'Downforce', min = 0, max = 100, step = 0.1 },
    { name = 'fPercentSubmerged', group = 'Body', label = 'Submerged %', min = 10, max = 100, step = 1 },
    { name = 'vecCentreOfMassOffset', group = 'Body', label = 'Centre of mass offset', type = 'vec', min = -2, max = 2, step = 0.01 },
    { name = 'vecInertiaMultiplier', group = 'Body', label = 'Inertia multiplier', type = 'vec', min = 0, max = 4, step = 0.01 },

    { name = 'fInitialDriveForce', group = 'Engine', label = 'Drive force', min = 0.01, max = 2, step = 0.005 },
    { name = 'fInitialDriveMaxFlatVel', group = 'Engine', label = 'Max flat speed', unit = 'km/h', min = 10, max = 500, step = 1, conv = 'kmh' },
    { name = 'fDriveInertia', group = 'Engine', label = 'Drive inertia', min = 0.01, max = 2, step = 0.01 },
    { name = 'fDriveBiasFront', group = 'Engine', label = 'Drive bias front', hint = '0 = RWD, 1 = FWD', min = 0, max = 1, step = 0.01, conv = 'drive' },
    { name = 'nInitialDriveGears', group = 'Engine', label = 'Gears', type = 'int', min = 1, max = 10, step = 1 },
    { name = 'fClutchChangeRateScaleUpShift', group = 'Engine', label = 'Upshift speed', min = 0.1, max = 10, step = 0.1 },
    { name = 'fClutchChangeRateScaleDownShift', group = 'Engine', label = 'Downshift speed', min = 0.1, max = 10, step = 0.1 },

    { name = 'fBrakeForce', group = 'Brakes & steering', label = 'Brake force', min = 0.01, max = 5, step = 0.01 },
    { name = 'fBrakeBiasFront', group = 'Brakes & steering', label = 'Brake bias front', min = 0, max = 1, step = 0.01, conv = 'bias' },
    { name = 'fHandBrakeForce', group = 'Brakes & steering', label = 'Handbrake force', min = 0, max = 5, step = 0.01 },
    { name = 'fSteeringLock', group = 'Brakes & steering', label = 'Steering lock', unit = 'deg', min = 10, max = 90, step = 0.5, conv = 'deg' },

    { name = 'fTractionCurveMax', group = 'Traction', label = 'Grip max', min = 0, max = 5, step = 0.01 },
    { name = 'fTractionCurveMin', group = 'Traction', label = 'Grip min', min = 0, max = 5, step = 0.01 },
    { name = 'fTractionCurveLateral', group = 'Traction', label = 'Lateral curve', unit = 'deg', min = 5, max = 45, step = 0.1, conv = 'deg' },
    { name = 'fTractionSpringDeltaMax', group = 'Traction', label = 'Spring delta max', min = 0, max = 1, step = 0.01 },
    { name = 'fLowSpeedTractionLossMult', group = 'Traction', label = 'Low speed wheelspin', min = 0, max = 3, step = 0.01 },
    { name = 'fCamberStiffnesss', group = 'Traction', label = 'Camber stiffness', min = 0, max = 2, step = 0.01 },
    { name = 'fTractionBiasFront', group = 'Traction', label = 'Grip bias front', hint = '0 or 1 means no grip', min = 0.01, max = 0.99, step = 0.01, conv = 'bias' },
    { name = 'fTractionLossMult', group = 'Traction', label = 'Off-road grip loss', min = 0, max = 3, step = 0.01 },

    { name = 'fSuspensionForce', group = 'Suspension', label = 'Spring force', min = 0, max = 10, step = 0.01 },
    { name = 'fSuspensionCompDamp', group = 'Suspension', label = 'Compression damping', min = 0, max = 10, step = 0.01, conv = 'damp' },
    { name = 'fSuspensionReboundDamp', group = 'Suspension', label = 'Rebound damping', min = 0, max = 10, step = 0.01, conv = 'damp' },
    { name = 'fSuspensionUpperLimit', group = 'Suspension', label = 'Upper limit', min = -1, max = 1, step = 0.01 },
    { name = 'fSuspensionLowerLimit', group = 'Suspension', label = 'Lower limit', min = -1, max = 1, step = 0.01 },
    { name = 'fSuspensionRaise', group = 'Suspension', label = 'Ride height', min = -1, max = 1, step = 0.01 },
    { name = 'fSuspensionBiasFront', group = 'Suspension', label = 'Spring bias front', min = 0, max = 1, step = 0.01, conv = 'bias' },
    { name = 'fAntiRollBarForce', group = 'Suspension', label = 'Anti-roll bar', min = 0, max = 10, step = 0.01 },
    { name = 'fAntiRollBarBiasFront', group = 'Suspension', label = 'Anti-roll bias front', min = 0, max = 1, step = 0.01, conv = 'bias' },
    { name = 'fRollCentreHeightFront', group = 'Suspension', label = 'Roll centre front', min = -1, max = 1, step = 0.01 },
    { name = 'fRollCentreHeightRear', group = 'Suspension', label = 'Roll centre rear', min = -1, max = 1, step = 0.01 },

    { name = 'fCollisionDamageMult', group = 'Damage', label = 'Collision damage', min = 0, max = 10, step = 0.1 },
    { name = 'fWeaponDamageMult', group = 'Damage', label = 'Weapon damage', min = 0, max = 10, step = 0.1 },
    { name = 'fDeformationDamageMult', group = 'Damage', label = 'Deformation', min = 0, max = 10, step = 0.1 },
    { name = 'fEngineDamageMult', group = 'Damage', label = 'Engine damage', min = 0, max = 10, step = 0.1 },
    { name = 'fPetrolTankVolume', group = 'Damage', label = 'Fuel tank', unit = 'L', min = 0, max = 200, step = 1 },
    { name = 'fOilVolume', group = 'Damage', label = 'Oil volume', min = 0, max = 20, step = 0.1 },
}

FieldByName = {}
for _, field in ipairs(Fields) do
    field.type = field.type or 'float'
    FieldByName[field.name] = field
end

local function round(n)
    return math.floor(n * 10000 + 0.5) / 10000
end

-- handling.meta value -> what the game keeps in memory
function ToGame(field, value)
    local conv = field.conv
    if conv == 'deg' then return math.rad(value) end
    if conv == 'kmh' then return value / 3.6 end
    if conv == 'bias' then return value * 2.0 end
    if conv == 'damp' then return value / 10.0 end
    if conv == 'drag' then return value / 10000.0 end
    if conv == 'drive' then
        if value <= 0.0 or value >= 1.0 then return value end
        return value * 2.0
    end
    return value
end

-- memory value -> handling.meta. `fwdOnly` settles drive bias: 1.0 in memory is either
-- pure FWD or a 50/50 split, and only the powered wheels can tell them apart.
function FromGame(field, value, fwdOnly)
    local conv = field.conv
    if conv == 'deg' then return round(math.deg(value)) end
    if conv == 'kmh' then return round(value * 3.6) end
    if conv == 'bias' then return round(value / 2.0) end
    if conv == 'damp' then return round(value * 10.0) end
    if conv == 'drag' then return round(value * 10000.0) end
    if conv == 'drive' then
        if value <= 0.0 then return 0.0 end
        if value == 1.0 and fwdOnly then return 1.0 end
        return round(value / 2.0)
    end
    return round(value)
end

-- keeps a value inside the field's range, nil if it isn't a usable value
function Clamp(field, value)
    if field.type == 'vec' then
        if type(value) ~= 'table' then return end
        local out = {}
        for _, axis in ipairs({ 'x', 'y', 'z' }) do
            local v = tonumber(value[axis])
            if not v or v ~= v then return end
            out[axis] = math.max(field.min, math.min(field.max, v))
        end
        return out
    end

    local v = tonumber(value)
    if not v or v ~= v then return end
    v = math.max(field.min, math.min(field.max, v))
    if field.type == 'int' then v = math.floor(v + 0.5) end
    return v
end
