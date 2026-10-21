local isOpening = false

local function openMainMenu()
    if isOpening or not ESX or not ESX.IsPlayerLoaded() then return end
    if IsEntityDead(PlayerPedId()) or IsPauseMenuActive() then return end

    isOpening = true
    local data = PM.Await('esx_personalmenu:getMenuData')
    isOpening = false
    if not data then return end

    ESX.UI.Menu.CloseAll()

    local elements = {
        { label = 'Brieftasche & Lizenzen', value = 'wallet' },
        { label = 'Kontostand', value = 'accounts' }
    }

    if Config.EnableBilling and GetResourceState('esx_billing') == 'started' then
        elements[#elements + 1] = { label = 'Rechnungen', value = 'bills' }
    end

    if Config.Faction.Enabled then
        elements[#elements + 1] = { label = 'Fraktion: ' .. PM.Color(PM.Escape(data.jobLabel), 'blue'), value = 'faction' }
    end

    if Config.EnableVehicleMenu and PM.GetDriverVehicle() then
        elements[#elements + 1] = { label = 'Fahrzeug', value = 'vehicle' }
    end

    if data.isAdmin then
        elements[#elements + 1] = { label = PM.Color('Admin-Bereich', 'red'), value = 'admin' }
    end

    PM.OpenMenu('main', ('%s | %s'):format(Config.MenuTitle, PM.Escape(data.name)), elements, function(element)
        local action = element.value
        if action == 'wallet' then PM.OpenWalletMenu()
        elseif action == 'accounts' then PM.OpenAccountMenu()
        elseif action == 'bills' then PM.OpenBillsMenu()
        elseif action == 'faction' then PM.OpenFactionMenu()
        elseif action == 'vehicle' then PM.OpenVehicleMenu()
        elseif action == 'admin' then PM.OpenAdminMenu()
        end
    end)
end

RegisterCommand(Config.Command, function()
    CreateThread(openMainMenu)
end, false)

RegisterKeyMapping(Config.Command, 'Persönliches Menü öffnen', 'keyboard', Config.OpenKey)
