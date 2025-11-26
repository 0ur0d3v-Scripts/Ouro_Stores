-- Society Stores Table
CREATE TABLE IF NOT EXISTS `society_shops` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `society` varchar(50) NOT NULL DEFAULT '0',
  `coords` longtext DEFAULT '{}',
  `name` varchar(50) DEFAULT "",
  `rank` int(11) DEFAULT 0,
  `showblip` int(11) DEFAULT 1,
  `sellitems` longtext DEFAULT '{}',
  `buyitems` longtext DEFAULT '{}',
  `storage` int(11) DEFAULT 100,
  `webhook` varchar(255) DEFAULT '',
  `repo` int(11) DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Clan Stores Table
CREATE TABLE IF NOT EXISTS `clan_shops` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `clan` varchar(50) NOT NULL DEFAULT '0',
  `coords` longtext DEFAULT '{}',
  `name` varchar(50) DEFAULT "",
  `rank` int(11) DEFAULT 0,
  `showblip` int(11) DEFAULT 1,
  `sellitems` longtext DEFAULT '{}',
  `buyitems` longtext DEFAULT '{}',
  `storage` int(11) DEFAULT 100,
  `webhook` varchar(255) DEFAULT '',
  `repo` int(11) DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Player Stores Table
CREATE TABLE IF NOT EXISTS `player_shops` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `charidentifier` varchar(50) NOT NULL,
  `coords` longtext DEFAULT '{}',
  `name` varchar(50) DEFAULT "",
  `showblip` int(11) DEFAULT 1,
  `sellitems` longtext DEFAULT '{}',
  `buyitems` longtext DEFAULT '{}',
  `storage` int(11) DEFAULT 100,
  `webhook` varchar(255) DEFAULT '',
  `ledger` int(11) DEFAULT 0,
  `repo` int(11) DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Store Items (for creating shop tokens)
INSERT IGNORE INTO `items`(`item`, `label`, `limit`, `can_remove`, `type`, `usable`) VALUES 
('shoptoken', 'Player Shop Creation License', 5, 1, 'item_standard', 1),
('societytoken', 'Society Shop Creation License', 5, 1, 'item_standard', 1),
('clantoken', 'Clan Shop Creation License', 5, 1, 'item_standard', 1);

