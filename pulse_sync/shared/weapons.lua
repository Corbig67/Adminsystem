-- Baut aus Config.Groups + Config.Weapons eine Tabelle Hash -> fertige Werte (Client und Server)
Sync = {}

-- Hashes immer als vorzeichenlose Zahl vergleichen (Natives und Events liefern sie unterschiedlich)
function Sync.norm(hash) return hash and (hash % 4294967296) end

Sync.weapons = {}
for name, entry in pairs(Config.Weapons) do
    local group = Config.Groups[entry.group] or Config.Groups.misc
    local data = { name = name, group = entry.group, allowed = entry.allowed ~= false }
    for key, value in pairs(group) do data[key] = value end
    for key, value in pairs(entry) do if key ~= 'group' then data[key] = value end end
    Sync.weapons[Sync.norm(joaat(name))] = data
end

function Sync.get(hash) return Sync.weapons[Sync.norm(hash)] end
