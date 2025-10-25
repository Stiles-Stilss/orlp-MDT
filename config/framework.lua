-- Framework Detection and Configuration
local Framework = {}

-- Auto-detect framework
local function DetectFramework()
    if GetResourceState('qb-core') == 'started' then
        return 'qb'
    elseif GetResourceState('qbx_core') == 'started' then
        return 'qbx'
    elseif GetResourceState('es_extended') == 'started' then
        return 'esx'
    else
        return 'standalone'
    end
end

Framework.Type = DetectFramework()

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
    if Framework.Type == 'qb' then
        return exports[config.core]:GetPlayerData()
    elseif Framework.Type == 'qbx' then
        return exports.qbx_core:GetPlayerData()
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

return Framework
