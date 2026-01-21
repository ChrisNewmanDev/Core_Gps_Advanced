local QBCore = exports['qb-core']:GetCoreObject()

local gpsMarkers = {}

local CURRENT_VERSION = Config.Version
local RESOURCE_NAME = Config.ResourceName
local VERSION_CHECK_URL = 'https://raw.githubusercontent.com/' .. Config.GithubRepo .. '/main/version.json'

local function ParseVersion(version)
    local major, minor, patch = version:match('(%d+)%.(%d+)%.(%d+)')
    return {
        major = tonumber(major) or 0,
        minor = tonumber(minor) or 0,
        patch = tonumber(patch) or 0
    }
end

local function CompareVersions(current, latest)
    local currentVer = ParseVersion(current)
    local latestVer = ParseVersion(latest)
    
    if latestVer.major > currentVer.major then return 'outdated'
    elseif latestVer.major < currentVer.major then return 'ahead' end
    
    if latestVer.minor > currentVer.minor then return 'outdated'
    elseif latestVer.minor < currentVer.minor then return 'ahead' end
    
    if latestVer.patch > currentVer.patch then return 'outdated'
    elseif latestVer.patch < currentVer.patch then return 'ahead' end
    
    return 'current'
end

local function CheckVersion()
    PerformHttpRequest(VERSION_CHECK_URL, function(statusCode, response, headers)
        if statusCode ~= 200 then
            print('^3[' .. RESOURCE_NAME .. '] ^1Failed to check for updates (HTTP ' .. statusCode .. ')^7')
            print('^3[' .. RESOURCE_NAME .. '] ^3Please verify the version.json URL is correct^7')
            return
        end
        
        local success, versionData = pcall(function() return json.decode(response) end)
        
        if not success or not versionData or not versionData.version then
            print('^3[' .. RESOURCE_NAME .. '] ^1Failed to parse version data^7')
            return
        end
        
        local latestVersion = versionData.version
        local versionStatus = CompareVersions(CURRENT_VERSION, latestVersion)
        
        print('^3========================================^7')
        print('^5[' .. RESOURCE_NAME .. '] Version Checker^7')
        print('^3========================================^7')
        print('^2Current Version: ^7' .. CURRENT_VERSION)
        print('^2Latest Version:  ^7' .. latestVersion)
        print('')
        
        if versionStatus == 'current' then
            print('^2✓ You are running the latest version!^7')
        elseif versionStatus == 'ahead' then
            print('^3⚠ You are running a NEWER version than released!^7')
            print('^3This may be a development version.^7')
        elseif versionStatus == 'outdated' then
            print('^1⚠ UPDATE AVAILABLE!^7')
            print('')
            
            if versionData.changelog and versionData.changelog[latestVersion] then
                local changelog = versionData.changelog[latestVersion]
                
                if changelog.date then
                    print('^6Release Date: ^7' .. changelog.date)
                    print('')
                end
                
                if changelog.changes and #changelog.changes > 0 then
                    print('^5Changes:^7')
                    for _, change in ipairs(changelog.changes) do
                        print('  ^2✓^7 ' .. change)
                    end
                    print('')
                end
                
                if changelog.files_to_update and #changelog.files_to_update > 0 then
                    print('^1Files that need to be updated:^7')
                    for _, file in ipairs(changelog.files_to_update) do
                        print('  ^3➤^7 ' .. file)
                    end
                    print('')
                end
            end
            
            print('^2Download: ^7https://github.com/' .. Config.GithubRepo .. '/releases/latest')
        end
        
        print('^3========================================^7')
    end, 'GET')
end

CreateThread(function()
    Wait(2000)
    CheckVersion()
end)

print('^2[' .. RESOURCE_NAME .. '] ^7Server initialized - v' .. CURRENT_VERSION)

QBCore.Functions.CreateUseableItem(Config.ItemName, function(source, item)
    TriggerClientEvent('core_gps:client:useItem', source, item)
end)

function GenerateGPSId(playerName)
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local formattedName = playerName:upper():gsub(" ", "_")
    local randomCode = ""
    for i = 1, 8 do
        local rand = math.random(1, #charset)
        randomCode = randomCode .. string.sub(charset, rand, rand)
    end
    local id = "GPS-" .. formattedName .. "-" .. randomCode
    local result = exports['oxmysql']:executeSync('SELECT COUNT(*) as count FROM core_gps_advanced_devices WHERE gps_id = ?', {id})
    if result and result[1] and result[1].count > 0 then
        return GenerateGPSId(playerName)
    end
    return id
end

RegisterNetEvent('core_gps:server:registerDevice', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local playerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    local gpsId = GenerateGPSId(playerName)
    exports['oxmysql']:insertSync('INSERT INTO core_gps_advanced_devices (gps_id) VALUES (?)', {gpsId})
    Player.Functions.AddItem('core_gps_a', 1, false, {gps_id = gpsId})
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['core_gps_a'], "add")
    TriggerClientEvent('QBCore:Notify', src, 'GPS Device ID: ' .. gpsId, 'success')
end)

QBCore.Commands.Add('givegpsa', 'Give yourself a GPS device', {}, false, function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local playerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    local gpsId = GenerateGPSId(playerName)
    exports['oxmysql']:insertSync('INSERT INTO core_gps_advanced_devices (gps_id) VALUES (?)', {gpsId})
    Player.Functions.AddItem('core_gps_a', 1, false, {gps_id = gpsId})
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['core_gps_a'], "add")
    TriggerClientEvent('QBCore:Notify', src, 'GPS Device ID: ' .. gpsId, 'success')
