local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local savedMarkers = {}
local blips = {}
local markersVisible = true
local receiveLocationsAllowed = false
local isUIOpen = false
local currentGPSId = nil

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    savedMarkers = {}
    currentGPSId = nil
    ClearAllBlips()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        PlayerData = QBCore.Functions.GetPlayerData()
        Wait(1000)
        if markersVisible then
            local hasItem, itemData = GetGPSItem()
            if hasItem and itemData and itemData.info and itemData.info.gps_id then
                currentGPSId = itemData.info.gps_id
                TriggerServerEvent('core_gps:server:loadMarkers', currentGPSId)
                Wait(500)
                if #savedMarkers > 0 then
                    RefreshBlips()
                end
            end
        end
    end
end)

function GetGPSItem()
    local Player = QBCore.Functions.GetPlayerData()
    if not Player then return false, nil end
    for _, item in pairs(Player.items) do
        if item and item.name == Config.ItemName then
            return true, item
        end
    end
    return false, nil
end

function CountGPSItems()
    local Player = QBCore.Functions.GetPlayerData()
    if not Player then return 0 end
    local count = 0
    for _, item in pairs(Player.items) do
        if item and item.name == Config.ItemName then
            count = count + 1
        end
    end
    return count
end

RegisterNetEvent('core_gps:client:useItem', function(item)
    if item and item.info and item.info.gps_id then
        currentGPSId = item.info.gps_id
        TriggerServerEvent('core_gps:server:loadMarkers', currentGPSId)
        Wait(100)
        OpenGPSUI()
    else
        QBCore.Functions.Notify('This GPS device is not properly registered!', 'error')
    end
end)

function OpenGPSUI()
    if isUIOpen then return end
    if not currentGPSId then
        QBCore.Functions.Notify('No GPS device detected!', 'error')
        return
    end
    isUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openUI',
        markers = savedMarkers,
        markersVisible = markersVisible,
        gpsId = currentGPSId
    })
end

RegisterNUICallback('closeUI', function(data, cb)
    isUIOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('markLocation', function(data, cb)
    if not currentGPSId then
        QBCore.Functions.Notify('GPS device not detected. Please try closing and reopening the GPS.', 'error')
        cb('error')
        return
    end
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    local markerData = {
        label = data.label or 'Marked Location',
        coords = {x = coords.x, y = coords.y, z = coords.z},
        street = streetName,
        timestamp = (os and os.time and os.time()) or math.floor(GetGameTimer() / 1000)
    }
    TriggerServerEvent('core_gps:server:addMarker', currentGPSId, markerData)
    cb('ok')
end)

RegisterNUICallback('removeMarker', function(data, cb)
    if not currentGPSId then
        cb('error')
        return
    end
    TriggerServerEvent('core_gps:server:removeMarker', currentGPSId, data.index)
    cb('ok')
end)

RegisterNUICallback('shareMarker', function(data, cb)
    if not currentGPSId then
        cb('error')
        return
    end
    TriggerServerEvent('core_gps:server:shareMarker', currentGPSId, data.playerId, data.index)
    cb('ok')
end)

RegisterNUICallback('toggleMarkers', function(data, cb)
    markersVisible = data.visible
    if markersVisible then
        local hasItem, itemData = GetGPSItem()
        if hasItem and itemData and itemData.info and itemData.info.gps_id then
            RefreshBlips()
        end
    else
        ClearAllBlips()
    end
    cb('ok')
end)

RegisterNUICallback('toggleReceiveLocations', function(data, cb)
    receiveLocationsAllowed = data.allowed
    cb('ok')
end)

RegisterNUICallback('setWaypoint', function(data, cb)
    local marker = savedMarkers[data.index]
    if marker then
        SetNewWaypoint(marker.coords.x, marker.coords.y)
        QBCore.Functions.Notify('Waypoint set!', 'success')
    end
    cb('ok')
end)

RegisterNetEvent('core_gps:client:updateMarkers', function(markers)
    savedMarkers = markers
    if isUIOpen then
        SendNUIMessage({
            action = 'updateMarkers',
            markers = savedMarkers
        })
    end
    if markersVisible then
        local hasItem, itemData = GetGPSItem()
        if hasItem and itemData and itemData.info and itemData.info.gps_id then
            RefreshBlips()
        else
            ClearAllBlips()
        end
    end
end)

RegisterNetEvent('core_gps:client:receiveSharedMarker', function(markerData, senderName, senderSource)
    if not receiveLocationsAllowed then
        QBCore.Functions.Notify('You have disabled location sharing. Enable "Allow Receiving Locations" in your GPS settings.', 'error')
        TriggerServerEvent('core_gps:server:notifyShareRejected', senderSource)
        return
    end
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'receiveLocation',
        markerData = markerData,
        senderName = senderName
    })
