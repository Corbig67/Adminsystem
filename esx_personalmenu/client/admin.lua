function PM.OpenAdminMenu()
    if not PM.Await('esx_personalmenu:isAdmin') then return end

    local elements = {}
    for index, action in ipairs(Config.Admin.Actions) do
        elements[#elements + 1] = { label = action.label, value = index }
    end

    PM.OpenMenu('admin', 'Admin-Bereich', elements, function(element)
        local action = Config.Admin.Actions[element.value]
        if not action then return end

        if Config.Admin.CloseMenuOnAction then
            ESX.UI.Menu.CloseAll()
        end
        ExecuteCommand(action.command)
    end)
end
