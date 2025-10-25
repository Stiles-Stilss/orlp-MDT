-- Framework Detection and Configuration
local Framework = {}

-- Auto-detect framework
local function DetectFramework()
    print("^3[OLRP-MDT]^7 Server checking resource states:")
    print("^3[OLRP-MDT]^7 qbx_core:", GetResourceState('qbx_core'))
    print("^3[OLRP-MDT]^7 qb-core:", GetResourceState('qb-core'))
    print("^3[OLRP-MDT]^7 es_extended:", GetResourceState('es_extended'))
    print("^3[OLRP-MDT]^7 ox_lib:", GetResourceState('ox_lib'))
    
    if GetResourceState('qbx_core') == 'started' and GetResourceState('ox_lib') == 'started' then
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
print("^2[OLRP-MDT]^7 Server detected framework:", Framework.Type)

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
function Framework.GetPlayerData(source)
    local config = Framework.GetConfig()
    if Framework.Type == 'qb' then
        local Player = exports[config.core]:GetPlayer(source)
        return Player and Player.PlayerData or nil
    elseif Framework.Type == 'qbx' then
        local Player = exports.qbx_core:GetPlayer(source)
        return Player and Player.PlayerData or nil
    elseif Framework.Type == 'esx' then
        return ESX.GetPlayerFromId(source)
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
        if lib and lib.callback then
            return lib.callback.await(name, false, ...)
        else
            -- QBox doesn't have TriggerCallback export, use direct callback
            print('MDT: Using direct callback for QBox without ox_lib')
            -- This is a fallback - ideally ox_lib should be used
            return {}
        end
    elseif Framework.Type == 'esx' then
        ESX.TriggerServerCallback(name, cb, ...)
    end
end

-- Show notification
function Framework.ShowNotification(source, message, type, duration)
    if Framework.Type == 'qb' or Framework.Type == 'qbx' then
        TriggerClientEvent('QBCore:Notify', source, message, type or 'primary', duration or 5000)
    elseif Framework.Type == 'esx' then
        TriggerClientEvent('esx:showNotification', source, message)
    else
        print(message)
    end
end

local MDT = {}
MDT.Players = {}
MDT.Data = {
    citizens = {},
    vehicles = {},
    incidents = {},
    arrests = {},
    warrants = {},
    bolos = {},
    calls = {},
    cases = {},
    evidence = {}
}

-- Initialize MDT Server
function MDT:Init()
    if Config.Debug then
        print("^2[OLRP-MDT]^7 Initializing MDT Server...")
    end
    
    -- Setup database
    self:SetupDatabase()
    
    -- Register callbacks
    self:RegisterCallbacks()
    
    -- Register events
    self:RegisterEvents()
    
    -- Load initial data
    self:LoadInitialData()
    
    if Config.Debug then
        print("^2[OLRP-MDT]^7 MDT Server initialized successfully")
    end
end

