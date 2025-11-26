-- Ouro Stores Client
local Core = exports.vorp_core:GetCore()

local OpenStores = 0
local PromptGroup = GetRandomIntInRange(0, 0xffffff)
local inStore = false
local storeNPCs = {}
local storeBlips = {}
local currentStoreId = nil
local currentStore = nil
local nuiFocused = false


-- Helper: Get distance from player to coords
local function GetPlayerDistanceFromCoords(vector)
    local playerPos = GetEntityCoords(PlayerPedId())
    return #(playerPos - vector)
end

-- Setup prompt
local function setUpPrompt()
    OpenStores = UiPromptRegisterBegin()
    UiPromptSetControlAction(OpenStores, Config.keys["G"])
    local label = VarString(10, 'LITERAL_STRING', language.openstore or "Open Store")
    UiPromptSetText(OpenStores, label)
    UiPromptSetEnabled(OpenStores, true)
    UiPromptSetVisible(OpenStores, true)
    UiPromptSetStandardMode(OpenStores, true)
    UiPromptSetGroup(OpenStores, PromptGroup, 0)
    UiPromptRegisterEnd(OpenStores)
end

-- Show prompt
local function showPrompt(label, action)
    local labelToDisplay = VarString(10, 'LITERAL_STRING', label)
    UiPromptSetActiveGroupThisFrame(PromptGroup, labelToDisplay, 0, 0, 0, 0)
    
    if UiPromptHasStandardModeCompleted(OpenStores, 0) then
        Wait(100)
        return action
    end
end

-- Add blip for store
local function AddBlip(k, store)
    if not store.showblip then return end
    
    local blip = BlipAddForCoords(1664425300, store.Pos.x, store.Pos.y, store.Pos.z)
    SetBlipSprite(blip, store.blipsprite or 1475879922, false)
    BlipAddModifier(blip, joaat("BLIP_MODIFIER_MP_COLOR_32"))
    SetBlipName(blip, store.Name or "Store")
    storeBlips[k] = blip
end

-- Spawn NPC for store
local function SpawnNPC(k, store)
    if not Config.SpawnNPCs then return end
    
    local modelHash = GetHashKey(GetRandomNPCModel())
    
    if not IsModelValid(modelHash) then
        print("Invalid NPC model for store: " .. (store.Name or k))
        return
    end
    
    RequestModel(modelHash, false)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(modelHash) then
        print("Failed to load NPC model for store: " .. (store.Name or k))
        return
    end
    
    local ped = CreatePed(modelHash, store.Pos.x, store.Pos.y, store.Pos.z - 1.0, Config.NPCHeading or 0.0, false, false, false, false)
    
    timeout = 0
    while not DoesEntityExist(ped) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if DoesEntityExist(ped) then
        Citizen.InvokeNative(0x283978A15512B2FE, ped, true) -- SetRandomOutfitVariation
        SetEntityCanBeDamaged(ped, false)
        SetEntityInvincible(ped, true)
        FreezeEntityPosition(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        storeNPCs[k] = ped
    end
end

-- Check if player can access store (job check)
local function CheckJobs(store)
    if not store.joblock or not next(store.joblock) then
        return true
    end
    
    local job = LocalPlayer.state.Character.Job
    
    for _, allowedJob in ipairs(store.joblock) do
        if allowedJob == job then
            return true
        end
    end
    
    return false
end

-- Store interaction logic
local function storeOpen(k, store)
    local distance = GetPlayerDistanceFromCoords(vector3(store.Pos.x, store.Pos.y, store.Pos.z))
    
    -- Handle blip
    if store.showblip then
        if not storeBlips[k] then
            AddBlip(k, store)
        end
    end
    
    -- Handle NPC spawning/despawning based on distance
    if Config.SpawnNPCs then
        local npcDistance = 20.0 -- distance to spawn/despawn NPC
        
        if distance < npcDistance then
            if not storeNPCs[k] then
                SpawnNPC(k, store)
            end
        else
            if storeNPCs[k] then
                if DoesEntityExist(storeNPCs[k]) then
                    DeleteEntity(storeNPCs[k])
                end
                storeNPCs[k] = nil
            end
        end
    end
    
    -- Handle prompt and interaction
    local inDistance = (distance <= (Config.interactiondistance or 2.0))
    
    if inDistance then
        -- Check job permissions
        if not CheckJobs(store) then
            return false
        end
        
        -- Show prompt and check for interaction
        if showPrompt(store.Name or "Store", "open") == "open" then
            OpenStore(k, store)
        end
        
        return true
    end
    
    return false
end

-- Open store inventory
function OpenStore(id, store)
    if inStore then 
        print("[DEBUG] Store already open")
        return 
    end
    
    print("[DEBUG] Opening store:", id, store.Name)
    inStore = true
    currentStoreId = id
    currentStore = store
    
    -- Request store data for pricing overlay
    Core.Callback.TriggerAsync("ouro_stores:GetStoreData", function(storeData)
        if storeData then
            -- Send pricing data to overlay
            SendNUIMessage({
                action = 'showPricing',
                storeData = {
                    buyItems = storeData.buyItems,
                    sellItems = storeData.sellItems
                }
            })
        end
    end, id)
    
    -- Request server to open the container inventory
    TriggerServerEvent("ouro_stores:server:OpenStore", id)
end

-- These menu functions have been replaced by the vorp_inventory container system
-- All buying/selling is now handled via drag-and-drop in the inventory UI

-- Close store
function CloseStore()
    inStore = false
    currentStoreId = nil
    currentStore = nil
    
    -- Hide pricing overlay
    SendNUIMessage({
        action = 'hidePricing'
    })
    
    -- Small delay to prevent reopening
    Wait(500)
end

-- Listen for inventory close
RegisterNetEvent('vorp_inventory:CloseInv', function()
    if inStore then
        CloseStore()
    end
end)

-- Main thread
Citizen.CreateThread(function()
    repeat Wait(2000) until LocalPlayer.state.IsInSession
    
    setUpPrompt()
    
    while true do
        local sleep = 1000
        local player = PlayerPedId()
        local dead = IsEntityDead(player)
        
        -- Check for backspace to close store menu
        if isInMenu and IsControlJustPressed(0, 0x156F7119) then -- BACKSPACE
            CloseStore()
        end
        
        if dead or inStore then
            goto skip
        end
        
        -- Check each NPC store
        for k, store in pairs(Config.npcstores) do
            if storeOpen(k, store) then
                sleep = 0 -- Player is near a store, check more frequently
            end
        end
        
        ::skip::
        Wait(sleep)
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Delete all NPCs
    for k, ped in pairs(storeNPCs) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    
    -- Remove all blips
    for k, blip in pairs(storeBlips) do
        RemoveBlip(blip)
    end
    
    -- Delete prompt
    if OpenStores ~= 0 then
        UiPromptDelete(OpenStores)
    end
end)
