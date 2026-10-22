ESX = nil

local ok, obj = pcall(function() return exports['es_extended']:getSharedObject() end)
if ok and obj then
    ESX = obj
else
    TriggerEvent('esx:getSharedObject', function(o) ESX = o end)
end

local L = Config.Locale
local PERM_KEYS <const> = { 'members', 'funds', 'settings', 'logs' }

local sessions = {}       -- [source] = { job = name, location = vector3|nil }
local invites = {}        -- [target] = { job, grade, from, fromName, expires }
local lastAction = {}
local settingsCache = {}

-- Helfer -------------------------------------------------------------------------------------
local function groupDigits(n)
    local s = tostring(math.floor(math.abs(n)))
    return (s:reverse():gsub('(%d%d%d)', '%1.'):reverse():gsub('^%.', ''))
end

local function money(n) return Config.UI.currency .. groupDigits(n) end

local function decode(str)
    if type(str) ~= 'string' or str == '' then return nil end
    local okDecode, data = pcall(json.decode, str)
    return okDecode and type(data) == 'table' and data or nil
end

local function notify(source, text, notifyType)
    if source then Config.Notify(source, text, notifyType or 'success') end
end

local function toInt(v)
    v = tonumber(v)
    if not v or v ~= v or v == math.huge or v == -math.huge then return nil end
    return math.floor(v)
end

local function relTime(ts)
    local now = os.time()
    local diff = now - ts
    if diff < 60 then return L.justNow end
    if diff < 3600 then return L.minutesAgo:format(math.floor(diff / 60)) end
    if os.date('%Y%m%d', ts) == os.date('%Y%m%d', now) then return L.hoursAgo:format(math.floor(diff / 3600)) end
    if os.date('%Y%m%d', ts) == os.date('%Y%m%d', now - 86400) then return L.yesterday end
    return os.date('%d.%m.', ts)
end

local function clockTime(ts)
    local now = os.time()
    if os.date('%Y%m%d', ts) == os.date('%Y%m%d', now) then return L.today .. ', ' .. os.date('%H:%M', ts) end
    if os.date('%Y%m%d', ts) == os.date('%Y%m%d', now - 86400) then return L.yesterday .. ', ' .. os.date('%H:%M', ts) end
    return os.date('%d.%m., %H:%M', ts)
end