-- Setup database tables
function MDT:SetupDatabase()
    if not Config.Database.useOxmysql then
        return
    end
    
    -- Citizens table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS mdt_citizens (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(50) UNIQUE NOT NULL,
            firstname VARCHAR(50) NOT NULL,
            lastname VARCHAR(50) NOT NULL,
            dateofbirth DATE NOT NULL,
            license VARCHAR(20),
            phone VARCHAR(20),
            address TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])
    
    -- Vehicles table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS mdt_vehicles (
            id INT AUTO_INCREMENT PRIMARY KEY,
            plate VARCHAR(20) UNIQUE NOT NULL,
            model VARCHAR(50) NOT NULL,
            owner_citizenid VARCHAR(50),
            vin VARCHAR(50),
            insurance_status ENUM('active', 'expired', 'suspended') DEFAULT 'active',
            registration_status ENUM('valid', 'expired', 'suspended') DEFAULT 'valid',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])
    
    -- Incidents table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS mdt_incidents (
            id INT AUTO_INCREMENT PRIMARY KEY,
            incident_type VARCHAR(50) NOT NULL,
            location TEXT NOT NULL,
            description TEXT,
            officer_citizenid VARCHAR(50) NOT NULL,
            officer_name VARCHAR(100) NOT NULL,
            status ENUM('open', 'closed', 'pending') DEFAULT 'open',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])
    
    -- Arrests table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS mdt_arrests (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(50) NOT NULL,
            officer_citizenid VARCHAR(50) NOT NULL,
            charges TEXT NOT NULL,
            fine_amount DECIMAL(10,2) DEFAULT 0,
            jail_time INT DEFAULT 0,
            incident_id INT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (incident_id) REFERENCES mdt_incidents(id)
        )
    ]])
    
    -- Warrants table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS mdt_warrants (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(50) NOT NULL,
            warrant_type VARCHAR(50) NOT NULL,
            description TEXT NOT NULL,
            issued_by VARCHAR(50) NOT NULL,
            status ENUM('active', 'executed', 'cancelled') DEFAULT 'active',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])
    
    -- BOLOs table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS mdt_bolos (
            id INT AUTO_INCREMENT PRIMARY KEY,
            title VARCHAR(100) NOT NULL,
            description TEXT NOT NULL,
            vehicle_plate VARCHAR(20),
            suspect_description TEXT,
            officer_citizenid VARCHAR(50) NOT NULL,
            status ENUM('active', 'resolved', 'cancelled') DEFAULT 'active',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])
    
    -- 911 Calls table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS mdt_calls (
            id INT AUTO_INCREMENT PRIMARY KEY,
            call_type VARCHAR(50) NOT NULL,
            location TEXT NOT NULL,
            description TEXT,
            caller_name VARCHAR(100),
            caller_phone VARCHAR(20),
            status ENUM('pending', 'assigned', 'completed', 'cancelled') DEFAULT 'pending',
            assigned_officer VARCHAR(50),
            priority ENUM('low', 'medium', 'high', 'emergency') DEFAULT 'medium',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])
    
    -- Cases table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS mdt_cases (
            id INT AUTO_INCREMENT PRIMARY KEY,
            case_number VARCHAR(20) UNIQUE NOT NULL,
            case_type VARCHAR(50) NOT NULL,
            description TEXT NOT NULL,
            assigned_officer VARCHAR(50) NOT NULL,
            status ENUM('open', 'closed', 'pending') DEFAULT 'open',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])
    
    -- Evidence table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS mdt_evidence (
            id INT AUTO_INCREMENT PRIMARY KEY,
            evidence_type VARCHAR(50) NOT NULL,
            description TEXT NOT NULL,
            location_found TEXT,
            collected_by VARCHAR(50) NOT NULL,
            case_id INT,
            status ENUM('collected', 'analyzed', 'stored', 'destroyed') DEFAULT 'collected',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            FOREIGN KEY (case_id) REFERENCES mdt_cases(id)
        )
    ]])
end

