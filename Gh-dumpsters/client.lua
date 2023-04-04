local QBCore = exports['qb-core']:GetCoreObject()
local Dumpster
local DumpsterCoords
local NearbyDumpster
local Dumpsters = {
    218085040,
    666561306,
    -58485588,
    -206690185,
    1511880420,
    682791951
}
local Slots = 20
local Weight = 100000

--- Standard function to round a number.
local function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

RegisterNetEvent('Gh-dumpsters:search:start', function(RandomTimer)
    local ped = PlayerPedId()
    QBCore.Functions.Progressbar("searching_dumpster", "search", RandomTimer, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@',
        anim = 'weed_crouch_checkingleaves_idle_01_inspector',
        flags = 16,
    }, {}, {}, function() -- Done
        DoingSomething = false
        ClearPedTasks(ped)
    end, function()
        DoingSomething = false
        ClearPedTasks(ped)
        TriggerServerEvent('Gh-dumpsters:search:cancel')
    end)
end)

exports['qb-target']:AddTargetModel(Dumpsters, {
    options = {
        {
            icon = 'fas fa-dumpster',
            label = 'Search',
            action = function(entity)
                TriggerServerEvent('Gh-dumpsters:search:check', GetEntityCoords(entity))
            end
        },
        {
            icon = 'fas fa-dumpster',
            label = 'Open Dumpster',
            action = function(entity)
                local DumpsterCoords = GetEntityCoords(entity)
                if DumpsterCoords.x < 0 then DumpsterX = -DumpsterCoords.x else DumpsterX = DumpsterCoords.x end
                if DumpsterCoords.y < 0 then DumpsterY = -DumpsterCoords.y else DumpsterY = DumpsterCoords.y end
                DumpsterX = round(DumpsterX, 1)
                DumpsterY = round(DumpsterY, 1)
                TriggerEvent("inventory:client:SetCurrentStash", "Dumpster | "..DumpsterX.." | "..DumpsterY)
                TriggerServerEvent("inventory:server:OpenInventory", "stash", "Dumpster | "..DumpsterX.." | "..DumpsterY, {
                    maxweight = Weight,
                    slots = Slots,
                })
            end
        }
    },
    distance = 2.0
})