end, 'admin')

RegisterNetEvent('core_gps:server:loadMarkers', function(gpsId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not gpsId then return end
    local result = exports['oxmysql']:executeSync('SELECT * FROM core_gps_advanced WHERE gps_id = ? ORDER BY id ASC', {gpsId})
    local deviceResult = exports['oxmysql']:executeSync('SELECT allow_receive_locations FROM core_gps_advanced_devices WHERE gps_id = ?', {gpsId})
    local allowReceive = false
    if deviceResult and deviceResult[1] then
        allowReceive = deviceResult[1].allow_receive_locations == 1
    end
    if result then
        local markers = {}
        for _, row in ipairs(result) do
            table.insert(markers, {
                id = row.id,
                label = row.label,
                coords = json.decode(row.coords),
                street = row.street,
                timestamp = row.timestamp
            })
        end
        gpsMarkers[gpsId] = markers
    else
        gpsMarkers[gpsId] = {}
    end
    TriggerClientEvent('core_gps:client:updateMarkers', src, gpsMarkers[gpsId])
    TriggerClientEvent('core_gps:client:updateReceiveSetting', src, allowReceive)
end)

RegisterNetEvent('core_gps:server:addMarker', function(gpsId, markerData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not gpsId or not markerData then return end
    if not gpsMarkers[gpsId] then
        gpsMarkers[gpsId] = {}
    end
    if #gpsMarkers[gpsId] >= Config.MaxMarkers then
        TriggerClientEvent('QBCore:Notify', src, 'This GPS has reached the maximum number of markers (' .. Config.MaxMarkers .. ')', 'error')
        return
    end
    local insertId = exports['oxmysql']:insertSync('INSERT INTO core_gps_advanced (gps_id, label, coords, street, timestamp) VALUES (?, ?, ?, ?, ?)', {
        gpsId,
        markerData.label,
        json.encode(markerData.coords),
        markerData.street,
        markerData.timestamp
    })
    if insertId then
        markerData.id = insertId
        table.insert(gpsMarkers[gpsId], markerData)
        TriggerClientEvent('core_gps:client:updateMarkers', src, gpsMarkers[gpsId])
        TriggerClientEvent('QBCore:Notify', src, 'Location marked!', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Failed to save marker', 'error')
    end
end)

RegisterNetEvent('core_gps:server:removeMarker', function(gpsId, index)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not gpsId then return end
    if gpsMarkers[gpsId] and gpsMarkers[gpsId][index] then
        local markerId = gpsMarkers[gpsId][index].id
        exports['oxmysql']:executeSync('DELETE FROM core_gps_advanced WHERE id = ? AND gps_id = ?', {markerId, gpsId})
        table.remove(gpsMarkers[gpsId], index)
        TriggerClientEvent('core_gps:client:updateMarkers', src, gpsMarkers[gpsId])
        TriggerClientEvent('QBCore:Notify', src, 'Marker removed!', 'success')
    end
end)

RegisterNetEvent('core_gps:server:shareMarker', function(gpsId, targetId, markerIndex)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local TargetPlayer = QBCore.Functions.GetPlayer(tonumber(targetId))
    if not Player or not gpsId then return end
    if not TargetPlayer then
        TriggerClientEvent('core_gps:client:shareResult', src, false, 'Player not found or offline')
        return
    end
    if gpsMarkers[gpsId] and gpsMarkers[gpsId][markerIndex] then
        local markerData = gpsMarkers[gpsId][markerIndex]
        local senderName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        local targetSource = TargetPlayer.PlayerData.source
        TriggerClientEvent('core_gps:client:receiveSharedMarker', targetSource, markerData, senderName, src)
        TriggerClientEvent('core_gps:client:shareResult', src, true, 'Location shared successfully!')
    else
        TriggerClientEvent('core_gps:client:shareResult', src, false, 'Marker not found')
    end
end)

RegisterNetEvent('core_gps:server:notifyShareRejected', function(senderSource)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local receiverName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    
    TriggerClientEvent('QBCore:Notify', senderSource, receiverName .. ' is not accepting shared locations.', 'error')
end)

RegisterNetEvent('core_gps:server:renameMarker', function(gpsId, index, newLabel)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not gpsId or not newLabel then return end
    
    if gpsMarkers[gpsId] and gpsMarkers[gpsId][index] then
        local markerId = gpsMarkers[gpsId][index].id
        exports['oxmysql']:executeSync('UPDATE core_gps_advanced SET label = ? WHERE id = ? AND gps_id = ?', {newLabel, markerId, gpsId})
        gpsMarkers[gpsId][index].label = newLabel
        TriggerClientEvent('core_gps:client:updateMarkers', src, gpsMarkers[gpsId])
        TriggerClientEvent('QBCore:Notify', src, 'Location renamed!', 'success')
    end
end)

RegisterNetEvent('core_gps:server:updateReceiveSetting', function(gpsId, allowed)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not gpsId then return end
    
    local allowValue = allowed and 1 or 0
    exports['oxmysql']:executeSync('UPDATE core_gps_advanced_devices SET allow_receive_locations = ? WHERE gps_id = ?', {allowValue, gpsId})
end)