-- Register server callbacks
function MDT:RegisterCallbacks()
    print('MDT: Registering callbacks for framework:', Framework.Type)
    print('MDT: lib available:', lib ~= nil)
    if lib then
        print('MDT: lib.callback available:', lib.callback ~= nil)
    end
    
    if Framework.Type == 'qbx' then
        -- QBox uses lib.callback, but fallback to QBCore if ox_lib not available
        if lib and lib.callback then
            lib.callback.register('mdt:getCitizens', function(source, query)
                return self:GetCitizens(query)
            end)
        
        lib.callback.register('mdt:getVehicles', function(source, query)
            return self:GetVehicles(query)
        end)
        
        lib.callback.register('mdt:getIncidents', function(source, query)
            return self:GetIncidents(query)
        end)
        
        lib.callback.register('mdt:getDashboardData', function(source)
            return self:GetDashboardData()
        end)
        
        lib.callback.register('mdt:createIncident', function(source, data)
            return self:CreateIncident(source, data)
        end)
        
        lib.callback.register('mdt:updateIncident', function(source, data)
            return self:UpdateIncident(source, data)
        end)
        
        lib.callback.register('mdt:createCitizen', function(source, data)
            return self:CreateCitizen(source, data)
        end)
        
        lib.callback.register('mdt:updateCitizen', function(source, data)
            return self:UpdateCitizen(source, data)
        end)
        
        lib.callback.register('mdt:createVehicle', function(source, data)
            return self:CreateVehicle(source, data)
        end)
        
        lib.callback.register('mdt:updateVehicle', function(source, data)
            return self:UpdateVehicle(source, data)
        end)
            print('MDT: QBox callbacks registered successfully')
        else
            print('MDT: ox_lib not available for QBox - callbacks will not work')
            print('MDT: Please install and start ox_lib resource for QBox support')
            print('MDT: Or switch to QBCore framework')
        end
    else
        -- QBCore/ESX use traditional callbacks
        -- Get citizens
        Framework.TriggerServerCallback('mdt:getCitizens', function(source, cb, query)
            local result = self:GetCitizens(query)
            cb(result)
        end)
        
        -- Get vehicles
        Framework.TriggerServerCallback('mdt:getVehicles', function(source, cb, query)
            local result = self:GetVehicles(query)
            cb(result)
        end)
        
        -- Get incidents
        Framework.TriggerServerCallback('mdt:getIncidents', function(source, cb, query)
            local result = self:GetIncidents(query)
            cb(result)
        end)
        
        -- Get dashboard data
        Framework.TriggerServerCallback('mdt:getDashboardData', function(source, cb)
            local result = self:GetDashboardData()
            cb(result)
        end)
        
        -- Create incident
        Framework.TriggerServerCallback('mdt:createIncident', function(source, cb, data)
            local result = self:CreateIncident(source, data)
            cb(result)
        end)
        
        -- Update incident
        Framework.TriggerServerCallback('mdt:updateIncident', function(source, cb, data)
            local result = self:UpdateIncident(source, data)
            cb(result)
        end)
        
        -- Create citizen
        Framework.TriggerServerCallback('mdt:createCitizen', function(source, cb, data)
            local result = self:CreateCitizen(source, data)
            cb(result)
        end)
        
        -- Update citizen
        Framework.TriggerServerCallback('mdt:updateCitizen', function(source, cb, data)
            local result = self:UpdateCitizen(source, data)
            cb(result)
        end)
        
        -- Create vehicle
        Framework.TriggerServerCallback('mdt:createVehicle', function(source, cb, data)
            local result = self:CreateVehicle(source, data)
            cb(result)
        end)
        
        -- Update vehicle
        Framework.TriggerServerCallback('mdt:updateVehicle', function(source, cb, data)
            local result = self:UpdateVehicle(source, data)
            cb(result)
        end)
    end
end

-- Register server events
function MDT:RegisterEvents()
    -- Player connecting
    AddEventHandler('playerConnecting', function()
        local source = source
        self.Players[source] = {
            connected = true,
            lastSeen = os.time()
        }
    end)
    
    -- Player disconnecting
    AddEventHandler('playerDropped', function()
        local source = source
        if self.Players[source] then
            self.Players[source] = nil
        end
    end)
end

-- Load initial data
function MDT:LoadInitialData()
    if not Config.Database.useOxmysql then
        return
    end
    
    -- Load citizens
    MySQL.query('SELECT * FROM mdt_citizens', {}, function(result)
        if result then
            for _, citizen in ipairs(result) do
                self.Data.citizens[citizen.citizenid] = citizen
            end
        end
    end)
    
    -- Load vehicles
    MySQL.query('SELECT * FROM mdt_vehicles', {}, function(result)
        if result then
            for _, vehicle in ipairs(result) do
                self.Data.vehicles[vehicle.plate] = vehicle
            end
        end
    end)
    
    -- Load incidents
    MySQL.query('SELECT * FROM mdt_incidents ORDER BY created_at DESC', {}, function(result)
        if result then
            for _, incident in ipairs(result) do
                table.insert(self.Data.incidents, incident)
            end
        end
    end)
end

