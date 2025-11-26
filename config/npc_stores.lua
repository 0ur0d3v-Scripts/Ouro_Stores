-- NPC stores are static stores that cannot be moved or modified by players
-- Items inside here and shop locations are up to you to manage and configure per your server needs

Config.npcstores = {
    -- General Store (Valentine)
    {
        Pos = {x = -322.43, y = 803.83, z = 117.88},
        blipsprite = 1475879922,
        Name = 'General Store',
        joblock = {},
        showblip = true,
        sellitems = {
            { name = "consumable_raspberrywater",   label = "Raspberry Water",          price = "8",    type = "item_standard" },
        },
        buyitems = {
            { name = "consumable_raspberrywater",   label = "Raspberry Water",          price = "4",    type = "item_standard" },
        },
    },
}

