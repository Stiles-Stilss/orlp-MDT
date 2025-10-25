Config = {}

-- General Settings
Config.Debug = false
Config.Locale = 'en'
Config.UpdateInterval = 30000 -- 30 seconds

-- UI Settings
Config.UI = {
    theme = 'dark', -- 'dark', 'light', 'auto'
    animations = true,
    sounds = true,
    notifications = true,
    autoClose = false,
    keybind = 'F1' -- Key to open MDT
}

-- Framework Settings
Config.Framework = {
    autoDetect = true,
    type = 'qbx', -- 'qb', 'qbx', 'esx', 'auto'
    debugMode = false
}

-- Database Settings
Config.Database = {
    useOxmysql = true,
    connectionTimeout = 10000,
    queryTimeout = 5000
}

-- Security Settings
Config.Security = {
    enablePermissions = true,
    enableLogging = true,
    enableAuditTrail = true,
    maxLoginAttempts = 3,
    lockoutDuration = 300000 -- 5 minutes
}

-- MDT Features
Config.Features = {
    -- Core Features
    citizenLookup = true,
    vehicleLookup = true,
    incidentReports = true,
    arrestRecords = true,
    warrants = true,
    bolos = true,
    calls = true,
    
    -- Advanced Features
    evidenceManagement = true,
    caseManagement = true,
    reportGeneration = true,
    analytics = true,
    notifications = true,
    realTimeUpdates = true,
    
    -- Communication Features
    radioIntegration = true,
    chatIntegration = true,
    emergencyAlerts = true
}

-- Job Restrictions
Config.Jobs = {
    enabled = false,  -- Temporarily disabled for testing
    allowedJobs = {
        'police',
        'sheriff',
        'state',
        'fbi',
        'marshal',
        'corrections'
    },
    adminOverride = true
}

-- Grade Restrictions
Config.Grades = {
    enabled = true,
    minimumGrade = 0,
    restrictions = {
        ['police'] = {
            [0] = { -- Cadet
                citizenLookup = true,
                vehicleLookup = true,
                incidentReports = false,
                arrestRecords = false,
                warrants = false,
                bolos = false,
                calls = true
            },
            [1] = { -- Officer
                citizenLookup = true,
                vehicleLookup = true,
                incidentReports = true,
                arrestRecords = true,
                warrants = false,
                bolos = true,
                calls = true
            },
            [2] = { -- Senior Officer
                citizenLookup = true,
                vehicleLookup = true,
                incidentReports = true,
                arrestRecords = true,
                warrants = true,
                bolos = true,
                calls = true
            },
            [3] = { -- Sergeant
                citizenLookup = true,
                vehicleLookup = true,
                incidentReports = true,
                arrestRecords = true,
                warrants = true,
                bolos = true,
                calls = true,
                evidenceManagement = true,
                caseManagement = true
            },
            [4] = { -- Lieutenant
                citizenLookup = true,
                vehicleLookup = true,
                incidentReports = true,
                arrestRecords = true,
                warrants = true,
                bolos = true,
                calls = true,
                evidenceManagement = true,
                caseManagement = true,
                reportGeneration = true,
                analytics = true
            },
            [5] = { -- Captain
                citizenLookup = true,
                vehicleLookup = true,
                incidentReports = true,
                arrestRecords = true,
                warrants = true,
                bolos = true,
                calls = true,
                evidenceManagement = true,
                caseManagement = true,
                reportGeneration = true,
                analytics = true,
                adminOverride = true
            }
        }
    }
}

-- Notification Settings
Config.Notifications = {
    enabled = true,
    types = {
        success = { color = '#4CAF50', icon = 'check-circle' },
        error = { color = '#F44336', icon = 'times-circle' },
        warning = { color = '#FF9800', icon = 'exclamation-triangle' },
        info = { color = '#2196F3', icon = 'info-circle' }
    },
    position = 'top-right',
    duration = 5000
}

-- API Settings
Config.API = {
    enabled = true,
    rateLimit = {
        enabled = true,
        maxRequests = 100,
        timeWindow = 60000 -- 1 minute
    },
    endpoints = {
        citizen = '/api/citizen',
        vehicle = '/api/vehicle',
        incident = '/api/incident',
        warrant = '/api/warrant',
        bolo = '/api/bolo',
        call = '/api/call'
    }
}

-- Logging Settings
Config.Logging = {
    enabled = true,
    level = 'info', -- 'debug', 'info', 'warn', 'error'
    file = 'mdt.log',
    maxSize = '10MB',
    maxFiles = 5,
    console = true
}

-- Performance Settings
Config.Performance = {
    enableCaching = true,
    cacheTimeout = 300000, -- 5 minutes
    maxCacheSize = 1000,
    enableCompression = true,
    enableMinification = true
}

-- Customization Settings
Config.Customization = {
    enableThemes = true,
    enableCustomCSS = true,
    enableCustomJS = true,
    defaultTheme = 'police-blue',
    themes = {
        ['police-blue'] = {
            primary = '#1976D2',
            secondary = '#42A5F5',
            accent = '#FFC107',
            background = '#121212',
            surface = '#1E1E1E',
            text = '#FFFFFF'
        },
        ['sheriff-brown'] = {
            primary = '#8D6E63',
            secondary = '#A1887F',
            accent = '#FF9800',
            background = '#121212',
            surface = '#1E1E1E',
            text = '#FFFFFF'
        },
        ['fbi-dark'] = {
            primary = '#424242',
            secondary = '#616161',
            accent = '#FF5722',
            background = '#000000',
            surface = '#1A1A1A',
            text = '#FFFFFF'
        }
    }
}
