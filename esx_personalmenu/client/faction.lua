local function getNearbyPlayers()
    local ids = PM.GetNearbyPlayers(Config.Faction.NearbyDistance)
    if #ids == 0 then return {} end
    return PM.Await('esx_personalmenu:getNearbyPlayers', ids) or {}
end

local function openEmployeeActions(target, name, refresh)
    PM.OpenMenu('faction_actions', PM.Escape(name), {
        { label = PM.Color('Befördern', 'green'), value = 'promote' },
        { label = PM.Color('Degradieren', 'yellow'), value = 'demote' },
        { label = PM.Color('Feuern', 'red'), value = 'fire' }
    }, function(element, menu)
        local function run()
            if PM.Await('esx_personalmenu:manageEmployee', element.value, target) then
                menu.close()
                if refresh then refresh() end
            end
        end

        if element.value == 'fire' then
            PM.Confirm(PM.Escape(name) .. ' wirklich feuern?', run)
        else
            run()
        end
    end)
end

local function openNearbyEmployees(faction)
    local elements = {}

    for _, player in ipairs(getNearbyPlayers()) do
        if player.job == faction.job then
            elements[#elements + 1] = {
                label  = ('%s [%s] - %s'):format(PM.Escape(player.name), player.id, PM.Escape(player.gradeLabel)),
                value  = player.id,
                name   = player.name,
                target = { type = 'player', id = player.id }
            }
        end
    end

    if #elements == 0 then
        return PM.Notify('Es sind keine Mitarbeiter in deiner Nähe.', 'error')
    end

    PM.OpenMenu('faction_nearby', 'Mitarbeiter in der Nähe', elements, function(element, menu)
        openEmployeeActions(element.target, element.name, function()
            menu.close()
            openNearbyEmployees(faction)
        end)
    end)
end

local function openEmployeeList()
    local employees = PM.Await('esx_personalmenu:getEmployees')
    if not employees then return end

    local elements = {}
    for _, employee in ipairs(employees) do
        elements[#elements + 1] = {
            label  = ('%s %s - %s'):format(
                PM.Color('●', employee.online and 'green' or 'grey'),
                PM.Escape(employee.name),
                PM.Escape(employee.gradeLabel)
            ),
            value  = employee.identifier,
            name   = employee.name,
            target = { type = 'identifier', id = employee.identifier }
        }
    end

    if #elements == 0 then
        elements[1] = { label = PM.Color('Keine weiteren Mitarbeiter.', 'grey') }
    end

    PM.OpenMenu('faction_list', 'Mitarbeiterliste', elements, function(element, menu)
        openEmployeeActions(element.target, element.name, function()
            menu.close()
            openEmployeeList()
        end)
    end)
end

local function openHireMenu(faction)
    local elements = {}

    for _, player in ipairs(getNearbyPlayers()) do
        if player.job ~= faction.job then
            elements[#elements + 1] = {
                label = ('%s [%s] - %s'):format(PM.Escape(player.name), player.id, PM.Escape(player.jobLabel)),
                value = player.id,
                name  = player.name
            }
        end
    end

    if #elements == 0 then
        return PM.Notify('Es ist keine Person in deiner Nähe, die du einstellen kannst.', 'error')
    end

    PM.OpenMenu('faction_hire', 'Person einstellen', elements, function(element, menu)
        PM.Confirm(PM.Escape(element.name) .. ' einstellen?', function()
            if PM.Await('esx_personalmenu:hire', element.value) then
                menu.close()
            end
        end)
    end)
end

function PM.OpenFactionMenu()
    local faction = PM.Await('esx_personalmenu:getFactionData')
    if not faction then return end

    local elements = {
        { label = 'Job: ' .. PM.Color(PM.Escape(faction.jobLabel), 'blue') },
        { label = 'Rang: ' .. PM.Escape(faction.gradeLabel) },
        { label = 'Gehalt: ' .. PM.Color(PM.FormatMoney(faction.salary), 'yellow') }
    }

    if faction.isBoss then
        if faction.societyMoney then
            elements[#elements + 1] = { label = 'Firmenkonto: ' .. PM.Color(PM.FormatMoney(faction.societyMoney), 'green') }
        end
        elements[#elements + 1] = { label = 'Mitarbeiter in der Nähe', value = 'nearby' }
        if Config.Faction.AllowRemoteManagement then
            elements[#elements + 1] = { label = 'Mitarbeiterliste', value = 'list' }
        end
        elements[#elements + 1] = { label = 'Person in der Nähe einstellen', value = 'hire' }
    end

    if faction.canResign then
        elements[#elements + 1] = { label = PM.Color('Job kündigen', 'red'), value = 'resign' }
    end

    PM.OpenMenu('faction', 'Fraktion', elements, function(element)
        if element.value == 'nearby' then
            openNearbyEmployees(faction)
        elseif element.value == 'list' then
            openEmployeeList()
        elseif element.value == 'hire' then
            openHireMenu(faction)
        elseif element.value == 'resign' then
            PM.Confirm('Möchtest du wirklich kündigen?', function()
                if PM.Await('esx_personalmenu:resign') then
                    ESX.UI.Menu.CloseAll()
                end
            end)
        end
    end)
end

RegisterNetEvent('esx_personalmenu:jobOffer', function(offerId, jobLabel, bossName, timeout)
    local menuName = 'job_offer_' .. offerId

    PM.OpenMenu(menuName, 'Jobangebot', {
        { label = PM.Escape(bossName) .. ' bietet dir einen Job an:' },
        { label = PM.Color(PM.Escape(jobLabel), 'blue') },
        { label = PM.Color('Annehmen', 'green'), value = 'accept' },
        { label = PM.Color('Ablehnen', 'red'), value = 'decline' }
    }, function(element, menu)
        menu.close()
        TriggerServerEvent('esx_personalmenu:answerOffer', offerId, element.value == 'accept')
    end, function()
        TriggerServerEvent('esx_personalmenu:answerOffer', offerId, false)
    end)

    SetTimeout(timeout * 1000, function()
        ESX.UI.Menu.Close('default', GetCurrentResourceName(), menuName)
    end)
end)