-- Get citizens data
function MDT:GetCitizens(query)
    print('MDT: GetCitizens called with query:', query)
    print('MDT: Framework Type:', Framework.Type)
    
    -- First, let's see what tables exist
    local tablesResult = MySQL.query.await('SHOW TABLES', {})
    print('MDT: Available tables:', json.encode(tablesResult))
    
    local citizens = {}
    
    if Framework.Type == 'qbx' then
        -- QBox - Get players from database
        local sql = 'SELECT * FROM players WHERE firstname IS NOT NULL AND lastname IS NOT NULL'
        local params = {}
        
        if query and query ~= '' then
            sql = sql .. ' AND (firstname LIKE ? OR lastname LIKE ? OR citizenid LIKE ? OR license LIKE ?)'
            local searchTerm = '%' .. query .. '%'
            params = {searchTerm, searchTerm, searchTerm, searchTerm}
        end
        
        sql = sql .. ' ORDER BY lastname, firstname LIMIT 100'
        
        print('MDT: Executing QBox query:', sql)
        local result = MySQL.query.await(sql, params)
        print('MDT: QBox query result:', json.encode(result))
        
        -- If no results, try alternative table names
        if not result or #result == 0 then
            print('MDT: No results from players table, trying alternative...')
            
            -- Try different table structures
            local alternatives = {
                'SELECT * FROM characters WHERE firstname IS NOT NULL AND lastname IS NOT NULL LIMIT 10',
                'SELECT * FROM users WHERE firstname IS NOT NULL AND lastname IS NOT NULL LIMIT 10',
                'SELECT * FROM players LIMIT 10',
                'SELECT * FROM characters LIMIT 10',
                'SELECT * FROM users LIMIT 10'
            }
            
            for i, altSql in ipairs(alternatives) do
                print('MDT: Trying alternative query', i, ':', altSql)
                result = MySQL.query.await(altSql, {})
                if result and #result > 0 then
                    print('MDT: Found data with alternative query', i, ':', json.encode(result))
                    break
                end
            end
        end
        
        if result then
            for _, player in pairs(result) do
                -- Flexible field mapping for different table structures
                local citizenData = {
                    citizenid = player.citizenid or player.identifier or player.id or 'N/A',
                    firstname = player.firstname or player.first_name or 'Unknown',
                    lastname = player.lastname or player.last_name or 'Unknown',
                    license = player.license or player.identifier or 'N/A',
                    phone = player.phone or player.phone_number or 'N/A',
                    birthdate = player.birthdate or player.dateofbirth or player.dob or 'N/A',
                    address = player.address or 'Unknown',
                    status = 'active',
                    warrants = false, -- TODO: Check warrants table
                    arrests = 0 -- TODO: Count arrests
                }
                
                -- Only add if we have at least a name
                if citizenData.firstname ~= 'Unknown' and citizenData.lastname ~= 'Unknown' then
                    table.insert(citizens, citizenData)
                end
            end
        end
    elseif Framework.Type == 'qb' then
        -- QBCore - Get players from database
        local sql = 'SELECT * FROM players WHERE firstname IS NOT NULL AND lastname IS NOT NULL'
        local params = {}
        
        if query and query ~= '' then
            sql = sql .. ' AND (firstname LIKE ? OR lastname LIKE ? OR citizenid LIKE ? OR license LIKE ?)'
            local searchTerm = '%' .. query .. '%'
            params = {searchTerm, searchTerm, searchTerm, searchTerm}
        end
        
        sql = sql .. ' ORDER BY lastname, firstname LIMIT 100'
        
        local result = MySQL.query.await(sql, params)
        if result then
            for _, player in pairs(result) do
                table.insert(citizens, {
                    citizenid = player.citizenid,
                    firstname = player.firstname,
                    lastname = player.lastname,
                    license = player.license,
                    phone = player.phone,
                    birthdate = player.birthdate,
                    address = player.address or 'Unknown',
                    status = 'active',
                    warrants = false,
                    arrests = 0
                })
            end
        end
    elseif Framework.Type == 'esx' then
        -- ESX - Get players from database
        local sql = 'SELECT * FROM users WHERE firstname IS NOT NULL AND lastname IS NOT NULL'
        local params = {}
        
        if query and query ~= '' then
            sql = sql .. ' AND (firstname LIKE ? OR lastname LIKE ? OR identifier LIKE ?)'
            local searchTerm = '%' .. query .. '%'
            params = {searchTerm, searchTerm, searchTerm}
        end
        
        sql = sql .. ' ORDER BY lastname, firstname LIMIT 100'
        
        local result = MySQL.query.await(sql, params)
        if result then
            for _, player in pairs(result) do
                table.insert(citizens, {
                    citizenid = player.identifier,
                    firstname = player.firstname,
                    lastname = player.lastname,
                    license = player.identifier,
                    phone = player.phone_number or 'Unknown',
                    birthdate = player.dateofbirth or 'Unknown',
                    address = 'Unknown',
                    status = 'active',
                    warrants = false,
                    arrests = 0
                })
            end
        end
    end
    
    print('MDT: Returning citizens:', json.encode(citizens))
    return citizens
