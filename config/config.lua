-- Store Ouro_Society Config (loaded first via shared_scripts)
local SocietyConfig = Config or {}

-- Now create our own Config table for Ouro_stores
Config = {}
language = {}

Config.keys = {
    ["F"] = 0xB2F377E8,
    ["B"] = 0x4CC0E2FE,
    ["G"] = 0x760A9C6F,
    ["ENTER"] = 0xC7B5340A,
    ["DOWN"] = 0x05CA7C52,
    ["SHIFT"] = 0x8FFC75D6,
    ["UP"] = 0x6319DB71,
    ["LEFT"] = 0xA65EBAB4,
    ["RIGHT"] = 0xDEB34313,
    ["RIGHTBRACKET"] = 0xA5BDCD3C,
    ["LEFTBRACKET"] = 0x430593AA,
    ["BACKSPACE"] = 0x156F7119,
    ["ALT"] = 0x8AAA0AD4,
    ["CTRL"] = 0xDB096B85,
    ["1"] = 0xE6F612E4,
    ["2"] = 0x1CE6D9EB,
    ["3"] = 0x4F49CC4C,
    ["4"] = 0x8F9F9E58,
    ["I"] = 0xC1989F95,
    ["X"] = 0x8CC9CD42,
}

Config.debug = true -- set to false on live server
Config.priceinfo = "<span style=color:Green;> "
Config.StoreInventoryLimit = 200 -- max ITEM COUNT in store inventory (not slots - VORP counts total items)
Config.StoreStockPerItem = 100 -- amount of each item to stock (will auto-adjust if total exceeds limit)

-- Decay Configs
Config.useDecayitems = false -- set to false if you dont want items to decay
Config.maxDecay = 0 -- max decay value you want items to be sold to the shop

-- Item Blacklist
Config.blacklisteditems = { 
    "identitycard",
    "passport",
    "bountylicns",
    "orden_presidente",
    "medcert",
}

-- ==============================================
-- NPC STORES (Config found in npc_stores.lua)
-- ==============================================
Config.npcstores = {} -- defined in npc_stores.lua

-- ==============================================
-- SOCIETY STORES
-- ==============================================
Config.societystores = true -- enable society stores
Config.societystoreblip = 249721687 -- blip sprite for society shops
Config.maxsocietyshops = 1 -- max shops owned by 1 society
Config.societytoken = "societytoken" -- item used to create society shop (can only be used by boss of society)

-- ==============================================
-- CLAN STORES
-- ==============================================
Config.clanstores = true -- enable clan stores
Config.clanstoreblip = 249721687 -- blip sprite for clan shops
Config.maxclanshops = 1 -- max shops owned by 1 clan
Config.clantoken = "clantoken" -- item used to create clan shop (can only be used by clan officer+)

-- ==============================================
-- PLAYER STORES
-- ==============================================
Config.playerstores = true -- enable player stores
Config.playershopsprite = -242384756 -- blip sprite for player owned shops
Config.maxshops = 1 -- max shops owned by 1 player
Config.adminbypassmax = true -- admins can bypass the max shops count
Config.shopcreationitem = "shoptoken" -- item that is used to create a shop
Config.playerstoretax = 50 -- how much is the tax for player owned stores

-- ==============================================
-- GENERAL STORE SETTINGS
-- ==============================================
Config.interactiondistance = 1.5 -- distance which shop interaction prompt is shown
Config.initalstorage = 100 -- newly created stores will have this much capacity
Config.upgradecost = 1 -- price per slot
Config.shopspacing = 5 -- shops cant be too close to each other
Config.moveshopcost = 100 -- how much it costs to move a shop
Config.relocatecommand = "moveshop" -- command to move a shop by player

-- ==============================================
-- REPO SETTINGS
-- ==============================================
Config.monthlyrepo = true
Config.repotime = { 
    day = 15,
    hour = 11,
    minute = 05
}
Config.weeklyrepo = false
Config.repotime2 = {
    day1 = 3,
    day2 = 10,
    day3 = 17,
    day4 = 24,
    hour = 6,
    minute = 10
}

-- ==============================================
-- ADMIN COMMANDS
-- ==============================================
Config.moveshopcommand = "adminmoveshop" -- move shop to a new location admin command /moveshop shopid x y z
Config.unreposhopcommand = "unreposhop" -- admin command to unrepo a shop
Config.adminrepocommand = "reposhop" -- sets the shop as repo this doesnt delete the shop just simply hides it from the players
Config.admindeleteshopcommand = "delshop" -- admin command to delete shops example /delshop shopid

