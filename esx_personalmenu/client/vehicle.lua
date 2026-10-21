local doorNames = {
    [0] = 'Vorne links',
    [1] = 'Vorne rechts',
    [2] = 'Hinten links',
    [3] = 'Hinten rechts',
    [4] = 'Motorhaube',
    [5] = 'Kofferraum'
}

local windowNames = {
    [0] = 'Vorne links',
    [1] = 'Vorne rechts',
    [2] = 'Hinten links',
    [3] = 'Hinten rechts'
}

local openWindows = {}

function PM.GetDriverVehicle()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
        return vehicle
    end
end

local function toggleDoor(vehicle, door)
    if GetVehicleDoorAngleRatio(vehicle, door) > 0.0 then
        SetVehicleDoorShut(vehicle, door, false)
    else
        SetVehicleDoorOpen(vehicle, door, false, false)
    end
end

local function toggleWindow(vehicle, window)
    openWindows[vehicle] = openWindows[vehicle] or {}
    if openWindows[vehicle][window] then
        RollUpWindow(vehicle, window)
        openWindows[vehicle][window] = nil
    else
        RollDownWindow(vehicle, window)
        openWindows[vehicle][window] = true
    end
end

local function openDoorMenu()
    local elements = {}
    for door = 0, 5 do
        elements[#elements + 1] = { label = doorNames[door], value = door }
    end
    elements[#elements + 1] = { label = 'Alle schließen', value = 'all' }

    PM.OpenMenu('vehicle_doors', 'Türen', elements, function(element)
        local vehicle = PM.GetDriverVehicle()
        if not vehicle then return PM.Notify('Du musst der Fahrer sein.', 'error') end

        if element.value == 'all' then
            SetVehicleDoorsShut(vehicle, false)
        else
            toggleDoor(vehicle, element.value)
        end
    end)
end

local function openWindowMenu()
    local elements = {}
    for window = 0, 3 do
        elements[#elements + 1] = { label = windowNames[window], value = window }
    end

    PM.OpenMenu('vehicle_windows', 'Fenster', elements, function(element)
        local vehicle = PM.GetDriverVehicle()
        if not vehicle then return PM.Notify('Du musst der Fahrer sein.', 'error') end
        toggleWindow(vehicle, element.value)
    end)
end

function PM.OpenVehicleMenu()
    PM.OpenMenu('vehicle', 'Fahrzeug', {
        { label = 'Motor an/aus', value = 'engine' },
        { label = 'Türen', value = 'doors' },
        { label = 'Fenster', value = 'windows' }
    }, function(element)
        if element.value == 'doors' then return openDoorMenu() end
        if element.value == 'windows' then return openWindowMenu() end

        local vehicle = PM.GetDriverVehicle()
        if not vehicle then return PM.Notify('Du musst der Fahrer sein.', 'error') end

        local running = GetIsVehicleEngineRunning(vehicle)
        SetVehicleEngineOn(vehicle, not running, false, true)
        PM.Notify(running and 'Motor ausgeschaltet.' or 'Motor eingeschaltet.')
    end)
end