end

-- Get vehicles data
function MDT:GetVehicles(query)
    local vehicles = {}
    
    if Framework.Type == 'qbx' then
        -- QBox - Get vehicles from database
        local sql = 'SELECT * FROM player_vehicles WHERE plate IS NOT NULL'
        local params = {}
        
        if query and query ~= '' then
            sql = sql .. ' AND (plate LIKE ? OR vehicle LIKE ? OR citizenid LIKE ?)'
            local searchTerm = '%' .. query .. '%'
            params = {searchTerm, searchTerm, searchTerm}
        end
        
        sql = sql .. ' ORDER BY plate LIMIT 100'
        
        local result = MySQL.query.await(sql, params)
        if result then
            for _, vehicle in pairs(result) do
                table.insert(vehicles, {
                    plate = vehicle.plate,
                    model = vehicle.vehicle,
                    owner_citizenid = vehicle.citizenid,
                    owner_name = 'Unknown', -- TODO: Join with players table
                    status = 'active',
                    stolen = false, -- TODO: Check stolen vehicles
                    insurance = true,
                    registration = 'Valid'
                })
            end
        end
    elseif Framework.Type == 'qb' then
        -- QBCore - Get vehicles from database
        local sql = 'SELECT * FROM player_vehicles WHERE plate IS NOT NULL'
        local params = {}
        
        if query and query ~= '' then
            sql = sql .. ' AND (plate LIKE ? OR vehicle LIKE ? OR citizenid LIKE ?)'
            local searchTerm = '%' .. query .. '%'
            params = {searchTerm, searchTerm, searchTerm}
        end
        
        sql = sql .. ' ORDER BY plate LIMIT 100'
        
        local result = MySQL.query.await(sql, params)
        if result then
            for _, vehicle in pairs(result) do
                table.insert(vehicles, {
                    plate = vehicle.plate,
                    model = vehicle.vehicle,
                    owner_citizenid = vehicle.citizenid,
                    owner_name = 'Unknown',
                    status = 'active',
                    stolen = false,
                    insurance = true,
                    registration = 'Valid'
                })
            end
        end
    elseif Framework.Type == 'esx' then
        -- ESX - Get vehicles from database
        local sql = 'SELECT * FROM owned_vehicles WHERE plate IS NOT NULL'
        local params = {}
        
        if query and query ~= '' then
            sql = sql .. ' AND (plate LIKE ? OR vehicle LIKE ? OR owner LIKE ?)'
            local searchTerm = '%' .. query .. '%'
            params = {searchTerm, searchTerm, searchTerm}
        end
        
        sql = sql .. ' ORDER BY plate LIMIT 100'
        
        local result = MySQL.query.await(sql, params)
        if result then
            for _, vehicle in pairs(result) do
                local vehicleData = json.decode(vehicle.vehicle)
                table.insert(vehicles, {
                    plate = vehicle.plate,
                    model = vehicleData.model,
                    owner_citizenid = vehicle.owner,
                    owner_name = 'Unknown',
                    status = 'active',
                    stolen = false,
                    insurance = true,
                    registration = 'Valid'
                })
            end
        end
    end
    
    return vehicles
