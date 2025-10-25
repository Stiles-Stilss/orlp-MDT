-- Framework Detection and Configuration
local Framework = {}

-- Auto-detect framework
local function DetectFramework()
    print("^3[OLRP-MDT]^7 Checking resource states:")
    print("^3[OLRP-MDT]^7 qbx_core:", GetResourceState('qbx_core'))
    print("^3[OLRP-MDT]^7 qb-core:", GetResourceState('qb-core'))
    print("^3[OLRP-MDT]^7 es_extended:", GetResourceState('es_extended'))
    
    if GetResourceState('qbx_core') == 'started' then
        return 'qbx'
    elseif GetResourceState('qb-core') == 'started' then
        return 'qb'
    elseif GetResourceState('es_extended') == 'started' then
        return 'esx'
    else
        return 'standalone'
    end
end

Framework.Type = DetectFramework()
print("^2[OLRP-MDT]^7 Detected framework:", Framework.Type)

-- Framework-specific configurations
Framework.Config = {
    qb = {
        core = 'qb-core',
        playerData = 'QBCore.Functions.GetPlayerData',
        triggerEvent = 'QBCore:Client:OnPlayerLoaded',
        triggerServer = 'QBCore:Server:TriggerCallback'
    },
    qbx = {
        core = 'qbx_core',
        playerData = 'exports.qbx_core:GetPlayerData',
        triggerEvent = 'QBCore:Client:OnPlayerLoaded',
        triggerServer = 'lib.callback.await'
    },
    esx = {
        core = 'es_extended',
        playerData = 'ESX.GetPlayerData',
        triggerEvent = 'esx:playerLoaded',
        triggerServer = 'esx:triggerServerCallback'
    },
    standalone = {
        core = nil,
        playerData = function() return {} end,
        triggerEvent = nil,
        triggerServer = nil
    }
}

-- Get current framework config
function Framework.GetConfig()
    return Framework.Config[Framework.Type]
end

-- Get player data based on framework
function Framework.GetPlayerData()
    local config = Framework.GetConfig()
    print("^3[OLRP-MDT]^7 Getting player data for framework:", Framework.Type)
    
    if Framework.Type == 'qb' then
        return exports[config.core]:GetPlayerData()
    elseif Framework.Type == 'qbx' then
        local Player = exports.qbx_core:GetPlayerData()
        print("^3[OLRP-MDT]^7 QBox player data:", json.encode(Player))
        return Player
    elseif Framework.Type == 'esx' then
        return ESX.GetPlayerData()
    else
        return {}
    end
end

-- Trigger server callback
function Framework.TriggerServerCallback(name, cb, ...)
    local config = Framework.GetConfig()
    if Framework.Type == 'qb' then
        exports[config.core]:TriggerCallback(name, cb, ...)
    elseif Framework.Type == 'qbx' then
        return lib.callback.await(name, false, ...)
    elseif Framework.Type == 'esx' then
        ESX.TriggerServerCallback(name, cb, ...)
    end
end

-- Show notification
function Framework.ShowNotification(message, type, duration)
    if Framework.Type == 'qb' or Framework.Type == 'qbx' then
        exports['qb-core']:Notify(message, type or 'primary', duration or 5000)
    elseif Framework.Type == 'esx' then
        ESX.ShowNotification(message)
    else
        print(message)
    end
end

local MDT = {}
MDT.isOpen = false
MDT.currentData = {}
MDT.initialized = false

-- Initialize MDT
function MDT:Init()
    if Config.Debug then
        print("^2[OLRP-MDT]^7 Initializing MDT System...")
    end
    
    -- Register keybind
    RegisterKeyMapping('mdt', 'Open MDT System', 'keyboard', Config.UI.keybind)
    
    -- Register commands
    RegisterCommand('mdt', function()
        print("^2[OLRP-MDT]^7 MDT command triggered")
        print("^2[OLRP-MDT]^7 MDT initialized:", self.initialized)
        print("^2[OLRP-MDT]^7 MDT isOpen:", self.isOpen)
        self:Toggle()
    end, false)
    
    -- Test command
    RegisterCommand('testmdt', function()
        print("^2[OLRP-MDT]^7 TEST MDT command triggered")
        self:Toggle()
    end, false)
    
    -- Setup framework events
    self:SetupFrameworkEvents()
    
    self.initialized = true
    
    if Config.Debug then
        print("^2[OLRP-MDT]^7 MDT System initialized successfully")
    end
end

-- Setup framework-specific events
function MDT:SetupFrameworkEvents()
    local config = Framework.GetConfig()
    
    if Framework.Type == 'qb' or Framework.Type == 'qbx' then
        RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
            self:OnPlayerLoaded()
        end)
        
        RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
            self:OnPlayerUnload()
        end)
    elseif Framework.Type == 'esx' then
        RegisterNetEvent('esx:playerLoaded', function()
            self:OnPlayerLoaded()
        end)
        
        RegisterNetEvent('esx:onPlayerLogout', function()
            self:OnPlayerUnload()
        end)
    end
end

-- Player loaded event
function MDT:OnPlayerLoaded()
    if Config.Debug then
        print("^2[OLRP-MDT]^7 Player loaded, checking permissions...")
    end
    
    local playerData = Framework.GetPlayerData()
    if self:CheckPermissions(playerData) then
        if Config.Debug then
            print("^2[OLRP-MDT]^7 Player has MDT access")
        end
    else
        if Config.Debug then
            print("^3[OLRP-MDT]^7 Player does not have MDT access")
        end
    end
