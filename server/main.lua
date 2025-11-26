local VORPcore = exports.vorp_core:GetCore()
local VORPInv = exports.vorp_inventory:vorp_inventoryApi()

-- Ouro_Society Config is stored before we overwrite Config table
-- Access it via the global SocietyConfig variable

-- Store data cache
local societyStores = {}
local clanStores = {}
local playerStores = {}

-- Load stores from database on resource start
CreateThread(function()
    Wait(2000)
    LoadStoresFromDB()
    RegisterUsableItems()
    RegisterStoreInventories()
end)

-- Register VORP Core callback for getting store data
VORPcore.Callback.Register("ouro_stores:GetStoreData", function(source, cb, storeId)
    print("[DEBUG] GetStoreData called for store:", storeId)
    
    local User = VORPcore.getUser(source)
    if not User then 
        print("[DEBUG] User not found")
        cb(nil)
        return 
    end
    
    local Character = User.getUsedCharacter
    local store = Config.npcstores[storeId]
    
    if not store then
        print("[DEBUG] Store not found in config:", storeId)
        cb(nil)
        return
    end
    
    print("[DEBUG] Store found:", store.Name)
    
    -- Get items player can BUY (from store's sellitems)
    local buyItems = {}
    if store.sellitems then
        for _, item in ipairs(store.sellitems) do
            table.insert(buyItems, {
                name = item.name,
                label = item.label,
                price = tonumber(item.price),
                type = item.type
            })
        end
    end
    
    -- Get items player can SELL (from their inventory that match store's buyitems)
    -- This requires using the async getUserInventoryItems
    exports.vorp_inventory:getUserInventoryItems(source, function(userInventory)
        local sellItems = {}
        
        if userInventory and store.buyitems then
            -- Create lookup table for buyable items
            local buyableItems = {}
            for _, item in ipairs(store.buyitems) do
                buyableItems[item.name] = {
                    name = item.name,
                    label = item.label,
                    price = tonumber(item.price)
                }
            end
            
            -- Check player inventory for sellable items
            for _, playerItem in pairs(userInventory) do
                if playerItem.count and playerItem.count > 0 and buyableItems[playerItem.name] then
                    table.insert(sellItems, {
                        name = playerItem.name,
                        label = playerItem.label,
                        count = playerItem.count,
                        price = buyableItems[playerItem.name].price
                    })
                end
            end
        end
        
        local result = {
            buyItems = buyItems,
            sellItems = sellItems,
            playerMoney = Character.money
        }
        
        print("[DEBUG] Sending store data - Buy items:", #buyItems, "Sell items:", #sellItems, "Money:", Character.money)
        cb(result)
    end)
end)


-- Register store inventories with VORP
function RegisterStoreInventories()
    for k, store in pairs(Config.npcstores) do
        local containerId = "store_" .. k
        
        -- Register the container
        exports.vorp_inventory:registerInventory({
            id = containerId,
            name = store.Name or "Store",
            limit = Config.StoreInventoryLimit or 50,
            acceptWeapons = false,
            shared = true,
            ignoreItemStackLimit = true,
            whitelistItems = false,
            UsePermissions = false,
            UseBlackList = false,
        })
        
        print("[Ouro Stores] Registered container: " .. containerId .. " (" .. store.Name .. ")")
    end
end

-- Populate store container with items when player opens it
function PopulateStoreForPlayer(source, storeId)
    local store = Config.npcstores[storeId]
    if not store or not store.sellitems then return end
    
    local User = VORPcore.getUser(source)
    if not User then return end
    
    local Character = User.getUsedCharacter
    local containerId = "store_" .. storeId
    
    -- Calculate stock based on container limit and item count
    -- VORP counts total items, not slots, so we need to distribute the limit
    local containerLimit = Config.StoreInventoryLimit or 50
    local itemCount = #store.sellitems
    local stockPerItem = math.floor(containerLimit / itemCount)
    
    -- Use config override if available and reasonable
    if Config.StoreStockPerItem and (Config.StoreStockPerItem * itemCount) <= containerLimit then
        stockPerItem = Config.StoreStockPerItem
    end
    
    print("[DEBUG] Populating store: " .. itemCount .. " item types with " .. stockPerItem .. " each (total: " .. (stockPerItem * itemCount) .. "/" .. containerLimit .. ")")
    
    -- Add items using the player's character ID (VORP requirement)
    local items = {}
    for _, item in ipairs(store.sellitems) do
        table.insert(items, {
            name = item.name,
            amount = stockPerItem  -- Stack size per item
        })
    end
    
    -- Use VORP's API to add items
    exports.vorp_inventory:addItemsToCustomInventory(containerId, items, Character.charIdentifier, function(success)
        if success then
            print("[Ouro Stores] Populated " .. store.Name .. " with " .. stockPerItem .. " of each item")
        else
            print("[Ouro Stores] Failed to populate " .. store.Name .. " - may need to increase Config.StoreInventoryLimit")
        end
    end, Character.identifier)
end

-- Register usable items
function RegisterUsableItems()
    -- Player shop token
    VORPInv.RegisterUsableItem(Config.shopcreationitem, function(data)
        local _source = data.source
        TriggerClientEvent('ouro_stores:useToken', _source, 'player')
    end)
    
    -- Society shop token
    VORPInv.RegisterUsableItem(Config.societytoken, function(data)
        local _source = data.source
        TriggerClientEvent('ouro_stores:useToken', _source, 'society')
    end)
    
    -- Clan shop token
    VORPInv.RegisterUsableItem(Config.clantoken, function(data)
        local _source = data.source
        TriggerClientEvent('ouro_stores:useToken', _source, 'clan')
    end)
    
    print("[Ouro Stores] Registered usable items")
end

-- Load all stores from database
function LoadStoresFromDB()
    -- Load society stores
    MySQL.query('SELECT * FROM society_shops WHERE repo = 0', {}, function(result)
        if result then
            for k, v in pairs(result) do
                societyStores[v.id] = v
            end
            print("[Ouro Stores] Loaded " .. #result .. " society stores")
        end
    end)
    
    -- Load clan stores
    MySQL.query('SELECT * FROM clan_shops WHERE repo = 0', {}, function(result)
        if result then
            for k, v in pairs(result) do
                clanStores[v.id] = v
            end
            print("[Ouro Stores] Loaded " .. #result .. " clan stores")
        end
    end)
    
    -- Load player stores
    MySQL.query('SELECT * FROM player_shops WHERE repo = 0', {}, function(result)
        if result then
            for k, v in pairs(result) do
                playerStores[v.id] = v
            end
            print("[Ouro Stores] Loaded " .. #result .. " player stores")
        end
    end)
end

-- Send stores to client
RegisterServerEvent('ouro_stores:requestStores')
AddEventHandler('ouro_stores:requestStores', function()
    local _source = source
    TriggerClientEvent('ouro_stores:receiveStores', _source, societyStores, clanStores, playerStores)
end)

-- Create a new store
RegisterServerEvent('ouro_stores:createStore')
AddEventHandler('ouro_stores:createStore', function(tokenType, coords)
    local _source = source
    local User = VORPcore.getUser(_source)
    
    if not User then return end
    
    local Character = User.getUsedCharacter
    local identifier = Character.identifier
    local charid = Character.charIdentifier
    
    if tokenType == 'society' then
        CreateSocietyStore(_source, identifier, charid, coords)
    elseif tokenType == 'clan' then
        CreateClanStore(_source, identifier, charid, coords)
    elseif tokenType == 'player' then
        CreatePlayerStore(_source, identifier, charid, coords)
    end
end)

-- Create society store
function CreateSocietyStore(source, identifier, charid, coords)
    local User = VORPcore.getUser(source)
    if not User then return end
    
    local Character = User.getUsedCharacter
    local job = Character.job
    local jobGrade = Character.jobGrade
    
    -- Check if job exists in Ouro_Society config
    if not SocietyConfig.Jobs[job] then
        TriggerClientEvent('vorp:TipRight', source, "You don't have a valid job to create a society store", 5000)
        return
    end
    
    -- Check if player has boss rank or higher
    local bossRank = SocietyConfig.Jobs[job].BossRank or 0
    if jobGrade < bossRank then
        TriggerClientEvent('vorp:TipRight', source, language.onlyboss, 5000)
        return
    end
    
    -- Check max society shops
    local count = 0
    for k, v in pairs(societyStores) do
        if v.society == job then
            count = count + 1
        end
    end
    
    if count >= Config.maxsocietyshops then
        TriggerClientEvent('vorp:TipRight', source, language.cantownmoresociety .. Config.maxsocietyshops, 5000)
        return
    end
    
    -- Check if too close to another shop
    if not CheckShopSpacing(coords) then
        TriggerClientEvent('vorp:TipRight', source, language.tooclosetoshop, 5000)
        return
    end
    
    -- Create store in database
    local coordsJson = json.encode({x = coords.x, y = coords.y, z = coords.z})
    local storeName = (SocietyConfig.Jobs[job].Label or job) .. " Store"
    
    MySQL.insert('INSERT INTO society_shops (society, coords, name, rank, showblip, sellitems, buyitems, storage, repo) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', 
        {job, coordsJson, storeName, 0, 1, json.encode({}), json.encode({}), Config.initalstorage, 0}, 
        function(result)
            if result then
                -- Remove token from player
                VORPInv.subItem(source, Config.societytoken, 1)
                
                -- Reload stores
                LoadStoresFromDB()
                
                -- Notify all clients to refresh
                TriggerClientEvent('ouro_stores:refreshStores', -1)
                
                TriggerClientEvent('vorp:TipRight', source, language.storecreated, 5000)
                print("[Ouro Stores] Society store created for " .. job .. " at " .. coords.x .. ", " .. coords.y .. ", " .. coords.z)
            end
        end
    )
end

-- Create clan store
function CreateClanStore(source, identifier, charid, coords)
    local User = VORPcore.getUser(source)
    if not User then return end
    
    local Character = User.getUsedCharacter
    local charIdentifier = Character.charIdentifier
    
    -- Get player's active clan
    MySQL.query('SELECT * FROM ouro_player_clans WHERE charidentifier = ? AND is_active = 1', {charIdentifier}, function(result)
        if not result or #result == 0 then
            TriggerClientEvent('vorp:TipRight', source, "You're not in an active clan", 5000)
            return
        end
        
        local clanName = result[1].clan
        local clanGrade = result[1].grade
        
        -- Check if clan exists in config
        if not SocietyConfig.Clans[clanName] then
            TriggerClientEvent('vorp:TipRight', source, "Invalid clan", 5000)
            return
        end
        
        -- Check if player has officer rank or higher (BossRank)
        local bossRank = SocietyConfig.Clans[clanName].BossRank or 3
        if clanGrade < bossRank then
            TriggerClientEvent('vorp:TipRight', source, language.onlyclanofficer, 5000)
            return
        end
        
        -- Check max clan shops
        local count = 0
        for k, v in pairs(clanStores) do
            if v.clan == clanName then
                count = count + 1
            end
        end
        
        if count >= Config.maxclanshops then
            TriggerClientEvent('vorp:TipRight', source, language.cantownmoreclan .. Config.maxclanshops, 5000)
            return
        end
        
        -- Check if too close to another shop
        if not CheckShopSpacing(coords) then
            TriggerClientEvent('vorp:TipRight', source, language.tooclosetoshop, 5000)
            return
        end
        
        -- Create store in database
        local coordsJson = json.encode({x = coords.x, y = coords.y, z = coords.z})
        local storeName = (SocietyConfig.Clans[clanName].Label or clanName) .. " Store"
        
        MySQL.insert('INSERT INTO clan_shops (clan, coords, name, rank, showblip, sellitems, buyitems, storage, repo) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', 
            {clanName, coordsJson, storeName, 0, 1, json.encode({}), json.encode({}), Config.initalstorage, 0}, 
            function(insertResult)
                if insertResult then
                    VORPInv.subItem(source, Config.clantoken, 1)
                    LoadStoresFromDB()
                    TriggerClientEvent('ouro_stores:refreshStores', -1)
                    TriggerClientEvent('vorp:TipRight', source, language.storecreated, 5000)
                    print("[Ouro Stores] Clan store created for " .. clanName .. " at " .. coords.x .. ", " .. coords.y .. ", " .. coords.z)
                end
            end
        )
    end)
end

-- Create player store
function CreatePlayerStore(source, identifier, charid, coords)
    local User = VORPcore.getUser(source)
    if not User then return end
    
    local Character = User.getUsedCharacter
    local charIdentifier = Character.charIdentifier
    
    -- Check max player shops
    local count = 0
    for k, v in pairs(playerStores) do
        if v.charidentifier == charIdentifier then
            count = count + 1
        end
    end
    
    if count >= Config.maxshops then
        TriggerClientEvent('vorp:TipRight', source, language.cantownmore, 5000)
        return
    end
    
    -- Check if too close to another shop
    if not CheckShopSpacing(coords) then
        TriggerClientEvent('vorp:TipRight', source, language.tooclosetoshop, 5000)
        return
    end
    
    local coordsJson = json.encode({x = coords.x, y = coords.y, z = coords.z})
    
    MySQL.insert('INSERT INTO player_shops (charidentifier, coords, name, showblip, sellitems, buyitems, storage, repo, ledger) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', 
        {charIdentifier, coordsJson, "Player Store", 1, json.encode({}), json.encode({}), Config.initalstorage, 0, 0}, 
        function(result)
            if result then
                VORPInv.subItem(source, Config.shopcreationitem, 1)
                LoadStoresFromDB()
                TriggerClientEvent('ouro_stores:refreshStores', -1)
                TriggerClientEvent('vorp:TipRight', source, language.storecreated, 5000)
                print("[Ouro Stores] Player store created for " .. charIdentifier .. " at " .. coords.x .. ", " .. coords.y .. ", " .. coords.z)
            end
        end
    )
end

-- Check if shop is too close to other shops
function CheckShopSpacing(newCoords)
    local minDistance = Config.shopspacing
    
    -- Check NPC stores
    for k, v in pairs(Config.npcstores) do
        local distance = #(vector3(newCoords.x, newCoords.y, newCoords.z) - vector3(v.Pos.x, v.Pos.y, v.Pos.z))
        if distance < minDistance then
            return false
        end
    end
    
    -- Check society stores
    for k, v in pairs(societyStores) do
        if v.coords then
            local coords = json.decode(v.coords)
            local distance = #(vector3(newCoords.x, newCoords.y, newCoords.z) - vector3(coords.x, coords.y, coords.z))
            if distance < minDistance then
                return false
            end
        end
    end
    
    -- Check clan stores
    for k, v in pairs(clanStores) do
        if v.coords then
            local coords = json.decode(v.coords)
            local distance = #(vector3(newCoords.x, newCoords.y, newCoords.z) - vector3(coords.x, coords.y, coords.z))
            if distance < minDistance then
                return false
            end
        end
    end
    
    -- Check player stores
    for k, v in pairs(playerStores) do
        if v.coords then
            local coords = json.decode(v.coords)
            local distance = #(vector3(newCoords.x, newCoords.y, newCoords.z) - vector3(coords.x, coords.y, coords.z))
            if distance < minDistance then
                return false
            end
        end
    end
    
    return true
end

-- Handle store opening
RegisterServerEvent('ouro_stores:server:OpenStore')
AddEventHandler('ouro_stores:server:OpenStore', function(storeId)
    local _source = source
    local containerId = "store_" .. storeId
    
    print("[DEBUG] Opening store container for player:", _source, "Container:", containerId)
    
    -- Populate store with items first
    PopulateStoreForPlayer(_source, storeId)
    
    -- Wait a moment then open
    Wait(200)
    
    -- Open the inventory using VORP's system
    exports.vorp_inventory:openInventory(_source, containerId)
end)

-- Handle buying items from NPC store
RegisterServerEvent('ouro_stores:buyItem')
AddEventHandler('ouro_stores:buyItem', function(storeId, itemName, amount)
    local _source = source
    local User = VORPcore.getUser(_source)
    
    if not User then return end
    
    local Character = User.getUsedCharacter
    
    -- Get store config
    local store = Config.npcstores[storeId]
    if not store or not store.sellitems then return end
    
    -- Find item in store
    local storeItem = nil
    for _, item in ipairs(store.sellitems) do
        if item.name == itemName then
            storeItem = item
            break
        end
    end
    
    if not storeItem then
        VORPcore.NotifyRightTip(_source, "Item not found in store", 3000)
        return
    end
    
    -- Calculate total price
    local totalPrice = tonumber(storeItem.price) * amount
    
    -- Check if player has enough money
    if Character.money < totalPrice then
        VORPcore.NotifyRightTip(_source, "You don't have enough money", 3000)
        return
    end
    
    -- Check if player can carry item
    local canCarry = VORPInv.canCarryItem(_source, itemName, amount)
    if not canCarry then
        VORPcore.NotifyRightTip(_source, "You don't have enough space", 3000)
        return
    end
    
    -- Process transaction
    Character.removeCurrency(0, totalPrice)
    VORPInv.addItem(_source, itemName, amount)
    
    -- Update UI
    TriggerClientEvent('ouro_stores:updateMoney', _source, Character.money)
    TriggerClientEvent('ouro_stores:refreshStore', _source)
    
    VORPcore.NotifyRightTip(_source, "Purchased " .. amount .. "x " .. storeItem.label .. " for $" .. string.format("%.2f", totalPrice), 5000)
    print("[Ouro Stores] " .. Character.firstname .. " " .. Character.lastname .. " bought " .. amount .. "x " .. itemName .. " for $" .. totalPrice)
end)

-- Handle selling items to NPC store
RegisterServerEvent('ouro_stores:sellItem')
AddEventHandler('ouro_stores:sellItem', function(storeId, itemName, amount)
    local _source = source
    local User = VORPcore.getUser(_source)
    
    if not User then return end
    
    local Character = User.getUsedCharacter
    
    -- Get store config
    local store = Config.npcstores[storeId]
    if not store or not store.buyitems then return end
    
    -- Find item in store
    local storeItem = nil
    for _, item in ipairs(store.buyitems) do
        if item.name == itemName then
            storeItem = item
            break
        end
    end
    
    if not storeItem then
        VORPcore.NotifyRightTip(_source, "Store doesn't buy this item", 3000)
        return
    end
    
    -- Check if player has item
    local playerItem = VORPInv.getItem(_source, itemName)
    if not playerItem or playerItem.count < amount then
        VORPcore.NotifyRightTip(_source, "You don't have enough items", 3000)
        return
    end
    
    -- Calculate total price
    local totalPrice = tonumber(storeItem.price) * amount
    
    -- Process transaction
    VORPInv.subItem(_source, itemName, amount)
    Character.addCurrency(0, totalPrice)
    
    -- Update UI
    TriggerClientEvent('ouro_stores:updateMoney', _source, Character.money)
    TriggerClientEvent('ouro_stores:refreshStore', _source)
    
    VORPcore.NotifyRightTip(_source, "Sold " .. amount .. "x " .. storeItem.label .. " for $" .. string.format("%.2f", totalPrice), 5000)
    print("[Ouro Stores] " .. Character.firstname .. " " .. Character.lastname .. " sold " .. amount .. "x " .. itemName .. " for $" .. totalPrice)
end)


-- Handle player taking item FROM store container (buying)
RegisterServerEvent('ouro_container:TakeFromContainer')
AddEventHandler('ouro_container:TakeFromContainer', function(obj)
    local _source = source
    local data = json.decode(obj)
    local containerId = data.Containerid
    
    -- Check if this is a store container
    if not string.match(containerId, "^store_") then return end
    
    local storeIndex = tonumber(string.match(containerId, "store_(%d+)"))
    if not storeIndex or not Config.npcstores[storeIndex] then return end
    
    local store = Config.npcstores[storeIndex]
    local User = VORPcore.getUser(_source)
    if not User then return end
    
    local Character = User.getUsedCharacter
    local itemName = data.item
    local amount = tonumber(data.number) or 1
    
    print("[DEBUG] Player taking from store:", itemName, "x" .. amount)
    
    -- Find item price in store's sellitems
    local itemPrice = nil
    for _, item in ipairs(store.sellitems) do
        if item.name == itemName then
            itemPrice = tonumber(item.price)
            break
        end
    end
    
    if not itemPrice then
        VORPcore.NotifyRightTip(_source, "This item is not for sale", 3000)
        return
    end
    
    -- Calculate total cost
    local totalCost = itemPrice * amount
    
    print("[DEBUG] Total cost:", totalCost, "Player money:", Character.money)
    
    -- Check if player has enough money
    if Character.money < totalCost then
        VORPcore.NotifyRightTip(_source, "You don't have enough money ($" .. string.format("%.2f", totalCost) .. ")", 3000)
        return
    end
    
    -- Remove money from player
    Character.removeCurrency(0, totalCost)
    
    -- Restock the store (add items back to maintain infinite stock)
    Wait(100)
    local User2 = VORPcore.getUser(_source)
    if User2 then
        local Character2 = User2.getUsedCharacter
        exports.vorp_inventory:addItemsToCustomInventory(containerId, {{name = itemName, amount = amount}}, Character2.charIdentifier, nil, Character2.identifier)
    end
    
    VORPcore.NotifyRightTip(_source, "Purchased " .. amount .. "x " .. itemName .. " for $" .. string.format("%.2f", totalCost), 3000)
    print("[Ouro Stores] " .. Character.firstname .. " " .. Character.lastname .. " bought " .. amount .. "x " .. itemName .. " for $" .. totalCost)
end)

-- Handle player moving item TO store container (selling)
RegisterServerEvent('ouro_container:MoveToContainer')
AddEventHandler('ouro_container:MoveToContainer', function(obj)
    local _source = source
    local data = json.decode(obj)
    local containerId = data.Containerid
    
    -- Check if this is a store container
    if not string.match(containerId, "^store_") then return end
    
    local storeIndex = tonumber(string.match(containerId, "store_(%d+)"))
    if not storeIndex or not Config.npcstores[storeIndex] then return end
    
    local store = Config.npcstores[storeIndex]
    local User = VORPcore.getUser(_source)
    if not User then return end
    
    local Character = User.getUsedCharacter
    local itemName = data.item
    local amount = tonumber(data.number) or 1
    
    print("[DEBUG] Player moving to store:", itemName, "x" .. amount)
    
    -- Find item price in store's buyitems
    local itemPrice = nil
    for _, item in ipairs(store.buyitems) do
        if item.name == itemName then
            itemPrice = tonumber(item.price)
            break
        end
    end
    
    if not itemPrice then
        VORPcore.NotifyRightTip(_source, "Store doesn't buy this item", 3000)
        -- Item was moved to container, give it back to player
        Wait(100)
        VORPInv.addItem(_source, itemName, amount)
        return
    end
    
    -- Calculate total payment
    local totalPayment = itemPrice * amount
    
    print("[DEBUG] Paying player:", totalPayment)
    
    -- Give money to player
    Character.addCurrency(0, totalPayment)
    
    -- Container will automatically have the item, we just don't restock it
    
    VORPcore.NotifyRightTip(_source, "Sold " .. amount .. "x " .. itemName .. " for $" .. string.format("%.2f", totalPayment), 3000)
    print("[Ouro Stores] " .. Character.firstname .. " " .. Character.lastname .. " sold " .. amount .. "x " .. itemName .. " for $" .. totalPayment)
end)

-- Export store data for other resources
exports('GetSocietyStores', function()
    return societyStores
end)

exports('GetClanStores', function()
    return clanStores
end)

exports('GetPlayerStores', function()
    return playerStores
end)

-- Admin commands
RegisterCommand(Config.moveshopcommand, function(source, args, rawCommand)
    -- TODO: Implement admin move shop
end)

RegisterCommand(Config.unreposhopcommand, function(source, args, rawCommand)
    -- TODO: Implement admin unrepo shop
end)

RegisterCommand(Config.adminrepocommand, function(source, args, rawCommand)
    -- TODO: Implement admin repo shop
end)

RegisterCommand(Config.admindeleteshopcommand, function(source, args, rawCommand)
    -- TODO: Implement admin delete shop
end)

