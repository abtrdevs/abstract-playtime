local playerPlaytime = 0

RegisterNetEvent('playtime:update')
AddEventHandler('playtime:update', function(time)
    playerPlaytime = time
end)

local function disarmPlayerIfNeeded()
    if playerPlaytime < Config.RequiredPlaytime then
        local ped = PlayerPedId()
        local weapon = GetSelectedPedWeapon(ped)

        if weapon ~= GetHashKey('WEAPON_UNARMED') then
            TriggerEvent('ox_inventory:disarm', PlayerId(), true)
            TriggerEvent('chat:addMessage', {
                args = { '[!]', 'You cannot equip weapons until you have met the playtime of 24hrs requirement!' }
            })
        end
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        disarmPlayerIfNeeded()
    end
end)

RegisterCommand('playtime', function()
    local hours = math.floor(playerPlaytime / 3600)
    local minutes = math.floor((playerPlaytime % 3600) / 60)
    local seconds = playerPlaytime % 60

    TriggerEvent('chat:addMessage', {
        args = { '[!]', string.format('You have been in the server for %d hours, %d minutes, %d seconds.', hours, minutes, seconds) }
    })
end, false)
