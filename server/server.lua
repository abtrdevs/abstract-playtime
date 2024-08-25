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
