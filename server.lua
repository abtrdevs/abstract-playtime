local playerPlaytime = {}

local function loadPlaytime(source)
    local identifier = GetPlayerIdentifiers(source)[1]
    local result = MySQL.Sync.fetchScalar('SELECT playtime FROM users WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    })

    if result then
        playerPlaytime[source] = result
    else
        playerPlaytime[source] = 0
        MySQL.Async.execute('INSERT INTO users (identifier, playtime) VALUES (@identifier, @playtime)', {
            ['@identifier'] = identifier,
            ['@playtime'] = 0
        })
    end

    TriggerClientEvent('playtime:update', source, playerPlaytime[source])
end

local function savePlaytime(source)
    local identifier = GetPlayerIdentifiers(source)[1]
    local playtime = playerPlaytime[source] or 0

    MySQL.Async.execute('UPDATE users SET playtime = @playtime WHERE identifier = @identifier', {
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
    
    playerPlaytime[source] = playerPlaytime[source] + 60

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