end

-- Get incidents data
function MDT:GetIncidents(query)
    if Config.Database.useOxmysql then
        local sql = 'SELECT * FROM mdt_incidents'
        local params = {}
        
        if query and query ~= '' then
            sql = sql .. ' WHERE incident_type LIKE ? OR location LIKE ? OR officer_name LIKE ?'
            local searchTerm = '%' .. query .. '%'
            params = {searchTerm, searchTerm, searchTerm}
        end
        
        sql = sql .. ' ORDER BY created_at DESC LIMIT 100'
        
        local result = MySQL.query.await(sql, params)
        return result or {}
    else
        -- Fallback to in-memory data
        local incidents = {}
        for _, incident in ipairs(self.Data.incidents) do
            if not query or query == '' or 
               string.find(string.lower(incident.incident_type), string.lower(query)) or
               string.find(string.lower(incident.location), string.lower(query)) or
               string.find(string.lower(incident.officer_name), string.lower(query)) then
                table.insert(incidents, incident)
            end
        end
        return incidents
    end
end

-- Get dashboard data
function MDT:GetDashboardData()
    local data = {
        activeCalls = 0,
        openCases = 0,
        arrestsToday = 0,
        activeWarrants = 0,
        crimeStats = {
            labels = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'},
            data = {12, 19, 3, 5, 2, 3}
        },
        responseTimes = {
            labels = {'Week 1', 'Week 2', 'Week 3', 'Week 4'},
            data = {4.2, 3.8, 4.5, 3.9}
        }
    }
    
    if Config.Database.useOxmysql then
        -- Get active calls
        local activeCalls = MySQL.query.await('SELECT COUNT(*) as count FROM mdt_calls WHERE status IN (?, ?)', {'pending', 'assigned'})
        if activeCalls and activeCalls[1] then
            data.activeCalls = activeCalls[1].count
        end
        
        -- Get open cases
        local openCases = MySQL.query.await('SELECT COUNT(*) as count FROM mdt_cases WHERE status = ?', {'open'})
        if openCases and openCases[1] then
            data.openCases = openCases[1].count
        end
        
        -- Get arrests today
        local today = os.date('%Y-%m-%d')
        local arrestsToday = MySQL.query.await('SELECT COUNT(*) as count FROM mdt_arrests WHERE DATE(created_at) = ?', {today})
        if arrestsToday and arrestsToday[1] then
            data.arrestsToday = arrestsToday[1].count
        end
        
        -- Get active warrants
        local activeWarrants = MySQL.query.await('SELECT COUNT(*) as count FROM mdt_warrants WHERE status = ?', {'active'})
        if activeWarrants and activeWarrants[1] then
            data.activeWarrants = activeWarrants[1].count
        end
    end
    
    return data
end

-- Create incident
function MDT:CreateIncident(source, data)
    local playerData = self:GetPlayerData(source)
    if not playerData then
        return {success = false, message = 'Player data not found'}
    end
    
    if Config.Database.useOxmysql then
        local result = MySQL.insert.await('INSERT INTO mdt_incidents (incident_type, location, description, officer_citizenid, officer_name) VALUES (?, ?, ?, ?, ?)', {
            data.type,
            data.location,
            data.description,
            playerData.citizenid,
            playerData.firstname .. ' ' .. playerData.lastname
        })
        
        if result then
            -- Notify all online officers
            self:NotifyOfficers('New incident report created', 'info')
            return {success = true, message = 'Incident created successfully', id = result.insertId}
        else
            return {success = false, message = 'Failed to create incident'}
        end
    else
        -- Fallback to in-memory storage
        local incident = {
            id = #self.Data.incidents + 1,
            incident_type = data.type,
            location = data.location,
            description = data.description,
            officer_citizenid = playerData.citizenid,
            officer_name = playerData.firstname .. ' ' .. playerData.lastname,
            status = 'open',
            created_at = os.date('%Y-%m-%d %H:%M:%S')
        }
        
        table.insert(self.Data.incidents, incident)
        self:NotifyOfficers('New incident report created', 'info')
        return {success = true, message = 'Incident created successfully', id = incident.id}
    end
