local function hasLicense(licenses, types)
    for _, license in ipairs(licenses) do
        for _, licenseType in ipairs(types) do
            if license.type == licenseType then return true end
        end
    end
    return false
end

-- cardType: nil = Personalausweis, 'driver' = Führerschein, 'weapon' = Waffenschein
local function openCard(cardType, show)
    if GetResourceState(Config.IdCard.Resource) ~= 'started' then
        return PM.Notify('Das Ausweissystem ist derzeit nicht verfügbar.', 'error')
    end

    if cardType and Config.IdCard.RequireLicense then
        local licenses = PM.Await('esx_personalmenu:getLicenses') or {}
        local types = cardType == 'driver' and Config.IdCard.DriverLicenses or Config.IdCard.WeaponLicenses
        if not hasLicense(licenses, types) then
            return PM.Notify(cardType == 'driver' and 'Du besitzt keinen Führerschein.' or 'Du besitzt keinen Waffenschein.', 'error')
        end
    end

    local me = GetPlayerServerId(PlayerId())
    local target = me

    if show then
        target = PM.GetClosestPlayer(Config.IdCard.ShowDistance)
        if not target then
            return PM.Notify('Es ist keine Person in deiner Nähe.', 'error')
        end
    end

    TriggerServerEvent('jsfour-idcard:open', me, target, cardType)

    if show then
        PM.Notify('Du hast das Dokument vorgezeigt.', 'success')
    end
end

local function openLicenseList()
    local licenses = PM.Await('esx_personalmenu:getLicenses') or {}
    local elements = {}

    for _, license in ipairs(licenses) do
        elements[#elements + 1] = { label = PM.Escape(license.label) }
    end

    if #elements == 0 then
        elements[1] = { label = PM.Color('Du besitzt keine Lizenzen.', 'grey') }
    end

    PM.OpenMenu('licenses', 'Meine Lizenzen', elements)
end

function PM.OpenWalletMenu()
    local elements = {}

    if Config.IdCard.Enabled then
        elements = {
            { label = 'Ausweis ansehen',       value = 'id_view' },
            { label = 'Ausweis zeigen',        value = 'id_show' },
            { label = 'Führerschein ansehen',  value = 'driver_view' },
            { label = 'Führerschein zeigen',   value = 'driver_show' },
            { label = 'Waffenschein ansehen',  value = 'weapon_view' },
            { label = 'Waffenschein zeigen',   value = 'weapon_show' }
        }
    end

    elements[#elements + 1] = { label = 'Alle Lizenzen anzeigen', value = 'licenses' }

    PM.OpenMenu('wallet', 'Brieftasche', elements, function(element)
        local action = element.value
        if action == 'licenses' then
            openLicenseList()
        elseif action == 'id_view' then openCard(nil, false)
        elseif action == 'id_show' then openCard(nil, true)
        elseif action == 'driver_view' then openCard('driver', false)
        elseif action == 'driver_show' then openCard('driver', true)
        elseif action == 'weapon_view' then openCard('weapon', false)
        elseif action == 'weapon_show' then openCard('weapon', true)
        end
    end)
end

function PM.OpenAccountMenu()
    local data = PM.Await('esx_personalmenu:getAccounts')
    if not data then return end

    local elements = {
        { label = 'Bargeld: ' .. PM.Color(PM.FormatMoney(data.cash), 'green') },
        { label = 'Bankkonto: ' .. PM.Color(PM.FormatMoney(data.bank), 'blue') }
    }

    if data.black then
        elements[#elements + 1] = { label = 'Schwarzgeld: ' .. PM.Color(PM.FormatMoney(data.black), 'red') }
    end

    elements[#elements + 1] = { label = 'Job: ' .. PM.Escape(data.jobLabel) .. ' - ' .. PM.Escape(data.gradeLabel) }
    elements[#elements + 1] = { label = 'Gehalt: ' .. PM.Color(PM.FormatMoney(data.salary), 'yellow') }

    PM.OpenMenu('accounts', 'Kontostand', elements)
end

function PM.OpenBillsMenu()
    local bills = PM.Await('esx_billing:getBills') or {}
    local elements = {}

    for _, bill in ipairs(bills) do
        elements[#elements + 1] = {
            label = PM.Escape(bill.label) .. ': ' .. PM.Color(PM.FormatMoney(bill.amount), 'red'),
            value = bill.id
        }
    end

    if #elements == 0 then
        elements[1] = { label = PM.Color('Keine offenen Rechnungen.', 'grey') }
    end

    PM.OpenMenu('bills', 'Rechnungen', elements, function(element, menu)
        PM.Confirm('Rechnung bezahlen?', function()
            menu.close()
            ESX.TriggerServerCallback('esx_billing:payBill', function() end, element.value)
            Wait(500)
            PM.OpenBillsMenu()
        end)
    end)
end