end)

RegisterNUICallback('acceptSharedLocation', function(data, cb)
    local markerData = data.markerData
    local hasItem, itemData = GetGPSItem()
    if hasItem and itemData and itemData.info and itemData.info.gps_id then
        TriggerServerEvent('core_gps:server:addMarker', itemData.info.gps_id, markerData)
        QBCore.Functions.Notify('Location accepted and saved to your GPS!', 'success')
    else
        QBCore.Functions.Notify('You need a GPS device to save this location!', 'error')
    end
    cb('ok')
end)

RegisterNUICallback('declineSharedLocation', function(data, cb)
    QBCore.Functions.Notify('Location declined', 'error')
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('closeReceiveModal', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNetEvent('core_gps:client:shareResult', function(success, message)
    if success then
        QBCore.Functions.Notify(message, 'success')
    else
        QBCore.Functions.Notify(message, 'error')
    end
end)

function RefreshBlips()
    ClearAllBlips()
    if not markersVisible then return end
    local gpsCount = CountGPSItems()
    if gpsCount > 1 then
        QBCore.Functions.Notify('You have too many GPS devices on you to display map data', 'error')
        return
    end
    local hasItem, itemData = GetGPSItem()
    if not hasItem or not itemData or not itemData.info or not itemData.info.gps_id then 
        return
    end
    for i, marker in ipairs(savedMarkers) do
        local blip = AddBlipForCoord(marker.coords.x, marker.coords.y, marker.coords.z)
        SetBlipSprite(blip, Config.BlipSettings.sprite)
        SetBlipColour(blip, Config.BlipSettings.color)
        SetBlipScale(blip, Config.BlipSettings.scale)
        SetBlipDisplay(blip, Config.BlipSettings.display)
        SetBlipAsShortRange(blip, Config.BlipSettings.shortRange)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(marker.label)
        EndTextCommandSetBlipName(blip)
        table.insert(blips, blip)
    end
end

function ClearAllBlips()
    for _, blip in ipairs(blips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    blips = {}
end

RegisterNetEvent('core_gps:client:itemAdded', function(item)
    if not item or not item.info or not item.info.gps_id then return end
    currentGPSId = item.info.gps_id
    TriggerServerEvent('core_gps:server:loadMarkers', currentGPSId)
    Wait(500)
    if markersVisible and #savedMarkers > 0 then
        RefreshBlips()
    end
end)

RegisterNetEvent('core_gps:client:itemRemoved', function()
    currentGPSId = nil
    savedMarkers = {}
    ClearAllBlips()
end)

RegisterNetEvent('QBCore:Client:ItemBox', function(itemData, type)
    if itemData.name == Config.ItemName then
        if type == "add" then
            local hasItem, item = GetGPSItem()
            if hasItem and item and item.info and item.info.gps_id then
                currentGPSId = item.info.gps_id
                TriggerServerEvent('core_gps:server:loadMarkers', currentGPSId)
                Wait(500)
                if markersVisible and #savedMarkers > 0 then
                    RefreshBlips()
                end
            end
        elseif type == "remove" then
            Wait(100)
            local hasItem, item = GetGPSItem()
            if not hasItem then
                currentGPSId = nil
                savedMarkers = {}
                ClearAllBlips()
            elseif item and item.info and item.info.gps_id and currentGPSId ~= item.info.gps_id then
                currentGPSId = item.info.gps_id
                TriggerServerEvent('core_gps:server:loadMarkers', currentGPSId)
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        ClearAllBlips()
        if isUIOpen then
            SetNuiFocus(false, false)
        end
    end
end)
