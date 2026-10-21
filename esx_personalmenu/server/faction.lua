local offers = {}
local nextOfferId = 0
local lastAction = {}

local function isBlacklisted(jobName)
    for _, name in ipairs(Config.Faction.BlacklistedJobs) do
        if name == jobName then return true end
    end
    return false
end

local function onCooldown(source)
    local now = GetGameTimer()
    if lastAction[source] and now - lastAction[source] < 1000 then return true end
    lastAction[source] = now
    return false
end

-- Liefert die Ränge eines Jobs sortiert, inkl. niedrigstem und höchstem Rang
function PM.GetJobData(jobName)
    local jobs = (ESX.GetJobs and ESX.GetJobs()) or ESX.Jobs or {}
    local job = jobs[jobName]
    if not job then return nil end

    local grades, sorted = {}, {}
    for key, grade in pairs(job.grades or {}) do
        local number = tonumber(grade.grade or key)
        if number then
            grades[number] = grade
            sorted[#sorted + 1] = number
        end
    end
    table.sort(sorted)
    if #sorted == 0 then return nil end

    return {
        name   = jobName,
        label  = job.label,
        grades = grades,
        sorted = sorted,
        min    = sorted[1],
        max    = sorted[#sorted]
    }
end

-- Gibt die Jobdaten zurück, wenn der Spieler den höchsten Rang seines Jobs hat
function PM.GetBossJob(xPlayer)
    if not Config.Faction.Enabled then return nil end

    local job = xPlayer.getJob()
    if isBlacklisted(job.name) then return nil end

    local jobData = PM.GetJobData(job.name)
    if jobData and job.grade >= jobData.max then
        return jobData
    end
end

local function gradeLabel(jobData, grade)
    local data = jobData.grades[grade]
    return data and data.label or tostring(grade)
end

local function getSocietyMoney(jobName)
    if GetResourceState('esx_addonaccount') ~= 'started' then return nil end

    local p, done = promise.new(), false
    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. jobName, function(account)
        if done then return end
        done = true
        p:resolve(account and account.money or nil)
    end)
    SetTimeout(1000, function()
        if done then return end
        done = true
        p:resolve(nil)
    end)

    return Citizen.Await(p)
end

local function unemployedGrade()
    local jobData = PM.GetJobData(Config.Faction.UnemployedJob)
    return jobData and jobData.min or 0
end

ESX.RegisterServerCallback('esx_personalmenu:getFactionData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(nil) end

    local job = xPlayer.getJob()
    local bossJob = PM.GetBossJob(xPlayer)

    cb({
        job          = job.name,
        jobLabel     = job.label,
        grade        = job.grade,
        gradeLabel   = job.grade_label,
        salary       = job.grade_salary,
        isBoss       = bossJob ~= nil,
        societyMoney = bossJob and Config.Faction.ShowSocietyMoney and getSocietyMoney(job.name) or nil,
        canResign    = Config.Faction.AllowResign and job.name ~= Config.Faction.UnemployedJob
    })
end)

ESX.RegisterServerCallback('esx_personalmenu:getNearbyPlayers', function(source, cb, ids)
    local result = {}
    if type(ids) ~= 'table' then return cb(result) end

    for i = 1, math.min(#ids, 32) do
        local id = tonumber(ids[i])
        local xTarget = id and id ~= source and ESX.GetPlayerFromId(id)

        if xTarget and PM.IsNear(source, id, Config.Faction.NearbyDistance) then
            local job = xTarget.getJob()
            result[#result + 1] = {
                id         = id,
                name       = xTarget.getName(),
                job        = job.name,
                jobLabel   = job.label,
                grade      = job.grade,
                gradeLabel = job.grade_label
            }
        end
    end

    cb(result)
end)

ESX.RegisterServerCallback('esx_personalmenu:getEmployees', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local jobData = xPlayer and Config.Faction.AllowRemoteManagement and PM.GetBossJob(xPlayer)
    if not jobData then return cb(nil) end

    local list, online = {}, {}

    -- Online-Spieler zuerst (deren Daten in der DB können veraltet sein)
    for _, xTarget in pairs(PM.GetOnlinePlayers()) do
        online[xTarget.identifier] = true
        local job = xTarget.getJob()
        if job.name == jobData.name and xTarget.identifier ~= xPlayer.identifier then
            list[#list + 1] = {
                identifier = xTarget.identifier,
                name       = xTarget.getName(),
                grade      = job.grade,
                gradeLabel = job.grade_label,
                online     = true
            }
        end
    end

    local rows = MySQL.query.await('SELECT identifier, firstname, lastname, job_grade FROM users WHERE job = ?', { jobData.name }) or {}
    for _, row in ipairs(rows) do
        if not online[row.identifier] then
            local name = ('%s %s'):format(row.firstname or '', row.lastname or ''):gsub('^%s+', ''):gsub('%s+$', '')
            list[#list + 1] = {
                identifier = row.identifier,
                name       = name ~= '' and name or row.identifier,
                grade      = row.job_grade,
                gradeLabel = gradeLabel(jobData, row.job_grade),
                online     = false
            }
        end
    end

    table.sort(list, function(a, b)
        if a.grade ~= b.grade then return a.grade > b.grade end
        return a.name < b.name
    end)

    cb(list)
end)

ESX.RegisterServerCallback('esx_personalmenu:manageEmployee', function(source, cb, action, target)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or onCooldown(source) then return cb(false) end

    local jobData = PM.GetBossJob(xPlayer)
    if not jobData then
        PM.Notify(source, 'Dazu hast du keine Berechtigung.', 'error')
        return cb(false)
    end

    if (action ~= 'promote' and action ~= 'demote' and action ~= 'fire') or type(target) ~= 'table' then
        return cb(false)
    end

    local xTarget, identifier
    if target.type == 'player' then
        local id = tonumber(target.id)
        xTarget = id and ESX.GetPlayerFromId(id)
        if not xTarget then return cb(false) end
        if not PM.IsNear(source, id, Config.Faction.NearbyDistance) then
            PM.Notify(source, 'Die Person ist zu weit entfernt.', 'error')
            return cb(false)
        end
    elseif target.type == 'identifier' and Config.Faction.AllowRemoteManagement then
        identifier = tostring(target.id)
        xTarget = ESX.GetPlayerFromIdentifier(identifier)
    else
        return cb(false)
    end

    local currentJob, currentGrade, targetName
    if xTarget then
        local job = xTarget.getJob()
        identifier, currentJob, currentGrade, targetName = xTarget.identifier, job.name, job.grade, xTarget.getName()
    else
        local row = MySQL.single.await('SELECT firstname, lastname, job, job_grade FROM users WHERE identifier = ?', { identifier })
        if not row then return cb(false) end
        currentJob, currentGrade = row.job, row.job_grade
        targetName = ('%s %s'):format(row.firstname or '', row.lastname or '')
    end

    if identifier == xPlayer.identifier then return cb(false) end

    if currentJob ~= jobData.name then
        PM.Notify(source, 'Diese Person gehört nicht zu deiner Fraktion.', 'error')
        return cb(false)
    end

    if currentGrade >= jobData.max then
        PM.Notify(source, 'Du kannst keine Personen mit dem höchsten Rang verwalten.', 'error')
        return cb(false)
    end

    local newJob, newGrade = jobData.name, nil
    if action == 'promote' then
        for _, grade in ipairs(jobData.sorted) do
            if grade > currentGrade then newGrade = grade break end
        end
        if not newGrade or (newGrade == jobData.max and not Config.Faction.AllowPromoteToBoss) then
            PM.Notify(source, 'Diese Person kann nicht weiter befördert werden.', 'error')
            return cb(false)
        end
    elseif action == 'demote' then
        for i = #jobData.sorted, 1, -1 do
            if jobData.sorted[i] < currentGrade then newGrade = jobData.sorted[i] break end
        end
        if not newGrade then
            PM.Notify(source, 'Diese Person hat bereits den niedrigsten Rang.', 'error')
            return cb(false)
        end
    else
        newJob, newGrade = Config.Faction.UnemployedJob, unemployedGrade()
    end

    if xTarget then
        xTarget.setJob(newJob, newGrade)
    else
        MySQL.update.await('UPDATE users SET job = ?, job_grade = ? WHERE identifier = ? AND job = ?',
            { newJob, newGrade, identifier, jobData.name })
    end

    local messages = {
        promote = { 'Du hast %s zum Rang %s befördert.', 'Du wurdest zum Rang %s befördert.' },
        demote  = { 'Du hast %s zum Rang %s degradiert.', 'Du wurdest zum Rang %s degradiert.' },
        fire    = { 'Du hast %s gefeuert.', 'Du wurdest aus der Fraktion %s entlassen.' }
    }
    local newLabel = action == 'fire' and jobData.label or gradeLabel(jobData, newGrade)

    PM.Notify(source, messages[action][1]:format(targetName, newLabel), 'success')
    if xTarget then
        PM.Notify(xTarget.source, messages[action][2]:format(newLabel), action == 'fire' and 'error' or 'info')
    end

    PM.Log('Fraktionsverwaltung', ('**%s** (%s) → %s: **%s** (%s) | Neuer Job: %s / %s'):format(
        xPlayer.getName(), jobData.label, action, targetName, identifier, newJob, newGrade))

    cb(true)
end)

local function applyHire(xBoss, xTarget, jobData)
    xTarget.setJob(jobData.name, jobData.min)
    PM.Notify(xBoss.source, ('Du hast %s eingestellt.'):format(xTarget.getName()), 'success')
    PM.Notify(xTarget.source, ('Du arbeitest jetzt als %s.'):format(jobData.label), 'success')
    PM.Log('Fraktionsverwaltung', ('**%s** hat **%s** (%s) bei %s eingestellt.'):format(
        xBoss.getName(), xTarget.getName(), xTarget.identifier, jobData.label))
end

ESX.RegisterServerCallback('esx_personalmenu:hire', function(source, cb, targetId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or onCooldown(source) then return cb(false) end

    local jobData = PM.GetBossJob(xPlayer)
    if not jobData then
        PM.Notify(source, 'Dazu hast du keine Berechtigung.', 'error')
        return cb(false)
    end

    targetId = tonumber(targetId)
    local xTarget = targetId and targetId ~= source and ESX.GetPlayerFromId(targetId)
    if not xTarget then return cb(false) end

    if not PM.IsNear(source, targetId, Config.Faction.NearbyDistance) then
        PM.Notify(source, 'Die Person ist zu weit entfernt.', 'error')
        return cb(false)
    end

    if xTarget.getJob().name == jobData.name then
        PM.Notify(source, 'Diese Person arbeitet bereits in deiner Fraktion.', 'error')
        return cb(false)
    end

    if not Config.Faction.RequireAcceptance then
        applyHire(xPlayer, xTarget, jobData)
        return cb(true)
    end

    nextOfferId = nextOfferId + 1
    offers[nextOfferId] = {
        boss    = source,
        target  = targetId,
        job     = jobData.name,
        expires = os.time() + Config.Faction.OfferTimeout
    }

    TriggerClientEvent('esx_personalmenu:jobOffer', targetId, nextOfferId, jobData.label, xPlayer.getName(), Config.Faction.OfferTimeout)
    PM.Notify(source, ('Jobangebot an %s gesendet.'):format(xTarget.getName()), 'info')
    cb(true)
end)

RegisterNetEvent('esx_personalmenu:answerOffer', function(offerId, accepted)
    local source = source
    local offer = offers[offerId]
    if not offer or offer.target ~= source then return end
    offers[offerId] = nil

    local xTarget = ESX.GetPlayerFromId(source)
    local xBoss = ESX.GetPlayerFromId(offer.boss)
    if not xTarget then return end

    if os.time() > offer.expires then
        return PM.Notify(source, 'Das Jobangebot ist abgelaufen.', 'error')
    end

    if not accepted then
        PM.Notify(source, 'Du hast das Jobangebot abgelehnt.', 'info')
        if xBoss then PM.Notify(offer.boss, ('%s hat das Jobangebot abgelehnt.'):format(xTarget.getName()), 'error') end
        return
    end

    local jobData = xBoss and PM.GetBossJob(xBoss)
    if not jobData or jobData.name ~= offer.job then
        return PM.Notify(source, 'Das Jobangebot ist nicht mehr gültig.', 'error')
    end

    if not PM.IsNear(source, offer.boss, Config.Faction.NearbyDistance * 2) then
        return PM.Notify(source, 'Du bist zu weit vom Arbeitgeber entfernt.', 'error')
    end

    applyHire(xBoss, xTarget, jobData)
end)

ESX.RegisterServerCallback('esx_personalmenu:resign', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not Config.Faction.AllowResign or onCooldown(source) then return cb(false) end

    local job = xPlayer.getJob()
    if job.name == Config.Faction.UnemployedJob then return cb(false) end

    xPlayer.setJob(Config.Faction.UnemployedJob, unemployedGrade())
    PM.Notify(source, ('Du hast bei %s gekündigt.'):format(job.label), 'info')
    PM.Log('Fraktionsverwaltung', ('**%s** (%s) hat bei %s gekündigt.'):format(xPlayer.getName(), xPlayer.identifier, job.label))
    cb(true)
end)

AddEventHandler('playerDropped', function()
    local source = source
    lastAction[source] = nil
    for id, offer in pairs(offers) do
        if offer.boss == source or offer.target == source then
            offers[id] = nil
        end
    end
end)
