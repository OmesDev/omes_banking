Config = {}

-- Framework Settings
Config.Framework = 'qb' -- Options: 'esx', 'qb', 'qbx'

-- Notification Settings
Config.NotificationType = 'ox' -- Options: 'esx', 'ox', 'qb' (IF USING QBX USE 'ox')

-- General Settings
Config.Locale = 'en'
Config.BankName = 'Fleeca Bank' -- Configurable bank name displayed in UI

-- Blip Configuration
Config.Blips = {
    enabled = true,
    sprite = 108, 
    color = 2, 
    scale = 0.8,
    name = "Bank",
    shortRange = true, 
    display = 4 
}

-- Banker Ped Configuration
Config.BankerPed = {
    enabled = true,
    model = "cs_bankman",
    scenario = "WORLD_HUMAN_CLIPBOARD", 
    invincible = true,
    freeze = true,
    blockEvents = true
}

-- Interaction Settings
Config.Interaction = {
    distance = 3.0, -- Distance to show interaction prompt
    key = 38, -- E key
    helpText = 'Press [E] to access banking',
    accessText = 'Banking system accessed!'
}

-- Banking Settings
Config.Banking = {
    enableATM = true,
    enableBankerPed = true,
    enableNUI = true,
    defaultAccount = 'bank',
    maxTransferAmount = 1000000,
    minTransferAmount = 1,
    transferFee = 0, -- Percentage fee for transfers (0 = no fee)
    enableTransactionHistory = true,
    maxHistoryEntries = 50
}

-- Discord Webhook Logging
Config.DiscordLogging = {
    enabled = true, -- Set to false to disable Discord logging
    webhook = "", -- Your Discord webhook URL here
    botName = "Banking System",
    botAvatar = "https://i.ibb.co/Q7ddTp9S/images.png", -- Custom avatar URL
    color = {
        deposit = 3066993, 
        withdrawal = 15158332, 
        transfer = 3447003, 
        savings = 10181046, 
        admin = 15844367, 
        error = 15158332 
    },
    logEvents = {
        deposits = true,
        withdrawals = true,
        transfers = true,
        savingsOperations = true,
        accountOperations = true, 
        historyClearing = true,
        pinOperations = true,
        adminActions = true
    }
}

-- ATM Configuration
Config.ATM = {
    enabled = true,
    models = {
        `prop_fleeca_atm`,
        `prop_atm_01`,
        `prop_atm_02`,
        `prop_atm_03`
    },
    interactionDistance = 2.0
}

-- Bank Locations
Config.BankLocations = {
    {
        coords = vector4(149.4113, -1042.0449, 29.3680, 342.9182) -- Legion Square
    },
    {
        coords = vector4(-1211.8585, -331.9854, 37.7809, 28.5983) -- Rockford Hills
    },
    {
        coords = vector4(-2961.0720, 483.1107, 15.6970, 88.1986) -- Great Ocean Highway
    },
    {
        coords = vector4(-112.2223, 6471.1128, 31.6267, 132.7517) -- Paleto Bay
    },
    {
        coords = vector4(313.8176, -280.5338, 54.1647, 339.1609) -- Pillbox Hill
    },
    {
        coords = vector4(-351.3247, -51.3466, 49.0365, 339.3305) -- Burton
    },
    {
        coords = vector4(1174.9718, 2708.2034, 38.0879, 178.2974) -- Sandy Shores
    },
    {
        coords = vector4(247.0348, 225.1851, 106.2875, 158.7528) -- Vinewood
    }
}
