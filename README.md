# Me
Hello! If you’re enjoying the script and feel like supporting the work that went into it, consider buying me a coffee ☕
https://buymeacoffee.com/core_scripts

# Core GPS Advanced

An advanced FiveM GPS Marker script for QB-Core framework featuring **device-based storage** where each GPS device has its own unique ID and saved locations.

## Some Screenshots


![GPSA1](https://i.postimg.cc/Jh394g5K/GPSA1.png)

![GPSA1](https://i.postimg.cc/brsK99Kv/GPSA4.png)

![GPSA2](https://i.postimg.cc/rpGvFbNZ/GPSA2.png)

![GPSA3](https://i.postimg.cc/vmwJyMf9/GPSA3.png)

## 🌟 Key Features

### Device-Based System
- **Unique GPS IDs** - Each GPS device has a unique identifier in the format: `GPS-PLAYERNAME-XXXXXXXX`
  - Example: `GPS-JOHN_DOE-A3K9X2M7`
  - Player name is automatically included for easy identification
  - 8 random alphanumeric characters ensure uniqueness
- **Data Saved to Device** - Markers are saved to the GPS device itself, not the player
- **Multiple GPS Devices** - Players can own multiple GPS devices with different markers on each
- **Device Trading** - GPS devices can be traded between players (with their saved locations)

### Location Management
- 📍 **Mark Current Location** - Save your current position with custom labels
- 🗺️ **Visual Map Markers** - See all markers saved on your GPS device on the map
- 🔄 **Toggle Markers** - Show/hide all markers with one click
- 🚩 **Set Waypoints** - Quickly navigate to saved locations
- 🗑️ **Remove Markers** - Delete markers with confirmation dialog
- 💾 **Persistent Storage** - All data saved to database via oxmysql

### Sharing System
- 📤 **Share Locations** - Share specific markers with other players
- ✅ **Accept/Decline System** - Receivers get a popup to accept or decline shared locations
- 📋 **Location Preview** - See location details before accepting
- 🎯 **Smart Validation** - Requires GPS device to accept shared locations

### Item-Based Display
- 🎒 **GPS Required** - Markers only display when GPS device is in inventory
- 🔄 **Auto Detection** - Automatically detects when GPS is added/removed
- 📱 **Device Switching** - Switching GPS devices loads that device's markers
- ⚡ **Event-Driven** - No polling, uses proper inventory events

### User Interface
- 🎨 **Modern UI** - Clean, radio-style interface
- 📊 **Marker Counter** - Shows how many locations are saved
- 🎯 **GPS ID Display** - Shows current device ID
- 🌙 **Dark Theme** - Easy on the eyes
- ⌨️ **Keyboard Shortcuts** - ESC to close, Enter to submit

## 📋 Requirements

- [QBCore Framework](https://github.com/qbcore-framework/qb-core)
- [oxmysql](https://github.com/overextended/oxmysql)

## 🔧 Installation

### 1. Database Setup

Run the SQL file located in `install/core_gps_advanced.sql`:

```sql
CREATE TABLE IF NOT EXISTS `core_gps_advanced` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `gps_id` varchar(100) NOT NULL,
    `label` varchar(100) NOT NULL,
    `coords` longtext NOT NULL,
    `street` varchar(255) DEFAULT NULL,
    `timestamp` bigint(20) DEFAULT NULL,
    `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`id`),
    KEY `gps_id` (`gps_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `core_gps_advanced_devices` (
    `gps_id` varchar(100) NOT NULL,
    `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`gps_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 2. Add the Resource

1. Copy the `core_gps_advanced` folder to your server's `resources` directory
2. Ensure `oxmysql` is installed and running
3. Add to your `server.cfg`:
```cfg
ensure oxmysql
ensure core_gps_advanced
```

### 3. Add the Item

Add this item to your `qb-core/shared/items.lua`:

```lua
core_gps_a = {
    name = 'core_gps_a',
    label = 'GPS Advanced',
    weight = 200,
    type = 'item',
    image = 'core_gps_advanced.png',
    unique = true,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'A GPS device for marking and managing locations'
}
```

**Important:** The item MUST be set as `unique = true` to support metadata (GPS ID storage).


## 🔄 Automatic Update Checker

The script includes an automatic version checker that runs when the server starts. It will:
- Check for new versions on GitHub
- Display the latest version information in the console
- Show changelog entries for new updates
- List specific files that need to be updated
- Provide a download link to the latest release

**Enjoy your advanced GPS system!** 📍🗺️

## Credits

- **Framework**: QB-Core
- **Developer**: ChrisNewmanDev