local function onlinePlayers()
    if ESX.GetExtendedPlayers then return ESX.GetExtendedPlayers() end
    local list = {}
    for _, id in ipairs(ESX.GetPlayers()) do list[#list + 1] = ESX.GetPlayerFromId(id) end
    return list
end

local function isOnDuty(xPlayer)
    if Config.DutyMode == 'duty' then return xPlayer.job.onDuty ~= false end
    return true
end

local function playerCoords(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return nil end
    local c = GetEntityCoords(ped)
    if c.x == 0.0 and c.y == 0.0 and c.z == 0.0 then return nil end -- ohne OneSync
    return c
end

-- Jobs und Rechte -------------------------------------------------------------------------------
local function getJob(name)
    local jobs = (ESX.GetJobs and ESX.GetJobs()) or ESX.Jobs or {}
    local job = jobs[name]
    if not job then return nil end

    local grades, byGrade = {}, {}
    for key, g in pairs(job.grades or {}) do
        local number = tonumber(g.grade or key)
        if number then
            local entry = { grade = number, label = g.label, salary = tonumber(g.salary) or 0 }
            grades[#grades + 1] = entry
            byGrade[number] = entry
        end
    end
    table.sort(grades, function(a, b) return a.grade < b.grade end)
    if #grades == 0 then return nil end

    return { name = name, label = job.label, grades = grades, byGrade = byGrade, min = grades[1].grade, max = grades[#grades].grade }
end

local function hasGrade(grade, req, jobData)
    if req == 'boss' then return grade >= jobData.max end
    if type(req) == 'number' then return grade >= req end
    if type(req) == 'table' then
        for _, g in ipairs(req) do if g == grade then return true end end
    end
    return false
end

local function getPermissions(xPlayer, jobData)
    local jobConfig = Config.Jobs[jobData.name] or {}
    local perms, any = {}, false
    for _, key in ipairs(PERM_KEYS) do
        local req = Config.Permissions[key]
        if jobConfig.permissions and jobConfig.permissions[key] ~= nil then req = jobConfig.permissions[key] end
        perms[key] = hasGrade(xPlayer.job.grade, req, jobData)
        any = any or perms[key]
    end
    return perms, any
end

local function canAssign(ownGrade, grade)
    local mode = Config.Rules.maxAssignGrade
    if mode == 'any' then return true end
    if mode == 'own' then return grade <= ownGrade end
    return grade < ownGrade
end

-- Einstellungen ------------------------------------------------------------------------------------
local function getSettings(job)
    if settingsCache[job] then return settingsCache[job] end
    local stored = decode(MySQL.scalar.await('SELECT data FROM pulse_bossmenu_settings WHERE job = ?', { job })) or {}
    local settings = {}
    for key, default in pairs(Config.DefaultSettings) do
        if stored[key] ~= nil then settings[key] = stored[key] == true else settings[key] = default end
    end
    settingsCache[job] = settings
    return settings
end

local PAYDAY_SETTINGS <const> = { payFromSociety = true, offDutyPay = true }

-- Nur Schalter, die gerade eine Wirkung haben, werden in der UI gezeigt
local function visibleSettings(job)
    local out = {}
    for key, value in pairs(getSettings(job)) do
        if Config.Payday.enabled or not PAYDAY_SETTINGS[key] then out[key] = value end
    end
    return out
end

-- Firmenkasse ----------------------------------------------------------------------------------------
local function getSociety(job)
    local name = (Config.Jobs[job] and Config.Jobs[job].society) or (Config.Society.prefix .. job)
    local account
    TriggerEvent('esx_addonaccount:getSharedAccount', name, function(acc) account = acc end)
    return account
end

-- Protokoll / Buchungen ----------------------------------------------------------------------------------
local function webhook(job, text, who)
    local url = (Config.Jobs[job] and Config.Jobs[job].webhook) or Config.Webhook
    if not url or url == '' then return end
    local jobData = getJob(job)
    PerformHttpRequest(url, function() end, 'POST', json.encode({
        username = 'Bossmenü',
        embeds = { { title = jobData and jobData.label or job, description = text, color = 3111935, footer = { text = who or '' }, timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ') } }
    }), { ['Content-Type'] = 'application/json' })
end

local function addLog(job, kind, text, who)
    MySQL.insert.await('INSERT INTO pulse_bossmenu_logs (job, kind, text, who) VALUES (?, ?, ?, ?)', { job, kind, text, who })
    webhook(job, text, who)
end

local function addTransaction(job, txType, amount, note, who)
    MySQL.insert.await('INSERT INTO pulse_bossmenu_transactions (job, type, amount, note, who) VALUES (?, ?, ?, ?, ?)', { job, txType, amount, note, who })
end

-- Wenn "Änderungen melden" aktiv ist, sehen alle Mitglieder online die Aktion
local function notifyMembers(job, text, except)
    if not getSettings(job).notifyAll then return end
    for _, xPlayer in ipairs(onlinePlayers()) do
        if xPlayer.job.name == job and not except[xPlayer.source] then notify(xPlayer.source, text) end
    end
end

-- Daten für die UI ------------------------------------------------------------------------------------------
local function uiGrades(jobData)
    local list = {}
    for i, g in ipairs(jobData.grades) do list[i] = { grade = g.grade, label = g.label, salary = g.salary } end
    return list
end

local function getMembers(job)
    local rows = MySQL.query.await([[
        SELECT u.identifier, u.firstname, u.lastname, u.job_grade, UNIX_TIMESTAMP(m.hired_at) AS hired
        FROM users u
        LEFT JOIN pulse_bossmenu_members m ON m.identifier = u.identifier AND m.job = u.job
        WHERE u.job = ?
    ]], { job }) or {}

    local members, byId = {}, {}
    for _, row in ipairs(rows) do
        local m = {
            identifier = row.identifier,
            name = ('%s %s'):format(row.firstname or '', row.lastname or ''):gsub('^%s+', ''):gsub('%s+$', ''),
            grade = tonumber(row.job_grade) or 0,
            online = false,
            since = row.hired and os.date('%m/%Y', math.floor(row.hired)) or nil
        }
        if m.name == '' then m.name = row.identifier end
        members[#members + 1] = m
        byId[m.identifier] = m
    end

    -- Online-Daten sind aktueller als die Datenbank (ESX speichert Jobwechsel erst später)
    local left = {}
    for _, xPlayer in ipairs(onlinePlayers()) do
        if xPlayer.job.name ~= job and byId[xPlayer.identifier] then
            left[xPlayer.identifier] = true
        elseif xPlayer.job.name == job then
            local m = byId[xPlayer.identifier]
            if not m then
                m = { identifier = xPlayer.identifier }
                members[#members + 1] = m
            end
            m.name = xPlayer.getName()
            m.grade = xPlayer.job.grade
            m.online = isOnDuty(xPlayer)
        end
    end

    if next(left) then
        local filtered = {}
        for _, m in ipairs(members) do if not left[m.identifier] then filtered[#filtered + 1] = m end end
        members = filtered
    end
    return members
end

local function getTransactions(job)
    local rows = MySQL.query.await(
        'SELECT type, amount, note, who, UNIX_TIMESTAMP(created_at) AS ts FROM pulse_bossmenu_transactions WHERE job = ? ORDER BY id DESC LIMIT ?',
        { job, Config.History.transactions }) or {}
    local list = {}
    for i, r in ipairs(rows) do list[i] = { type = r.type, amount = r.amount, note = r.note, who = r.who, time = clockTime(math.floor(r.ts)) } end
    return list
end

local function getLogs(job)
    local rows = MySQL.query.await(
        'SELECT kind, text, who, UNIX_TIMESTAMP(created_at) AS ts FROM pulse_bossmenu_logs WHERE job = ? ORDER BY id DESC LIMIT ?',
        { job, Config.History.logs }) or {}
    local list = {}
    for i, r in ipairs(rows) do list[i] = { kind = r.kind, text = r.text, who = r.who, time = relTime(math.floor(r.ts)) } end
    return list
end

local function getWeekChange(job)
    if not Config.UI.showWeekChange then return nil end
    local sum = MySQL.scalar.await(
        "SELECT COALESCE(SUM(CASE WHEN type = 'in' THEN amount ELSE -amount END), 0) FROM pulse_bossmenu_transactions WHERE job = ? AND created_at >= NOW() - INTERVAL 7 DAY",
        { job }) or 0
    sum = tonumber(sum) or 0
    return L.weekChange:format(sum >= 0 and '+' or '−', money(sum))
end

-- parts: welche Bereiche geschickt werden (nil = alle, die der Spieler sehen darf)
local function collect(job, perms, parts)
    local jobData = getJob(job)
    local want = function(k) return parts == nil or parts[k] end
    local data = {}

    if want('grades') then data.grades = uiGrades(jobData) end
    if want('members') then data.members = getMembers(job) end
    if want('settings') then data.settings = visibleSettings(job) end
    if perms.funds and want('funds') then
        local society = getSociety(job)
        data.balance = society and society.money or 0
        data.transactions = getTransactions(job)
        data.weekChange = getWeekChange(job)
    end
    if perms.logs and want('logs') then data.logs = getLogs(job) end
    return data
end

-- Alle anderen offenen Bossmenüs dieses Jobs aktualisieren
local function broadcast(job, except, parts)
    for src, session in pairs(sessions) do
        if session.job == job and src ~= except then
            local xPlayer = ESX.GetPlayerFromId(src)
            local jobData = getJob(job)
            local perms, any
            if xPlayer and jobData and xPlayer.job.name == job then perms, any = getPermissions(xPlayer, jobData) end
            if not any then
                sessions[src] = nil
                TriggerClientEvent('pulse_bossmenu:close', src)
            else
                local data = collect(job, perms, parts)
                data.permissions = perms
                TriggerClientEvent('pulse_bossmenu:update', src, data)
            end
        end
    end
end

-- Mitglied suchen (online oder offline)
local function findMember(job, identifier)
    if type(identifier) ~= 'string' or identifier == '' then return nil end
    local xTarget = ESX.GetPlayerFromIdentifier(identifier)
    if xTarget then
        if xTarget.job.name ~= job then return nil end
        return { identifier = identifier, name = xTarget.getName(), grade = xTarget.job.grade, xPlayer = xTarget }
    end
    local row = MySQL.single.await('SELECT firstname, lastname, job, job_grade FROM users WHERE identifier = ?', { identifier })
    if not row or row.job ~= job then return nil end
    return { identifier = identifier, name = ('%s %s'):format(row.firstname or '', row.lastname or ''), grade = tonumber(row.job_grade) or 0 }
end

local function setMemberJob(member, job, grade)
    if member.xPlayer then
        member.xPlayer.setJob(job, grade)
    else
        MySQL.update.await('UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?', { job, grade, member.identifier })
    end
end

-- Aktionen ---------------------------------------------------------------------------------------------------
local function fail(msg) return { ok = false, error = msg } end

local actions = {}

local function changeGrade(ctx, data, dir)
    if not ctx.perms.members then return fail(L.noAccess) end
    local job, jobData, own = ctx.job, ctx.jobData, ctx.xPlayer.job.grade
    if data.identifier == ctx.xPlayer.identifier then return fail(L.notYourself) end

    local member = findMember(job, data.identifier)
    if not member then return fail(L.memberNotFound) end
    if Config.Rules.onlyLowerGrades and member.grade >= own then return fail(L.targetTooHigh) end

    local grade = toInt(data.grade)
    local target = grade and jobData.byGrade[grade]
    if not target or (dir > 0 and grade <= member.grade) or (dir < 0 and grade >= member.grade) then return fail(L.gradeInvalid) end
    if not canAssign(own, grade) then return fail(L.gradeTooHigh) end

    setMemberJob(member, job, grade)

    local kind = dir > 0 and 'promote' or 'demote'
    local text = (dir > 0 and L.logPromote or L.logDemote):format(member.name, target.label)
    addLog(job, kind, text, ctx.name)
    if member.xPlayer then notify(member.xPlayer.source, (dir > 0 and L.youWerePromoted or L.youWereDemoted):format(target.label)) end
    notifyMembers(job, text, { [ctx.source] = true, [member.xPlayer and member.xPlayer.source or -1] = true })
    broadcast(job, ctx.source, { members = true, logs = true })
    return { ok = true, data = collect(job, ctx.perms, { members = true, logs = true }) }
end

actions.promote = function(ctx, data) return changeGrade(ctx, data, 1) end
actions.demote = function(ctx, data) return changeGrade(ctx, data, -1) end

actions.fire = function(ctx, data)
    if not ctx.perms.members then return fail(L.noAccess) end
    local job = ctx.job
    if data.identifier == ctx.xPlayer.identifier then return fail(L.notYourself) end

    local member = findMember(job, data.identifier)
    if not member then return fail(L.memberNotFound) end
    if Config.Rules.onlyLowerGrades and member.grade >= ctx.xPlayer.job.grade then return fail(L.targetTooHigh) end

    setMemberJob(member, Config.Rules.unemployedJob, Config.Rules.unemployedGrade)
    MySQL.update.await('DELETE FROM pulse_bossmenu_members WHERE identifier = ? AND job = ?', { member.identifier, job })

    local text = L.logFire:format(member.name)
    addLog(job, 'fire', text, ctx.name)
    if member.xPlayer then notify(member.xPlayer.source, L.youWereFired:format(ctx.jobData.label), 'error') end
    notifyMembers(job, text, { [ctx.source] = true })
    broadcast(job, ctx.source, { members = true, logs = true })
    return { ok = true, data = collect(job, ctx.perms, { members = true, logs = true }) }
end

actions.getNearbyPlayers = function(ctx)
    if not ctx.perms.members then return fail(L.noAccess) end
    local coords = playerCoords(ctx.source)
    if not coords then return fail(L.noOneSync) end

    local list = {}
    for _, xPlayer in ipairs(onlinePlayers()) do
        if xPlayer.source ~= ctx.source and xPlayer.job.name ~= ctx.job then
            local c = playerCoords(xPlayer.source)
            if c and #(c - coords) <= Config.Invite.distance then
                list[#list + 1] = { id = xPlayer.source, name = xPlayer.getName() }
            end
        end
    end
    return { ok = true, data = list }
end

actions.hire = function(ctx, data)
    if not ctx.perms.members then return fail(L.noAccess) end
    local targetId = toInt(data.id)
    local xTarget = targetId and ESX.GetPlayerFromId(targetId)
    if not xTarget or targetId == ctx.source then return fail(L.playerNotFound) end
    if xTarget.job.name == ctx.job then return fail(L.alreadyMember) end

    local a, b = playerCoords(ctx.source), playerCoords(targetId)
    if not a or not b or #(a - b) > Config.Invite.distance then return fail(L.tooFar) end

    local pending = invites[targetId]
    if pending and pending.expires > os.time() then return fail(L.alreadyInvited) end

    local grade = toInt(data.grade)
    local target = grade and ctx.jobData.byGrade[grade]
    if not target then return fail(L.gradeInvalid) end
    if not canAssign(ctx.xPlayer.job.grade, grade) then return fail(L.gradeTooHigh) end

    invites[targetId] = {
        job = ctx.job, grade = grade, from = ctx.source, fromName = ctx.name,
        expires = os.time() + Config.Invite.timeout + 2
    }
    TriggerClientEvent('pulse_bossmenu:invite', targetId, {
        faction = { name = ctx.job, label = ctx.jobData.label },
        grade = target.label,
        salary = target.salary,
        from = ctx.name,
        timeout = Config.Invite.timeout,
        text = Config.Invite.text
    })
    return { ok = true }
end

local function moveMoney(ctx, data, kind)
    if not ctx.perms.funds then return fail(L.noAccess) end
    local amount = toInt(data.amount)
    if not amount or amount <= 0 then return fail(L.amountInvalid) end
    if amount < Config.Funds.min then return fail(L.amountMin) end
    if amount > Config.Funds.max then return fail(L.amountMax) end

    local society = getSociety(ctx.job)
    if not society then return fail(L.societyMissing) end
    local xPlayer = ctx.xPlayer

    if kind == 'deposit' then
        local account = xPlayer.getAccount(Config.Funds.depositFrom)
        if not account or account.money < amount then return fail(L.notEnoughMoney) end
        xPlayer.removeAccountMoney(Config.Funds.depositFrom, amount, 'Bossmenü')
        society.addMoney(amount)
        addTransaction(ctx.job, 'in', amount, L.txDeposit, ctx.name)
        addLog(ctx.job, 'deposit', L.logDeposit:format(money(amount)), ctx.name)
    else
        if society.money < amount then return fail(L.notEnoughSociety) end
        society.removeMoney(amount)
        xPlayer.addAccountMoney(Config.Funds.withdrawTo, amount, 'Bossmenü')
        addTransaction(ctx.job, 'out', amount, L.txWithdraw, ctx.name)
        addLog(ctx.job, 'withdraw', L.logWithdraw:format(money(amount)), ctx.name)
    end

    broadcast(ctx.job, ctx.source, { funds = true, logs = true })
    return { ok = true, data = collect(ctx.job, ctx.perms, { funds = true, logs = true }) }
end

actions.deposit = function(ctx, data) return moveMoney(ctx, data, 'deposit') end
actions.withdraw = function(ctx, data) return moveMoney(ctx, data, 'withdraw') end

actions.saveSettings = function(ctx, data)
    if not ctx.perms.settings then return fail(L.noAccess) end
    local job, jobData = ctx.job, ctx.jobData
    local salaryChanges = {}

    for _, entry in ipairs(type(data.grades) == 'table' and data.grades or {}) do
        local grade, salary = toInt(entry.grade), toInt(entry.salary)
        local current = grade and jobData.byGrade[grade]
        if current and salary then
            if salary < 0 then return fail(L.amountInvalid) end
            if salary > Config.Rules.maxSalary then return fail(L.salaryTooHigh:format(money(Config.Rules.maxSalary))) end
            if salary ~= current.salary then salaryChanges[#salaryChanges + 1] = { grade = grade, label = current.label, salary = salary } end
        end
    end

    local settings = getSettings(job)
    local visible = visibleSettings(job)
    local settingChanges = {}
    if type(data.settings) == 'table' then
        for key in pairs(visible) do
            local value = data.settings[key]
            if type(value) == 'boolean' and value ~= settings[key] then settingChanges[#settingChanges + 1] = { key = key, value = value } end
        end
    end

    for _, change in ipairs(salaryChanges) do
        MySQL.update.await('UPDATE job_grades SET salary = ? WHERE job_name = ? AND grade = ?', { change.salary, job, change.grade })
        addLog(job, 'settings', L.logSalary:format(change.label, money(change.salary)), ctx.name)
    end
    if #salaryChanges > 0 then
        if ESX.RefreshJobs then ESX.RefreshJobs() end
        -- Gehalt bei Mitgliedern online sofort aktualisieren (ESX-Zahltag nutzt job.grade_salary)
        local bySalary = {}
        for _, change in ipairs(salaryChanges) do bySalary[change.grade] = change.salary end
        for _, xPlayer in ipairs(onlinePlayers()) do
            if xPlayer.job.name == job and bySalary[xPlayer.job.grade] then xPlayer.job.grade_salary = bySalary[xPlayer.job.grade] end
        end
    end

    if #settingChanges > 0 then
        for _, change in ipairs(settingChanges) do
            settings[change.key] = change.value
            addLog(job, 'settings', L.logSetting:format(L.settingNames[change.key] or change.key, change.value and L.settingOn or L.settingOff), ctx.name)
        end
        MySQL.insert.await('INSERT INTO pulse_bossmenu_settings (job, data) VALUES (?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)', { job, json.encode(settings) })
    end

    broadcast(job, ctx.source, { grades = true, settings = true, logs = true })
    return { ok = true, data = collect(job, ctx.perms, { grades = true, settings = true, logs = true }) }
end

local MUTATING <const> = { promote = true, demote = true, fire = true, hire = true, deposit = true, withdraw = true, saveSettings = true }

-- Callbacks ------------------------------------------------------------------------------------------------------
ESX.RegisterServerCallback('pulse_bossmenu:open', function(source, cb, locationIndex)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(fail(L.error)) end

    local job = xPlayer.job.name
    local jobConfig = Config.Jobs[job]
    local jobData = jobConfig and getJob(job)
    if not jobData then return cb(fail(L.notInJob)) end

    local location
    if locationIndex then
        location = jobConfig.locations and jobConfig.locations[tonumber(locationIndex) or 0]
        if not location then return cb(fail(L.notInJob)) end
        local coords = playerCoords(source)
        if coords and #(coords - location) > Config.MaxDistance then return cb(fail(L.tooFar)) end
    elseif not Config.AllowAnywhere then
        return cb(fail(L.noAccess))
    end

    local perms, any = getPermissions(xPlayer, jobData)
    if not any then return cb(fail(L.noAccess)) end

    sessions[source] = { job = job, location = location }

    local data = collect(job, perms)
    data.faction = { name = job, label = jobData.label }
    data.me = xPlayer.identifier
    data.permissions = perms
    data.ui = { brand = Config.UI.brand, currency = Config.UI.currency, quick = Config.UI.quick, rankColors = Config.UI.rankColors }
    cb({ ok = true, data = data })
end)

ESX.RegisterServerCallback('pulse_bossmenu:action', function(source, cb, name, data)
    local handler = actions[name]
    if not handler then return cb(fail(L.error)) end

    local session = sessions[source]
    local xPlayer = ESX.GetPlayerFromId(source)
    if not session or not xPlayer then return cb(fail(L.notOpen)) end
    if xPlayer.job.name ~= session.job then return cb(fail(L.notInJob)) end

    if session.location then
        local coords = playerCoords(source)
        if coords and #(coords - session.location) > Config.MaxDistance then return cb(fail(L.tooFar)) end
    end

    if MUTATING[name] then
        local now = GetGameTimer()
        if lastAction[source] and now - lastAction[source] < Config.Rules.actionCooldown then return cb(fail(L.wait)) end
        lastAction[source] = now
    end

    local jobData = getJob(session.job)
    local perms, any = getPermissions(xPlayer, jobData)
    if not any then return cb(fail(L.noAccess)) end

    local ctx = { source = source, xPlayer = xPlayer, name = xPlayer.getName(), job = session.job, jobData = jobData, perms = perms }
    local success, result = pcall(handler, ctx, type(data) == 'table' and data or {})
    if not success then
        print(('^1[pulse_bossmenu] Fehler bei %s: %s^7'):format(name, result))
        return cb(fail(L.error))
    end
    cb(result)
end)

RegisterNetEvent('pulse_bossmenu:close', function()
    sessions[source] = nil
end)

-- Einladung beantworten
RegisterNetEvent('pulse_bossmenu:inviteAnswer', function(accept, timeout)
    local src = source
    local invite = invites[src]
    invites[src] = nil
    if not invite then return end

    local xTarget = ESX.GetPlayerFromId(src)
    if not xTarget then return end
    local targetName = xTarget.getName()
    local inviterOnline = ESX.GetPlayerFromId(invite.from) and invite.from or nil

    if not accept then
        notify(inviterOnline, (timeout and L.inviteTimedOut or L.inviteDeclined):format(targetName), 'error')
        return
    end
    if invite.expires < os.time() then
        notify(src, L.inviteExpired, 'error')
        return
    end

    local jobData = getJob(invite.job)
    local grade = jobData and jobData.byGrade[invite.grade]
    if not grade then return notify(src, L.error, 'error') end

    xTarget.setJob(invite.job, invite.grade)
    MySQL.insert.await(
        'INSERT INTO pulse_bossmenu_members (identifier, job, hired_at) VALUES (?, ?, NOW()) ON DUPLICATE KEY UPDATE hired_at = NOW()',
        { xTarget.identifier, invite.job })

    local text = L.logHire:format(targetName, grade.label)
    addLog(invite.job, 'hire', text, invite.fromName)
    notify(src, L.welcome:format(jobData.label))
    notify(inviterOnline, L.inviteAccepted:format(targetName))
    notifyMembers(invite.job, text, { [src] = true, [invite.from] = true })
    broadcast(invite.job, nil, { members = true, logs = true })
end)

AddEventHandler('playerDropped', function()
    sessions[source] = nil
    invites[source] = nil
    lastAction[source] = nil
end)

-- Zahltag ---------------------------------------------------------------------------------------------------------------
local function payday()
    local byJob = {}
    for _, xPlayer in ipairs(onlinePlayers()) do
        local job = xPlayer.job.name
        if Config.Jobs[job] then
            byJob[job] = byJob[job] or {}
            byJob[job][#byJob[job] + 1] = xPlayer
        end
    end

    for job, players in pairs(byJob) do
        local settings = getSettings(job)
        local society = settings.payFromSociety and getSociety(job) or nil
        local total = 0
        for _, xPlayer in ipairs(players) do
            local salary = tonumber(xPlayer.job.grade_salary) or 0
            if salary > 0 and (settings.offDutyPay or isOnDuty(xPlayer)) then
                if settings.payFromSociety then
                    if society and society.money >= salary then
                        society.removeMoney(salary)
                        total = total + salary
                        xPlayer.addAccountMoney(Config.Payday.account, salary, 'Zahltag')
                        notify(xPlayer.source, L.paydayPaid:format(money(salary)))
                    else
                        notify(xPlayer.source, L.paydayNoMoney, 'error')
                    end
                else
                    xPlayer.addAccountMoney(Config.Payday.account, salary, 'Zahltag')
                    notify(xPlayer.source, L.paydayPaid:format(money(salary)))
                end
            end
        end
        if total > 0 then
            addTransaction(job, 'out', total, L.txPayday, L.system)
            broadcast(job, nil, { funds = true })
        end
    end
end

-- Start ----------------------------------------------------------------------------------------------------------------
MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `pulse_bossmenu_logs` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `job` VARCHAR(50) NOT NULL,
            `kind` VARCHAR(20) NOT NULL,
            `text` VARCHAR(255) NOT NULL,
            `who` VARCHAR(100) NULL DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`), KEY `idx_job` (`job`, `id`)
        ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `pulse_bossmenu_transactions` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `job` VARCHAR(50) NOT NULL,
            `type` ENUM('in', 'out') NOT NULL,
            `amount` INT UNSIGNED NOT NULL,
            `note` VARCHAR(100) NULL DEFAULT NULL,
            `who` VARCHAR(100) NULL DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`), KEY `idx_job` (`job`, `id`)
        ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `pulse_bossmenu_settings` (
            `job` VARCHAR(50) NOT NULL,
            `data` LONGTEXT NOT NULL,
            PRIMARY KEY (`job`)
        ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `pulse_bossmenu_members` (
            `identifier` VARCHAR(60) NOT NULL,
            `job` VARCHAR(50) NOT NULL,
            `hired_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`, `job`)
        ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4
    ]])

    if Config.History.keepDays > 0 then
        MySQL.update('DELETE FROM pulse_bossmenu_logs WHERE created_at < NOW() - INTERVAL ? DAY', { Config.History.keepDays })
        MySQL.update('DELETE FROM pulse_bossmenu_transactions WHERE created_at < NOW() - INTERVAL ? DAY', { Config.History.keepDays })
    end

    if Config.Payday.enabled then
        CreateThread(function()
            while true do
                Wait(Config.Payday.interval * 60000)
                payday()
            end
        end)
    end
end)
