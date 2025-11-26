-- NPC Creator Configuration
-- This file allows you to spawn NPCs at your store locations

Config.SpawnNPCs = true -- set to false if you don't want NPCs to spawn at stores

Config.NPCModels = {
    "CS_SDStoreOwner_01",
    "CS_VALGeneralStoreOwner",
    "CS_RHOGeneralStoreOwner",
    "CS_BLKGeneralStoreOwner",
    "CS_StoreOwner_01",
}

-- Function to get a random NPC model
function GetRandomNPCModel()
    return Config.NPCModels[math.random(#Config.NPCModels)]
end

-- NPC spawn configuration for each store type
Config.NPCHeading = 0.0 -- default heading for NPCs
Config.NPCScenario = "WORLD_HUMAN_SMOKE_INTERACTION" -- default scenario for NPCs

