Config = {}

-- Allgemein ---------------------------------------------------------------
Config.Title          = 'KLEIDUNGSLADEN'
Config.DefaultPay     = 'cash'          -- 'cash' oder 'bank' vorausgewählt
Config.MaxOutfits     = 20              -- max. gespeicherte Outfits pro Charakter
Config.OpenKey        = 38              -- E (INPUT_CONTEXT)
Config.InteractRange  = 1.5             -- Abstand zum Marker zum Öffnen
Config.MaxDistance    = 6.0             -- serverseitig: max. Abstand zum Laden beim Kaufen (OneSync)
Config.RotateStep     = 12.0            -- Grad pro Drehung (A/D oder Buttons)
Config.AutoCreateTable = true           -- Tabelle pulse_outfits beim Start automatisch anlegen

-- Kategorien: müssen zu html/js/app.js (CONFIG.categories) passen.
-- Die Preise hier sind maßgeblich, sie werden an die UI geschickt und beim Kauf nachgerechnet.
Config.Categories = {
    { id = 'tshirt',    label = 'T-Shirt',  icon = 'shirt',    d = 'tshirt_1',    t = 'tshirt_2',    price = 80,  min = 0 },
    { id = 'torso',     label = 'Oberteil', icon = 'jacket',   d = 'torso_1',     t = 'torso_2',     price = 240, min = 0 },
    { id = 'arms',      label = 'Arme',     icon = 'glove',    d = 'arms',        t = 'arms_2',      price = 60,  min = 0 },
    { id = 'pants',     label = 'Hose',     icon = 'pants',    d = 'pants_1',     t = 'pants_2',     price = 150, min = 0 },
    { id = 'shoes',     label = 'Schuhe',   icon = 'shoes',    d = 'shoes_1',     t = 'shoes_2',     price = 130, min = 0 },
    { id = 'helmet',    label = 'Kopf',     icon = 'cap',      d = 'helmet_1',    t = 'helmet_2',    price = 90,  min = -1 },
    { id = 'glasses',   label = 'Brille',   icon = 'glasses',  d = 'glasses_1',   t = 'glasses_2',   price = 70,  min = 0 },
    { id = 'mask',      label = 'Maske',    icon = 'mask',     d = 'mask_1',      t = 'mask_2',      price = 110, min = 0 },
    { id = 'chain',     label = 'Kette',    icon = 'chain',    d = 'chain_1',     t = 'chain_2',     price = 300, min = 0 },
    { id = 'watches',   label = 'Uhr',      icon = 'watch',    d = 'watches_1',   t = 'watches_2',   price = 260, min = -1 },
    { id = 'bracelets', label = 'Armband',  icon = 'bracelet', d = 'bracelets_1', t = 'bracelets_2', price = 90,  min = -1 },
    { id = 'bags',      label = 'Tasche',   icon = 'bag',      d = 'bags_1',      t = 'bags_2',      price = 140, min = 0 }
}

-- Kamera-Einstellungen (dist = Abstand vor dem Spieler, z = Höhe, point = Blickhöhe)
Config.Camera = {
    head = { dist = 0.75, z = 0.65,  point = 0.65,  fov = 40.0 },
    body = { dist = 1.25, z = 0.25,  point = 0.15,  fov = 45.0 },
    legs = { dist = 1.25, z = -0.35, point = -0.45, fov = 45.0 },
    feet = { dist = 0.95, z = -0.70, point = -0.90, fov = 40.0 },
    full = { dist = 2.60, z = 0.10,  point = -0.10, fov = 50.0 }
}

-- Läden -------------------------------------------------------------------
-- categories (optional): nur diese Kategorien anbieten, z. B. { 'helmet', 'glasses', 'mask' }
-- prices (optional):     Preise für diesen Laden überschreiben, z. B. { torso = 400 }
-- blip = false:          kein Blip auf der Karte
Config.Shops = {
    { coords = vector3(72.3, -1399.1, 29.4),     title = 'KLEIDUNGSLADEN' },
    { coords = vector3(-703.8, -152.3, 37.4),    title = 'PONSONBYS', prices = { torso = 400, pants = 250, shoes = 220 } },
    { coords = vector3(-167.9, -299.0, 39.7),    title = 'PONSONBYS', prices = { torso = 400, pants = 250, shoes = 220 } },
    { coords = vector3(428.7, -800.1, 29.5),     title = 'KLEIDUNGSLADEN' },
    { coords = vector3(-829.4, -1073.7, 11.3),   title = 'KLEIDUNGSLADEN' },
    { coords = vector3(-1447.8, -242.5, 49.8),   title = 'PONSONBYS', prices = { torso = 400, pants = 250, shoes = 220 } },
    { coords = vector3(11.6, 6514.2, 31.9),      title = 'KLEIDUNGSLADEN' },
    { coords = vector3(123.6, -219.4, 54.6),     title = 'KLEIDUNGSLADEN' },
    { coords = vector3(1696.3, 4829.3, 42.1),    title = 'KLEIDUNGSLADEN' },
    { coords = vector3(618.1, 2759.6, 42.1),     title = 'KLEIDUNGSLADEN' },
    { coords = vector3(1190.6, 2713.4, 38.2),    title = 'KLEIDUNGSLADEN' },
    { coords = vector3(-1193.4, -772.3, 17.3),   title = 'KLEIDUNGSLADEN' },
    { coords = vector3(-3172.5, 1048.1, 20.9),   title = 'KLEIDUNGSLADEN' },
    { coords = vector3(-1108.4, 2708.9, 19.1),   title = 'KLEIDUNGSLADEN' },
    { coords = vector3(-1336.8, -1278.6, 4.9),   title = 'MASKENLADEN', categories = { 'mask', 'helmet', 'glasses' } }
}

Config.Blip = { sprite = 73, color = 47, scale = 0.7, label = 'Kleidungsladen' }
Config.Marker = { type = 27, size = vector3(1.2, 1.2, 0.6), color = { r = 47, g = 123, b = 255, a = 140 }, drawDistance = 12.0 }
