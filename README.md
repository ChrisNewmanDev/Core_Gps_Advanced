# Core GPS Advanced

An advanced FiveM GPS Marker script for QB-Core framework featuring **device-based storage** where each GPS device has its own unique ID and saved locations.

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

Run the SQL file located in `install/core_gps.sql`:

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

1. Copy the `Core_Gps_Advanced` folder to your server's `resources` directory
2. Ensure `oxmysql` is installed and running
3. Add to your `server.cfg`:
```cfg
ensure oxmysql
ensure Core_Gps_Advanced
```

### 3. Add the Item

Add this item to your `qb-core/shared/items.lua`:

```lua
core_gps_a = {
    name = 'core_gps_a',
    label = 'GPS',
    weight = 200,
    type = 'item',
    image = 'core_gps.png',
    unique = true,           -- MUST BE TRUE for metadata support
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'A GPS device for marking and managing locations'
}
```

**Important:** The item MUST be set as `unique = true` to support metadata (GPS ID storage).

### 4. Configure Settings

Edit `config.lua` to customize:

```lua
Config = {}

Config.ItemName = 'core_gps_a'  -- Item name (must match items.lua)
Config.MaxMarkers = 50        -- Maximum markers per GPS device

-- Blip settings
Config.BlipSettings = {
    sprite = 1,               -- Blip icon
    color = 3,                -- Blip color
    scale = 0.8,              -- Blip size
    display = 4,              -- Display type
    shortRange = true         -- Only show when nearby
}
```

## 📖 Usage

### Getting a GPS Device

**Method 1: Admin Command (Testing)**
```
/givegpsa
```
- Admin only command
- Generates a new GPS with unique ID
- Automatically includes your character name

**Method 2: Shop Integration**

Add to your shop script (server-side):
```lua
-- Example for shop purchase
local playerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
local gpsId = GenerateGPSId(playerName)

MySQL.insert.await('INSERT INTO core_gps_advanced_devices (gps_id) VALUES (?)', {gpsId})
Player.Functions.AddItem('core_gps_a', 1, false, {gps_id = gpsId})
```

**Method 3: Server Event**
```lua
TriggerServerEvent('core_gps:server:registerDevice')
```

### Using Your GPS

1. **Open GPS Device**
   - Use the GPS item from your inventory
   - Opens the GPS interface

2. **Mark a Location**
   - Enter a custom name/label
   - Click "Mark Current Location"
   - Location is saved to your GPS device

3. **View Saved Locations**
   - All markers appear in the list
   - Shows label, street name, and timestamp
   - Click waypoint icon to navigate
   - Click share icon to send to another player
   - Click delete icon to remove

4. **Share Locations**
   - Click share button on any marker
   - Enter the target player's server ID
   - They receive a popup to accept/decline
   - If accepted, location saves to their GPS

5. **Toggle Marker Visibility**
   - Use the checkbox to show/hide map markers
   - Markers only display when GPS is in inventory

### GPS ID Format

GPS IDs follow this format: `GPS-FIRSTNAME_LASTNAME-XXXXXXXX`