end

-- Update incident
function MDT:UpdateIncident(source, data)
    local playerData = self:GetPlayerData(source)
    if not playerData then
        return {success = false, message = 'Player data not found'}
    end
    
    if Config.Database.useOxmysql then
        local result = MySQL.update.await('UPDATE mdt_incidents SET status = ?, description = ? WHERE id = ?', {
            data.status,
            data.description,
            data.id
        })
        
        if result.affectedRows > 0 then
            return {success = true, message = 'Incident updated successfully'}
        else
            return {success = false, message = 'Failed to update incident'}
        end
    else
        -- Fallback to in-memory storage
        for i, incident in ipairs(self.Data.incidents) do
            if incident.id == data.id then
                incident.status = data.status
                incident.description = data.description
                incident.updated_at = os.date('%Y-%m-%d %H:%M:%S')
                return {success = true, message = 'Incident updated successfully'}
            end
        end
        
        return {success = false, message = 'Incident not found'}
    end
end

-- Create citizen
function MDT:CreateCitizen(source, data)
    local playerData = self:GetPlayerData(source)
    if not playerData then
        return {success = false, message = 'Player data not found'}
    end
    
    if Config.Database.useOxmysql then
        local result = MySQL.insert.await('INSERT INTO mdt_citizens (citizenid, firstname, lastname, dateofbirth, license, phone, address) VALUES (?, ?, ?, ?, ?, ?, ?)', {
            data.citizenid,
            data.firstname,
            data.lastname,
            data.dateofbirth,
            data.license,
            data.phone,
            data.address
        })
        
        if result then
            return {success = true, message = 'Citizen created successfully', id = result.insertId}
        else
            return {success = false, message = 'Failed to create citizen'}
        end
    else
        -- Fallback to in-memory storage
        local citizen = {
            id = #self.Data.citizens + 1,
            citizenid = data.citizenid,
            firstname = data.firstname,
            lastname = data.lastname,
            dateofbirth = data.dateofbirth,
            license = data.license,
            phone = data.phone,
            address = data.address,
            created_at = os.date('%Y-%m-%d %H:%M:%S')
        }
        
        self.Data.citizens[data.citizenid] = citizen
        return {success = true, message = 'Citizen created successfully', id = citizen.id}
    end
end

-- Update citizen
function MDT:UpdateCitizen(source, data)
    local playerData = self:GetPlayerData(source)
    if not playerData then
        return {success = false, message = 'Player data not found'}
    end
    
    if Config.Database.useOxmysql then
        local result = MySQL.update.await('UPDATE mdt_citizens SET firstname = ?, lastname = ?, dateofbirth = ?, license = ?, phone = ?, address = ? WHERE citizenid = ?', {
            data.firstname,
            data.lastname,
            data.dateofbirth,
            data.license,
            data.phone,
            data.address,
            data.citizenid
        })
        
        if result.affectedRows > 0 then
            return {success = true, message = 'Citizen updated successfully'}
        else
            return {success = false, message = 'Failed to update citizen'}
        end
    else
        -- Fallback to in-memory storage
        if self.Data.citizens[data.citizenid] then
            self.Data.citizens[data.citizenid].firstname = data.firstname
            self.Data.citizens[data.citizenid].lastname = data.lastname
            self.Data.citizens[data.citizenid].dateofbirth = data.dateofbirth
            self.Data.citizens[data.citizenid].license = data.license
            self.Data.citizens[data.citizenid].phone = data.phone
            self.Data.citizens[data.citizenid].address = data.address
            self.Data.citizens[data.citizenid].updated_at = os.date('%Y-%m-%d %H:%M:%S')
            return {success = true, message = 'Citizen updated successfully'}
        else
            return {success = false, message = 'Citizen not found'}
        end
    end
end

