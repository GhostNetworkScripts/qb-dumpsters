local QBCore = exports['qb-core']:GetCoreObject()
local DumpsterSearched = {}
local PreviousDumpster = {}
local Cancelled = {}
local RestartTimer = 15 -- seconds
local RewardInventory = true -- true = give items inside of an inventory box, false = give item directly
local Loot = {
    ['tier1'] = {
        'plastic',
        'metalscrap',
        'copper',
        'aluminum',
        'iron',
        'steel',
        'glass',
        'tosti', 
        'coffee', 
        'vodka'
    },
    ['tier2'] = {
        'rolex',
        'diamond_ring',
        'goldchain',
        'cryptostick',
        'vodka',
        'bandage',
        'pisltol_ammo',
        'advancedlockpick'
    },
    ['tier3'] = {
        'advancedlockpick',
        'trojan_usb'
    }
}

local function CreateLog(id, source, Player)
    local Log = {
        [1] = 'Tried to search a dumpster too far away. [Log #1]',
        [2] = 'Tried to search a dumpster that is too close to his previous one. [Log #2]',
    }
    if not Log[id] then TriggerEvent('qb-log:server:CreateLog', 'dumpsters', 'Dumpsters', 'green', 'Tried to create a log which doesn\'t exist. #'..id) print('Tried to create a log which doesn\'t exist. #'..id) return end
    TriggerEvent('qb-log:server:CreateLog', 'dumpsters', 'Dumpsters', 'green', string.format("**%s** (CitizenID: %s | ID: %s) - %s", GetPlayerName(source), Player.PlayerData.citizenid, source, Log[id]))
end

local function RestartDumpster(DumpsterCoordsX, DumpsterCoordsY, source)
    local EndTime = os.time() + RestartTimer

    while os.time() < EndTime do
        Wait(1000)
    end

    for i = 1, #DumpsterSearched do
        if not DumpsterSearched[i] then return end
        if DumpsterSearched[i].x == DumpsterCoordsX and DumpsterSearched[i].y == DumpsterCoordsY then
            table.remove(DumpsterSearched, i)
            break
        end
    end
end

local function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function HasSearched(DumpsterCoordsX, DumpsterCoordsY)
    for i = 1, #DumpsterSearched do 
        if DumpsterSearched[i].x == DumpsterCoordsX and DumpsterSearched[i].y == DumpsterCoordsY then return true end
    end
    return false
end

local function GetTier(Chance)
    if Chance <= 80 then return 'tier1'
    elseif Chance <= 98 then return 'tier2' end
    return 'tier3'
end

local function GetAmount(Tier)
    if Tier == 'tier1' then return math.random(3, 10)
    elseif Tier == 'tier2' then return math.random(1, 4) end
    return math.random(1, 2)
end

RegisterNetEvent('Gh-dumpsters:search:check', function(DumpsterCoords)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(src))
    local DumpsterCoordsX = round(DumpsterCoords.x, 3)
    local DumpsterCoordsY = round(DumpsterCoords.y, 3)
    local DumpsterCoordsZ = round(DumpsterCoords.z, 3)
    local RandomTimer = math.random(3000, 6000)

    if #(PlayerCoords - vector3(DumpsterCoordsX, DumpsterCoordsY, DumpsterCoordsZ)) > 3 then CreateLog(1, src, Player) return end

    TriggerClientEvent('Gh-dumpsters:search:start', src, RandomTimer)
    SetTimeout(RandomTimer - 50, function()
        if HasSearched(DumpsterCoordsX, DumpsterCoordsY) then TriggerClientEvent('QBCore:Notify', src, 'It seems like this one has already been searched', 'error') return end
        if not PreviousDumpster[src] then PreviousDumpster[src] = DumpsterCoords
        elseif (#(PreviousDumpster[src] - DumpsterCoords) < 0.8) and not PreviousDumpster[src] == DumpsterCoords then CreateLog(2, src, Player) return end
        if Cancelled[src] then Cancelled[src] = false return end

        DumpsterSearched[#DumpsterSearched + 1] = {x = DumpsterCoordsX, y = DumpsterCoordsY}
        PreviousDumpster[src] = DumpsterCoords

        if not RewardInventory then
            for i = 1, 3 do
                local Tier = GetTier(math.random(1, 100))
                local Item = Loot[Tier][math.random(1, #Loot[Tier])]
                local Amount = GetAmount(Tier)
                Player.Functions.AddItem(Item, Amount)
                TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items[Item], "add")
                TriggerEvent('qb-log:server:CreateLog', 'dumpsters', 'Dumpsters', 'green', string.format("**%s** (CitizenID: %s | ID: %s) - Found %sx %s. Player: %s Dumpster: %s", GetPlayerName(src), Player.PlayerData.citizenid, src, Amount, QBCore.Shared.Items[Item].name, PlayerCoords, DumpsterCoords))
            end
        else
            local RandomName = "Dumpster"..math.random(1, 999)
            local Dumpster = {}
            Dumpster.name = "trunk-"..RandomName
            Dumpster.label = RandomName
            Dumpster.maxweight = 8000
            Dumpster.slots = 5
            Dumpster.inventory = {}
            TriggerEvent('inventory:server:addTrunkItems', RandomName, {})
            for i = 1, 3 do
                local Tier = GetTier(math.random(1, 100))
                local Item = Loot[Tier][math.random(1, #Loot[Tier])]
                local Amount = GetAmount(Tier)
                local itemInfo = QBCore.Shared.Items[Item]
                if itemInfo then
                    Dumpster.inventory[i] = {
                            name = itemInfo["name"],
                            amount = Amount,
                            info = "",
                            label = itemInfo["label"],
                            description = itemInfo["description"] or "",
                            weight = itemInfo["weight"],
                            type = itemInfo["type"],
                            unique = itemInfo["unique"],
                            useable = itemInfo["useable"],
                            image = itemInfo["image"],
                            slot = i,
                    }
                end
                TriggerEvent('qb-log:server:CreateLog', 'dumpsters', 'Dumpsters', 'green', string.format("**%s** (CitizenID: %s | ID: %s) - Created %sx %s inside of %s. Player: %s Dumpster: %s", GetPlayerName(src), Player.PlayerData.citizenid, src, Amount, QBCore.Shared.Items[Item].name, RandomName, PlayerCoords, DumpsterCoords))
            end
            TriggerEvent('inventory:server:addTrunkItems', RandomName, Dumpster.inventory)
            Wait(20)
            TriggerClientEvent("inventory:client:OpenInventory", src, {}, Player.PlayerData.items, Dumpster)
        end
        RestartDumpster(DumpsterCoordsX, DumpsterCoordsY, src)
    end)
end)

RegisterNetEvent('Gh-dumpsters:search:cancel', function()
    Cancelled[source] = true
    TriggerClientEvent('QBCore:Notify', source, 'Cancelled', 'error')
end)
