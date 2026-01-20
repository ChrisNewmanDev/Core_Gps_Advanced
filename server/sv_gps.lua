local QBCore = exports['qb-core']:GetCoreObject()

local gpsMarkers = {}

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