-- Create vehicle
function MDT:CreateVehicle(source, data)
    local playerData = self:GetPlayerData(source)
    if not playerData then
        return {success = false, message = 'Player data not found'}
    end
    
    if Config.Database.useOxmysql then
        local result = MySQL.insert.await('INSERT INTO mdt_vehicles (plate, model, owner_citizenid, vin, insurance_status, registration_status) VALUES (?, ?, ?, ?, ?, ?)', {
            data.plate,
            data.model,
            data.owner_citizenid,
            data.vin,
            data.insurance_status or 'active',
            data.registration_status or 'valid'
        })
        
        if result then
            return {success = true, message = 'Vehicle created successfully', id = result.insertId}
        else
            return {success = false, message = 'Failed to create vehicle'}
        end
    else
        -- Fallback to in-memory storage
        local vehicle = {
            id = #self.Data.vehicles + 1,
            plate = data.plate,
            model = data.model,
            owner_citizenid = data.owner_citizenid,
            vin = data.vin,
            insurance_status = data.insurance_status or 'active',
            registration_status = data.registration_status or 'valid',
            created_at = os.date('%Y-%m-%d %H:%M:%S')
        }
        
        self.Data.vehicles[data.plate] = vehicle
        return {success = true, message = 'Vehicle created successfully', id = vehicle.id}
    end
end

-- Update vehicle
function MDT:UpdateVehicle(source, data)
    local playerData = self:GetPlayerData(source)
    if not playerData then
        return {success = false, message = 'Player data not found'}
    end
    
    if Config.Database.useOxmysql then
        local result = MySQL.update.await('UPDATE mdt_vehicles SET model = ?, owner_citizenid = ?, vin = ?, insurance_status = ?, registration_status = ? WHERE plate = ?', {
            data.model,
            data.owner_citizenid,
            data.vin,
            data.insurance_status,
            data.registration_status,
            data.plate
        })
        
        if result.affectedRows > 0 then
            return {success = true, message = 'Vehicle updated successfully'}
        else
            return {success = false, message = 'Failed to update vehicle'}
        end
    else
        -- Fallback to in-memory storage
        if self.Data.vehicles[data.plate] then
            self.Data.vehicles[data.plate].model = data.model
            self.Data.vehicles[data.plate].owner_citizenid = data.owner_citizenid
            self.Data.vehicles[data.plate].vin = data.vin
            self.Data.vehicles[data.plate].insurance_status = data.insurance_status
            self.Data.vehicles[data.plate].registration_status = data.registration_status
            self.Data.vehicles[data.plate].updated_at = os.date('%Y-%m-%d %H:%M:%S')
            return {success = true, message = 'Vehicle updated successfully'}
        else
            return {success = false, message = 'Vehicle not found'}
        end
    end
end

-- Get player data
function MDT:GetPlayerData(source)
    local playerData = Framework.GetPlayerData(source)
    if not playerData then
        return nil
    end
    
    if Framework.Type == 'qb' or Framework.Type == 'qbx' then
        return {
            citizenid = playerData.citizenid,
            firstname = playerData.charinfo?.firstname,
            lastname = playerData.charinfo?.lastname,
            job = playerData.job?.name,
            grade = playerData.job?.grade?.level
        }
    elseif Framework.Type == 'esx' then
        return {
            citizenid = playerData.identifier,
            firstname = playerData.firstName,
            lastname = playerData.lastName,
            job = playerData.job?.name,
            grade = playerData.job?.grade
        }
    end
    
    return nil
end

-- Notify all officers
function MDT:NotifyOfficers(message, type)
    for source, _ in pairs(self.Players) do
        local playerData = self:GetPlayerData(source)
        if playerData and self:CheckJobPermission(playerData.job) then
            TriggerClientEvent('mdt:notification', source, message, type)
        end
    end
end

-- Check job permission
function MDT:CheckJobPermission(job)
    for _, allowedJob in ipairs(Config.Jobs.allowedJobs) do
        if job == allowedJob then
            return true
        end
    end
    return false
end

-- Initialize MDT Server
CreateThread(function()
    MDT:Init()
end)
