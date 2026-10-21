ESX = nil
PM = {}

local ok, obj = pcall(function() return exports['es_extended']:getSharedObject() end)
if ok and obj then
    ESX = obj
else
    CreateThread(function()
        while ESX == nil do
            TriggerEvent('esx:getSharedObject', function(o) ESX = o end)
            Wait(100)
        end
    end)
end

PM.Colors = {
    green  = '#4caf50',
    red    = '#f44336',
    blue   = '#64b5f6',
    yellow = '#ffc107',
    grey   = '#9e9e9e'
}

function PM.Notify(msg, notifyType)
    ESX.ShowNotification(msg, notifyType)
end

-- menu_default rendert Labels als HTML, daher Spielertexte immer escapen
function PM.Escape(text)
    return (tostring(text or ''):gsub('[&<>"\']', {
        ['&'] = '&amp;', ['<'] = '&lt;', ['>'] = '&gt;', ['"'] = '&quot;', ["'"] = '&#39;'
    }))
end

function PM.Color(text, color)
    return ('<span style="color:%s">%s</span>'):format(PM.Colors[color] or color, text)
end

function PM.FormatMoney(amount)
    amount = math.floor(tonumber(amount) or 0)
    local formatted = tostring(math.abs(amount)):reverse():gsub('(%d%d%d)', '%1.'):reverse()
    if formatted:sub(1, 1) == '.' then formatted = formatted:sub(2) end
    return (amount < 0 and '-' or '') .. formatted .. ' $'
end

-- Synchroner Server-Callback (nur innerhalb eines Threads verwenden)
function PM.Await(name, ...)
    local p = promise.new()
    ESX.TriggerServerCallback(name, function(...)
        p:resolve(table.pack(...))
    end, ...)
    local result = Citizen.Await(p)
    return table.unpack(result, 1, result.n)
end

function PM.GetNearbyPlayers(radius)
    local myId = PlayerId()
    local myCoords = GetEntityCoords(PlayerPedId())
    local result = {}

    for _, player in ipairs(GetActivePlayers()) do
        if player ~= myId then
            local ped = GetPlayerPed(player)
            if DoesEntityExist(ped) and #(GetEntityCoords(ped) - myCoords) <= radius then
                result[#result + 1] = GetPlayerServerId(player)
            end
        end
    end

    return result
end

function PM.GetClosestPlayer(radius)
    local myId = PlayerId()
    local myCoords = GetEntityCoords(PlayerPedId())
    local closest, closestDist = nil, radius

    for _, player in ipairs(GetActivePlayers()) do
        if player ~= myId then
            local ped = GetPlayerPed(player)
            if DoesEntityExist(ped) then
                local dist = #(GetEntityCoords(ped) - myCoords)
                if dist <= closestDist then
                    closest, closestDist = GetPlayerServerId(player), dist
                end
            end
        end
    end

    return closest
end

-- Wrapper um esx_menu_default. Elemente ohne value sind reine Infozeilen.
function PM.OpenMenu(name, title, elements, onSelect, onClose)
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), name, {
        title    = title,
        align    = Config.MenuAlign,
        elements = elements
    }, function(data, menu)
        if onSelect and data.current and data.current.value ~= nil then
            CreateThread(function() onSelect(data.current, menu) end)
        end
    end, function(_, menu)
        menu.close()
        if onClose then CreateThread(onClose) end
    end)
end

function PM.Confirm(title, onYes)
    PM.OpenMenu('confirm', title, {
        { label = PM.Color('Ja', 'green'), value = 'yes' },
        { label = PM.Color('Nein', 'red'), value = 'no' }
    }, function(element, menu)
        menu.close()
        if element.value == 'yes' then onYes() end
    end)
end
