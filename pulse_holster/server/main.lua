-- Leitet den Holster-Sound an alle Spieler weiter, die Lautstärke rechnet jeder Client nach Entfernung
local lastSound = {}

RegisterNetEvent('pulse_holster:sound', function(kind)
    local src = source
    if kind ~= 'holster' and kind ~= 'unholster' then return end
    if not Config.Sound.enabled or Config.Sound.range <= 0 then return end

    local now = GetGameTimer()
    if lastSound[src] and now - lastSound[src] < 150 then return end
    lastSound[src] = now

    TriggerClientEvent('pulse_holster:sound', -1, src, kind)
end)

AddEventHandler('playerDropped', function()
    lastSound[source] = nil
end)
