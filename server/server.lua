local playerPlaytime = {}

local function getSteamHexIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, id in ipairs(identifiers) do
        if string.match(id, "steam:") then
            return id
        end
    end
    return nil
end

function GetPlayerGroup(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    return xPlayer.getGroup()
end

local function isAllowedGroup(source)
    local allowedGroups = {
        "admin",
        "superadmin",
    }

    local playerGroup = GetPlayerGroup(source)
    for _, group in ipairs(allowedGroups) do
        if playerGroup == group then
            return true
        end
    end

    return false
end

local function loadPlaytime(source)
    local identifier = getSteamHexIdentifier(source)
    
    if not identifier then
        print("Error: Steam hex identifier is nil.")
        return
    end

    local result = MySQL.Sync.fetchScalar('SELECT playtime FROM server_playtime WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    })

    if result then
        playerPlaytime[source] = tonumber(result) or 0
    else
        playerPlaytime[source] = 0
        MySQL.Async.execute('INSERT INTO server_playtime (identifier, playtime) VALUES (@identifier, @playtime)', {
            ['@identifier'] = identifier,
            ['@playtime'] = 0
        })
    end

    TriggerClientEvent('playtime:update', source, playerPlaytime[source])
end

local function savePlaytime(source)
    local identifier = getSteamHexIdentifier(source)

    if not identifier then
        print("Error: Steam hex identifier is nil.")
        return
    end

    local playtime = playerPlaytime[source] or 0

    MySQL.Async.execute('UPDATE server_playtime SET playtime = @playtime WHERE identifier = @identifier', {
        ['@identifier'] = identifier,
        ['@playtime'] = playtime
    })
end

RegisterNetEvent('playtime:track')
AddEventHandler('playtime:track', function()
    local source = source

    if not playerPlaytime[source] then
        loadPlaytime(source)
    end
    
    playerPlaytime[source] = (playerPlaytime[source] or 0) + 1  -- Update every second

    savePlaytime(source)

    TriggerClientEvent('playtime:update', source, playerPlaytime[source])
end)

RegisterCommand("setplaytime", function(source, args, rawCommand)
    local source = source
    if not isAllowedGroup(source) then
        TriggerClientEvent('chat:addMessage', source, {
            args = {"[!]", "You do not have permission to use this command."}
        })
        return
    end

    if #args < 3 then
        TriggerClientEvent('chat:addMessage', source, {
            args = {"[!]", "Usage: /setplaytime [hours] [minutes] [seconds]"}
        })
        return
    end

    local hours = tonumber(args[1])
    local minutes = tonumber(args[2])
    local seconds = tonumber(args[3])

    if not hours or not minutes or not seconds then
        TriggerClientEvent('chat:addMessage', source, {
            args = {"[!]", "Invalid input. Please enter numbers for hours, minutes, and seconds."}
        })
        return
    end

    local playtimeInSeconds = (hours * 3600) + (minutes * 60) + seconds

    playerPlaytime[source] = playtimeInSeconds
    savePlaytime(source)

    TriggerClientEvent('playtime:update', source, playtimeInSeconds)

    TriggerClientEvent('chat:addMessage', source, {
        args = {"[!]", "Your playtime has been updated."}
    })
end, false)


AddEventHandler('playerDropped', function()
    local source = source
    savePlaytime(source)
    playerPlaytime[source] = nil
end)

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source
    loadPlaytime(source)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)  -- Wait for 1 second
        for _, playerId in ipairs(GetPlayers()) do
            TriggerEvent('playtime:track')
        end
    end
end)
