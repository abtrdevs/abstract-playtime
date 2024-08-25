local playerPlaytime = 0

RegisterNetEvent('playtime:update')
AddEventHandler('playtime:update', function(time)
    playerPlaytime = time
end)

local function disarmPlayer()
    if playerPlaytime < Config.RequiredPlaytime then
        local ped = PlayerPedId()
        local weapon = GetSelectedPedWeapon(ped)

        if weapon ~= GetHashKey('WEAPON_UNARMED') then
            exports.ox_inventory:Disarm(ped)
            TriggerEvent('chat:addMessage', {
                args = { '[!]', 'You cannot equip weapons until you have met the playtime requirement!' }
            })
        end
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        disarmPlayer()
    end
end)