**Examples:**
- Peter File → `GPS-PETER_FILE-A3K9X2M7`
- John Doe → `GPS-JOHN_DOE-B5N7Q1P4`
- Sarah O'Connor → `GPS-SARAH_O'CONNOR-W9X8Y7Z6`

**Benefits:**
- Instantly identify who created/owns the GPS
- Perfect for trading and player-to-player sales
- Easy for admins to track devices
- Great for roleplay servers

## 🎮 Gameplay Features

### Multiple GPS Devices
Players can have multiple GPS devices, each with different saved locations:
- **Work GPS** - Job-related locations
- **Personal GPS** - Home, favorite spots
- **Trade GPS** - Sell GPS devices with specific routes pre-saved

### Trading & Economy
- GPS devices are tradeable items
- Sell pre-configured GPS devices (e.g., "Weed Farm Route GPS")
- Trade GPS devices with other players
- Each GPS retains its saved markers when traded

### Automatic Inventory Detection
- Add GPS to inventory → Markers appear
- Remove GPS from inventory → Markers disappear
- Switch GPS devices → Different markers load automatically
- No manual refresh needed

## 🔐 Security

- **Admin-Only Commands** - `/givegps` restricted to admins
- **GPS Validation** - Must have GPS device to save/view markers
- **Database Checks** - Unique ID collision prevention
- **Player Validation** - All server events validate player data

## 🛠️ Advanced Configuration

### Custom GPS ID Generation

The GPS ID generation can be customized in `server/sv_gps.lua`:

```lua
function GenerateGPSId(playerName)
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local formattedName = playerName:upper():gsub(" ", "_")
    local randomCode = ""
    
    for i = 1, 8 do
        local rand = math.random(1, #charset)
        randomCode = randomCode .. string.sub(charset, rand, rand)
    end
    
    local id = "GPS-" .. formattedName .. "-" .. randomCode
    return id
end
```

### Shop Integration Example

```lua
-- qb-shops or custom shop
RegisterNetEvent('yourshop:server:purchaseGPS', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    if Player.Functions.RemoveMoney('cash', 500) then
        local playerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
        local gpsId = GenerateGPSId(playerName)
        
        MySQL.insert.await('INSERT INTO core_gps_advanced_devices (gps_id) VALUES (?)', {gpsId})
        Player.Functions.AddItem('core_gps_a', 1, false, {gps_id = gpsId})
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['core_gps_a'], "add")
        TriggerClientEvent('QBCore:Notify', src, 'GPS Device purchased! ID: ' .. gpsId, 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Not enough money!', 'error')
    end
end)
```

## 📁 File Structure

```
Core_Gps_Advanced/
├── client/
│   └── cl_gps.lua          # Client-side logic
├── server/
│   └── sv_gps.lua          # Server-side logic, GPS ID generation
├── html/
│   ├── index.html          # UI structure
│   ├── script.js           # UI logic
│   └── style.css           # UI styling
├── install/
│   ├── core_gps.sql        # Database setup
│   └── item.lua            # Item configuration
├── config.lua              # Configuration file
├── fxmanifest.lua          # Resource manifest
└── README.md               # This file
```

## 🎯 Events Reference

### Client Events

```lua
-- Trigger when player uses GPS item
TriggerEvent('core_gps:client:useItem', itemData)

-- Receive shared location
TriggerEvent('core_gps:client:receiveSharedMarker', markerData, senderName)

-- Update markers display
TriggerEvent('core_gps:client:updateMarkers', markers)

-- Share result notification
TriggerEvent('core_gps:client:shareResult', success, message)
```

### Server Events

```lua
-- Register new GPS device
TriggerServerEvent('core_gps:server:registerDevice')

-- Load markers for GPS device
TriggerServerEvent('core_gps:server:loadMarkers', gpsId)

-- Add marker to GPS
TriggerServerEvent('core_gps:server:addMarker', gpsId, markerData)

-- Remove marker from GPS
TriggerServerEvent('core_gps:server:removeMarker', gpsId, index)

-- Share marker with player
TriggerServerEvent('core_gps:server:shareMarker', gpsId, targetId, markerIndex)
```

### NUI Callbacks

```lua
-- Close GPS UI
RegisterNUICallback('closeUI', function(data, cb) end)

-- Mark current location
RegisterNUICallback('markLocation', function(data, cb) end)

-- Remove marker
RegisterNUICallback('removeMarker', function(data, cb) end)

-- Share marker
RegisterNUICallback('shareMarker', function(data, cb) end)

-- Toggle marker visibility
RegisterNUICallback('toggleMarkers', function(data, cb) end)

-- Set waypoint
RegisterNUICallback('setWaypoint', function(data, cb) end)

-- Accept shared location
RegisterNUICallback('acceptSharedLocation', function(data, cb) end)

-- Decline shared location
RegisterNUICallback('declineSharedLocation', function(data, cb) end)
```

## 🐛 Troubleshooting

**Markers not appearing on map:**
- Ensure you have the GPS item in your inventory
- Check if "Show Markers on Map" is enabled in GPS UI
- Verify the GPS device has saved markers

**GPS item has no ID:**
- Item must be set as `unique = true` in items.lua
- Use `/givegpsa` command or proper registration events
- Don't manually add GPS without metadata

**Shared locations not working:**
- Receiver must have a GPS device in inventory
- Check target player ID is correct
- Ensure both players are online

**Database errors:**
- Verify oxmysql is running
- Check SQL tables were created correctly
- Ensure gps_id fields are varchar(100)

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Check existing issues for solutions
- Review the documentation above

## 🎉 Credits

Developed for QB-Core Framework
- Modern UI design
- Device-based storage system
- Advanced sharing with accept/decline
- Event-driven inventory detection

---

**Enjoy your advanced GPS system!** 📍🗺️