end

-- Player unload event
function MDT:OnPlayerUnload()
    if self.isOpen then
        self:Close()
    end
end

-- Check if player has permissions to use MDT
function MDT:CheckPermissions(playerData)
    if not Config.Jobs.enabled then
        return true
    end
    
    local job = playerData.job
    if not job then
        return false
    end
    
    -- Check if job is allowed
    for _, allowedJob in ipairs(Config.Jobs.allowedJobs) do
        if job.name == allowedJob then
            -- Check grade restrictions
            if Config.Grades.enabled then
                local restrictions = Config.Grades.restrictions[job.name]
                if restrictions and restrictions[job.grade.level] then
                    return true
                elseif job.grade.level >= Config.Grades.minimumGrade then
                    return true
                end
            else
                return true
            end
        end
    end
    
    return false
end

-- Toggle MDT
function MDT:Toggle()
    print("^2[OLRP-MDT]^7 Toggle called, isOpen:", self.isOpen)
    if self.isOpen then
        print("^2[OLRP-MDT]^7 Closing MDT")
        self:Close()
    else
        print("^2[OLRP-MDT]^7 Opening MDT")
        self:Open()
    end
end

-- Open MDT
function MDT:Open()
    if self.isOpen then
        return
    end
    
    if not self.initialized then
        print("^1[OLRP-MDT]^7 MDT not initialized yet")
        return
    end
    
    local playerData = Framework.GetPlayerData()
    print("^3[OLRP-MDT]^7 Player data:", json.encode(playerData))
    
    if not self:CheckPermissions(playerData) then
        print("^1[OLRP-MDT]^7 Permission denied for player")
        Framework.ShowNotification("You don't have permission to access the MDT system", 'error')
        return
    end
    
    print("^2[OLRP-MDT]^7 Opening MDT for player")
    
    self.isOpen = true
    
    -- Set NUI focus
    SetNuiFocus(true, true)
    
    -- Send player data to NUI
    self:SendPlayerData(playerData)
    
    -- Open NUI
    SendNUIMessage({
        type = 'open',
        data = {
            player = playerData,
            config = Config
        }
    })
    
    if Config.UI.sounds then
        PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
    end
    
    if Config.Debug then
        print("^2[OLRP-MDT]^7 MDT opened")
    end
end

-- Close MDT
function MDT:Close()
    if not self.isOpen then
        return
    end
    
    self.isOpen = false
    
    -- Remove NUI focus
    SetNuiFocus(false, false)
    
    -- Close NUI
    SendNUIMessage({
        type = 'close'
    })
    
    if Config.UI.sounds then
        PlaySoundFrontend(-1, "CANCEL", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
    end
    
    if Config.Debug then
        print("^2[OLRP-MDT]^7 MDT closed")
    end
end

-- Send player data to NUI
function MDT:SendPlayerData(playerData)
    SendNUIMessage({
        type = 'playerData',
        data = {
            name = playerData.charinfo?.firstname .. ' ' .. playerData.charinfo?.lastname or 'Unknown',
            badge = playerData.job?.grade?.name or 'Officer',
            department = playerData.job?.label or 'Police',
            rank = playerData.job?.grade?.level or 0,
            callsign = playerData.metadata?.callsign or 'N/A'
        }
    })
end

-- Handle NUI callbacks
RegisterNUICallback('close', function(data, cb)
    MDT:Close()
    cb('ok')
end)

RegisterNUICallback('getData', function(data, cb)
    local dataType = data.type
    
    if dataType == 'citizens' then
        Framework.TriggerServerCallback('mdt:getCitizens', function(result)
            cb(result)
        end, data.query)
    elseif dataType == 'vehicles' then
        Framework.TriggerServerCallback('mdt:getVehicles', function(result)
            cb(result)
        end, data.query)
    elseif dataType == 'incidents' then
        Framework.TriggerServerCallback('mdt:getIncidents', function(result)
            cb(result)
        end, data.query)
    elseif dataType == 'dashboard' then
        Framework.TriggerServerCallback('mdt:getDashboardData', function(result)
            cb(result)
        end)
    else
        cb({})
    end
end)

RegisterNUICallback('createIncident', function(data, cb)
    Framework.TriggerServerCallback('mdt:createIncident', function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('updateIncident', function(data, cb)
    Framework.TriggerServerCallback('mdt:updateIncident', function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('createCitizen', function(data, cb)
    Framework.TriggerServerCallback('mdt:createCitizen', function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('updateCitizen', function(data, cb)
    Framework.TriggerServerCallback('mdt:updateCitizen', function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('createVehicle', function(data, cb)
    Framework.TriggerServerCallback('mdt:createVehicle', function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('updateVehicle', function(data, cb)
    Framework.TriggerServerCallback('mdt:updateVehicle', function(result)
        cb(result)
    end, data)
end)

-- Handle server events
RegisterNetEvent('mdt:updateData', function(data)
    if MDT.isOpen then
        SendNUIMessage({
            type = 'updateData',
            data = data
        })
    end
end)

RegisterNetEvent('mdt:notification', function(message, type)
    if MDT.isOpen then
        SendNUIMessage({
            type = 'notification',
            data = {
                message = message,
                type = type
            }
        })
    end
    
    Framework.ShowNotification(message, type)
end)

-- Initialize MDT when resource starts
CreateThread(function()
    MDT:Init()
end)
