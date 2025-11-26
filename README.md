# Ouro Stores

A comprehensive store system for RedM/VORP that supports multiple store types:

- NPC Stores (static government/business stores)
- Society Stores (managed by job societies from Ouro_Society)
- Clan Stores (managed by clans from Ouro_Society)
- Player Stores (owned by individual players)

## Features

- Multiple store types with different ownership models
- Dynamic store creation using tokens
- Configurable items, prices, and stock levels
- Store management system with permissions
- Blip system for each store type
- NPC spawning at store locations
- Webhook support for logging
- Store repossession system for unpaid taxes
- Admin commands for store management
- Full integration with Ouro_Society for jobs and clans
- Shop spacing enforcement to prevent overlapping stores

## Installation

### Step 1: Database Setup
Import the SQL file to create the required tables:
```sql
-- Import: sql/stores.sql
```

This will create three tables:
- `society_shops` - Stores owned by societies/jobs
- `clan_shops` - Stores owned by clans
- `player_shops` - Stores owned by players

It will also add three usable items:
- `shoptoken` - Player Shop Creation License
- `societytoken` - Society Shop Creation License
- `clantoken` - Clan Shop Creation License

### Step 2: Configure NPC Stores
Edit `config/npc_stores.lua` to add/modify static NPC stores. You can copy the configuration structure directly from `syn_stores/config/normalstores.lua` if you're migrating from syn_stores.

**Example NPC Store Config:**
```lua
{
    Pos = {x = 2924.84, y = 1371.46, z = 45.14},
    blipsprite = 1475879922,
    Name = 'General Store',
    joblock = {}, -- Empty for public, or {"sheriff", "doctor"} for job-locked
    showblip = true,
    sellitems = {
        { name = "water", label = "water", price = "0.15", type = "item_standard" },
        { name = "beefjerky", label = "Beef Jerky", price = "0.20", type = "item_standard" },
    },
    buyitems = {
        { name = "water", label = "water", price = "0.10", type = "item_standard" },
    },
}
```

### Step 3: Configure General Settings
Edit `config/config.lua` to adjust:
- Store spacing (how close stores can be to each other)
- Maximum stores per player/society/clan
- Store creation costs
- Tax and repo settings
- Webhook URLs

### Step 4: Add to Server
Add to your `server.cfg`:
```
ensure Ouro_stores
```

**Note:** Make sure Ouro_stores loads AFTER Ouro_Society since it depends on it.

## Configuration

### NPC Stores
Static stores that are always available. Configure in `config/npc_stores.lua`.

**Features:**
- Fixed locations
- Cannot be moved or deleted by players
- Configurable items to buy and sell
- Job locking support
- Optional blips

### Society Stores
Dynamic stores created by society bosses using tokens.

**Requirements:**
- Player must be a boss (BossRank or higher) in their society
- Player must have a `societytoken` item
- Society must not have reached max store limit (Config.maxsocietyshops)

**Features:**
- Money goes to society ledger (via Ouro_Society)
- Managed by society members with appropriate rank
- Store name automatically uses society label
- Full integration with Ouro_Society job system

### Clan Stores
Dynamic stores created by clan officers using tokens.

**Requirements:**
- Player must be in an active clan
- Player must be an officer (BossRank or higher) in their clan
- Player must have a `clantoken` item
- Clan must not have reached max store limit (Config.maxclanshops)

**Features:**
- Money goes to clan ledger (via Ouro_Society)
- Managed by clan members with appropriate rank
- Store name automatically uses clan label
- Full integration with Ouro_Society clan system

### Player Stores
Dynamic stores created by individual players using tokens.

**Requirements:**
- Player must have a `shoptoken` item
- Player must not have reached max store limit (Config.maxshops)

**Features:**
- Money goes to player's personal store ledger
- Can be upgraded and customized
- Subject to tax and repossession
- Personal ownership and management

## Creating Stores

To create a store, players need to:
1. Obtain the appropriate token (shoptoken, societytoken, or clantoken)
2. Use the token from their inventory
3. Stand at the desired location for the store
4. Confirm the creation

**Store Spacing:**
- New stores cannot be created within `Config.shopspacing` units of existing stores
- This applies to all store types (NPC, Society, Clan, Player)
- Default spacing is 5 units

## Society Integration

Ouro_stores integrates directly with Ouro_Society:

**Jobs/Societies:**
- Pulls job configuration from Ouro_Society's Config.Jobs
- Checks BossRank to determine if player can create society store
- Uses society label for store naming

**Clans:**
- Pulls clan configuration from Ouro_Society's Config.Clans
- Checks player's active clan from `ouro_player_clans` table
- Verifies player has officer rank (BossRank) or higher
- Uses clan label for store naming

## Admin Commands

- `/adminmoveshop [shopid] [x] [y] [z]` - Move a shop to new coordinates
- `/reposhop [shopid]` - Repossess a shop (hides it from players)
- `/unreposhop [shopid]` - Unrepo a shop
- `/delshop [shopid]` - Permanently delete a shop

## Migrating from syn_stores

If you're migrating from syn_stores:

1. **NPC Stores:** Copy your `Config.normalstores` from syn_stores to `Config.npcstores` in ouro_stores
2. **Society Stores:** Any existing society stores in syn_stores will need to be recreated in ouro_stores
3. **Player Stores:** Player stores should work similarly - players can create new ones with tokens

## Dependencies

- **vorp_core** - Core framework
- **vorp_inventory** - Inventory system
- **Ouro_Society** - Job and clan management (REQUIRED)

## Exports

### Server Exports

```lua
-- Get all society stores
local societyStores = exports.Ouro_stores:GetSocietyStores()

-- Get all clan stores
local clanStores = exports.Ouro_stores:GetClanStores()

-- Get all player stores
local playerStores = exports.Ouro_stores:GetPlayerStores()
```

## TODO / Future Features

- Store UI for buying/selling items
- Store inventory management
- Store upgrade system
- Tax collection and auto-repo
- Full admin menu for store management
- Store statistics and logs

## Credits

- Configuration structure inspired by syn_stores
- Developed for Ouro RedM Server
- Integrated with Ouro_Society system

