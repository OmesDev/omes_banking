local Framework = nil
local FrameworkName = Config.Framework

if FrameworkName == 'esx' then
    Framework = exports['es_extended']:getSharedObject()
elseif FrameworkName == 'qb' then
    Framework = exports['qb-core']:GetCoreObject()
elseif FrameworkName == 'qbx' then
    Framework = exports.qbx_core
end


local function ShowNotification(message, type)
    if Config.NotificationType == 'ox' or Config.NotificationType == 'qbx' then
        exports.ox_lib:notify({
            title = 'Banking',
            description = message,
            type = type or 'info',
            duration = 5000
        })
    elseif Config.NotificationType == 'esx' then
        Framework.ShowNotification(message)
    elseif Config.NotificationType == 'qb' then
        Framework.Functions.Notify(message, type or 'primary', 5000)
    end
end

local function ShowHelpNotification(message)
    if FrameworkName == 'esx' then
        Framework.ShowHelpNotification(message)
    elseif FrameworkName == 'qb' then
        if exports['qb-core'] and exports['qb-core'].DrawText then
            exports['qb-core']:DrawText(message, 'left')
        else
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName(message)
            EndTextCommandDisplayHelp(0, false, true, -1)
        end
    elseif FrameworkName == 'qbx' then
        lib.showTextUI(message)
    end
    isShowingHelpText = true
end

local function HideHelpNotification()
    if isShowingHelpText then
        if FrameworkName == 'qb' then
            if exports['qb-core'] and exports['qb-core'].HideText then
                exports['qb-core']:HideText()
            end
        elseif FrameworkName == 'qbx' then
            lib.hideTextUI()
        end
        isShowingHelpText = false
    end
end

local function TriggerServerCallback(name, callback, ...)
    if FrameworkName == 'esx' then
        Framework.TriggerServerCallback(name, callback, ...)
    elseif FrameworkName == 'qb' then
        Framework.Functions.TriggerCallback(name, callback, ...)
    elseif FrameworkName == 'qbx' then
        lib.callback(name, false, callback, ...)
    end
end

local bankerPed = nil
local bankingOpen = false
local nearbyATMs = {}
local isUsingATM = false
local isShowingHelpText = false

function CreateBankerPeds()
    if not Config.BankerPed.enabled then return end
    
    local pedModel = GetHashKey(Config.BankerPed.model)
    
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do
        Wait(1)
    end
    
    for i, bank in pairs(Config.BankLocations) do
        local ped = CreatePed(4, pedModel, bank.coords.x, bank.coords.y, bank.coords.z - 1.0, bank.coords.w, false, true)
        
        SetEntityHeading(ped, bank.coords.w)
        
        if Config.BankerPed.freeze then
            FreezeEntityPosition(ped, true)
        end
        
        if Config.BankerPed.invincible then
            SetEntityInvincible(ped, true)
        end
        
        if Config.BankerPed.blockEvents then
            SetBlockingOfNonTemporaryEvents(ped, true)
        end
        
        SetEntityAsMissionEntity(ped, true, true)
        
        if Config.BankerPed.scenario then
            TaskStartScenarioInPlace(ped, Config.BankerPed.scenario, 0, true)
        end
        
        if not bankerPeds then bankerPeds = {} end
        bankerPeds[i] = ped
    end
    
    SetModelAsNoLongerNeeded(pedModel)
end

function DeleteBankerPeds()
    if bankerPeds then
        for _, ped in pairs(bankerPeds) do
            if DoesEntityExist(ped) then
                DeleteEntity(ped)
            end
        end
        bankerPeds = {}
    end
    
    if bankerPed and DoesEntityExist(bankerPed) then
        DeleteEntity(bankerPed)
        bankerPed = nil
    end
end



function OpenBankingUI()
    if bankingOpen then return end
    
    bankingOpen = true
    SetNuiFocus(true, true)
    
    TriggerServerCallback('omes_banking:getPlayerData', function(playerData)
        TriggerServerCallback('omes_banking:getTransactionHistory', function(transactions)
            TriggerServerCallback('omes_banking:getBalanceHistory', function(balanceHistory)
        SendNUIMessage({
            type = 'openBank',
            playerData = playerData,
                    bankName = Config.BankName,
                    transactions = transactions,
                    balanceHistory = balanceHistory
        })
            end)
        end)
    end)
end

function CloseBankingUI()
    if not bankingOpen then return end
    
    bankingOpen = false
    isUsingATM = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    
    SendNUIMessage({
        type = 'closeBank'
    })
end

function HandleATMAccess()
    isUsingATM = true
    
    TriggerServerCallback('omes_banking:getPlayerData', function(playerData)
        if not playerData.hasPin then
            ShowNotification('You need to set up a PIN at a bank first', 'error')
            isUsingATM = false
            return
        end

        SetNuiFocus(true, true)
        SendNUIMessage({
            type = 'showPinEntry',
            isATM = true
        })
    end)
end


function CreateBankBlips()
    if not Config.Blips.enabled then return end
    
    for _, bank in pairs(Config.BankLocations) do
        local blip = AddBlipForCoord(bank.coords.x, bank.coords.y, bank.coords.z)
        SetBlipSprite(blip, Config.Blips.sprite)
        SetBlipDisplay(blip, Config.Blips.display)
        SetBlipScale(blip, Config.Blips.scale)
        SetBlipColour(blip, Config.Blips.color)
        SetBlipAsShortRange(blip, Config.Blips.shortRange)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.BankName)
        EndTextCommandSetBlipName(blip)
    end
end




function ScanForNearbyATMs()
    if not Config.ATM.enabled then return end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    nearbyATMs = {}
    
    for _, model in pairs(Config.ATM.models) do
        local atmObject = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, 10.0, model, false, false, false)
        
        if atmObject ~= 0 then
            local atmCoords = GetEntityCoords(atmObject)
            local distance = #(playerCoords - atmCoords)
            
            if distance <= 10.0 then
                table.insert(nearbyATMs, {
                    object = atmObject,
                    coords = atmCoords,
                    distance = distance
                })
            end
        end
    end
end


RegisterNUICallback('closeBank', function(data, cb)
    CloseBankingUI()
    cb('ok')
end)

RegisterNUICallback('transfer', function(data, cb)
    TriggerServerEvent('omes_banking:transfer', data.recipient, data.amount, data.description)
    

    Citizen.Wait(500)
    TriggerServerCallback('omes_banking:getPlayerData', function(playerData)
        TriggerServerCallback('omes_banking:getTransactionHistory', function(transactions)
            TriggerServerCallback('omes_banking:getBalanceHistory', function(balanceHistory)
                SendNUIMessage({
                    type = 'updateBankingData',
                    playerData = playerData,
                    transactions = transactions,
                    balanceHistory = balanceHistory
                })
            end)
        end)
    end)
    
    cb('ok')
end)

RegisterNUICallback('deposit', function(data, cb)
    TriggerServerEvent('omes_banking:deposit', data.amount)
    

    Citizen.Wait(500)
    TriggerServerCallback('omes_banking:getPlayerData', function(playerData)
        TriggerServerCallback('omes_banking:getTransactionHistory', function(transactions)
            TriggerServerCallback('omes_banking:getBalanceHistory', function(balanceHistory)
                SendNUIMessage({
                    type = 'updateBankingData',
                    playerData = playerData,
                    transactions = transactions,
                    balanceHistory = balanceHistory
                })
            end)
        end)
    end)
    
    cb('ok')
end)

RegisterNUICallback('withdraw', function(data, cb)
    TriggerServerEvent('omes_banking:withdraw', data.amount)
    

    Citizen.Wait(500)
    TriggerServerCallback('omes_banking:getPlayerData', function(playerData)
        TriggerServerCallback('omes_banking:getTransactionHistory', function(transactions)
            TriggerServerCallback('omes_banking:getBalanceHistory', function(balanceHistory)
                SendNUIMessage({
                    type = 'updateBankingData',
                    playerData = playerData,
                    transactions = transactions,
                    balanceHistory = balanceHistory
                })
            end)
        end)
    end)
    
    cb('ok')
end)

RegisterNUICallback('openSavingsAccount', function(data, cb)
    TriggerServerEvent('omes_banking:openSavingsAccount')
    

    Citizen.Wait(1000)
    TriggerServerCallback('omes_banking:getPlayerData', function(playerData)
        TriggerServerCallback('omes_banking:getTransactionHistory', function(transactions)
            TriggerServerCallback('omes_banking:getBalanceHistory', function(balanceHistory)
                SendNUIMessage({
                    type = 'updateBankingData',
                    playerData = playerData,
                    transactions = transactions,
                    balanceHistory = balanceHistory
                })
            end)
        end)
    end)
    
    cb('ok')
end)

RegisterNUICallback('depositSavings', function(data, cb)
    TriggerServerEvent('omes_banking:depositSavings', data.amount)
    

    Citizen.Wait(500)
    TriggerServerCallback('omes_banking:getPlayerData', function(playerData)
        TriggerServerCallback('omes_banking:getTransactionHistory', function(transactions)
            TriggerServerCallback('omes_banking:getBalanceHistory', function(balanceHistory)
                SendNUIMessage({
                    type = 'updateBankingData',
                    playerData = playerData,
                    transactions = transactions,
                    balanceHistory = balanceHistory
                })
            end)
        end)
    end)
    
    cb('ok')
end)

RegisterNUICallback('withdrawSavings', function(data, cb)
    TriggerServerEvent('omes_banking:withdrawSavings', data.amount)
    

    Citizen.Wait(500)
    TriggerServerCallback('omes_banking:getPlayerData', function(playerData)
        TriggerServerCallback('omes_banking:getTransactionHistory', function(transactions)
            TriggerServerCallback('omes_banking:getBalanceHistory', function(balanceHistory)
                SendNUIMessage({
                    type = 'updateBankingData',
                    playerData = playerData,
                    transactions = transactions,
                    balanceHistory = balanceHistory
                })
            end)
        end)
    end)
    
    cb('ok')
end)

RegisterNUICallback('transferBetweenAccounts', function(data, cb)
    TriggerServerEvent('omes_banking:transferBetweenAccounts', data.fromAccount, data.toAccount, data.amount)
    

    Citizen.Wait(500)
    TriggerServerCallback('omes_banking:getPlayerData', function(playerData)
        TriggerServerCallback('omes_banking:getTransactionHistory', function(transactions)
            TriggerServerCallback('omes_banking:getBalanceHistory', function(balanceHistory)
                SendNUIMessage({
                    type = 'updateBankingData',
                    playerData = playerData,
                    transactions = transactions,
                    balanceHistory = balanceHistory
                })
            end)
        end)
    end)
    
    cb('ok')
end)

RegisterNUICallback('setupPin', function(data, cb)
    TriggerServerEvent('omes_banking:setupPin', data.pin)
    cb('ok')
end)

RegisterNUICallback('clearAllTransactions', function(data, cb)
    TriggerServerEvent('omes_banking:clearAllTransactions')
    cb('ok')
end)

RegisterNUICallback('getPlayerData', function(data, cb)

    TriggerServerCallback('omes_banking:getPlayerData', function(playerData)
        cb(playerData)
    end)
end)

RegisterNUICallback('closeSavingsAccount', function(data, cb)
    TriggerServerEvent('omes_banking:closeSavingsAccount')
    cb('ok')
end)


function OpenATMUI()
    if bankingOpen then return end
    
    bankingOpen = true
    TriggerServerCallback('omes_banking:getPlayerData', function(playerData)
        TriggerServerCallback('omes_banking:getTransactionHistory', function(transactions)
            TriggerServerCallback('omes_banking:getBalanceHistory', function(balanceHistory)
                SetNuiFocus(true, true)
                SendNUIMessage({
                    type = 'openBank',
                    playerData = playerData,
                    bankName = Config.BankName,
                    transactions = transactions,
                    balanceHistory = balanceHistory,
                    isATM = true
                })
            end)
        end)
    end)
end


RegisterNUICallback('verifyPin', function(data, cb)
    local wasUsingATM = isUsingATM
    
    TriggerServerCallback('omes_banking:verifyPin', function(isValid)
        if isValid then

            SendNUIMessage({
                type = 'pinVerificationSuccess'
            })
            

            isUsingATM = false
            

            if wasUsingATM then
                OpenATMUI()
            else
                OpenBankingUI()
            end
        else

            SendNUIMessage({
                type = 'pinVerificationFailed'
            })
        end
    end, data.pin)
    
    cb('ok')
end)


RegisterNUICallback('closePinEntry', function(data, cb)
    SetNuiFocus(false, false)
    isUsingATM = false
    cb('ok')
end)


RegisterNetEvent('omes_banking:pinSetupSuccess')
AddEventHandler('omes_banking:pinSetupSuccess', function(data)
    SendNUIMessage({
        type = 'pinSetupSuccess',
        pin = data.pin
    })
end)


RegisterNetEvent('omes_banking:savingsAccountClosed')
AddEventHandler('omes_banking:savingsAccountClosed', function()
    SendNUIMessage({
        type = 'savingsAccountClosed'
    })
end)


Citizen.CreateThread(function()
    if Config.Banking.enableBankerPed then
        CreateBankerPeds()
    end
    CreateBankBlips()
end)


AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        DeleteBankerPeds()
        if bankingOpen then
            CloseBankingUI()
        end
    end
end)


Citizen.CreateThread(function()
    while true do
        if bankingOpen then
            if IsControlJustReleased(0, 322) then
                CloseBankingUI()
            end
        end
        Wait(0)
    end
end)


Citizen.CreateThread(function()
    local lastATMScan = 0
    
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local canInteract = false
        

        if Config.Banking.enableBankerPed then
            for _, bank in pairs(Config.BankLocations) do
                local distance = #(playerCoords - vector3(bank.coords.x, bank.coords.y, bank.coords.z))
                
                if distance < Config.Interaction.distance then
                    sleep = 0
                    canInteract = true
                    ShowHelpNotification(Config.Interaction.helpText)
                    
                    if IsControlJustReleased(0, Config.Interaction.key) then
                        OpenBankingUI()
                        break
                    end
                end
            end
        end
        

        if Config.ATM.enabled and not canInteract then
            local currentTime = GetGameTimer()
            if currentTime - lastATMScan > 500 then
                ScanForNearbyATMs()
                lastATMScan = currentTime
            end
            
            for _, atm in pairs(nearbyATMs) do
                if atm.distance <= Config.ATM.interactionDistance then
                    sleep = 0
                    canInteract = true
                    ShowHelpNotification('Press [E] to use ATM')
                    
                    if IsControlJustReleased(0, Config.Interaction.key) then
                        HandleATMAccess()
                        break
                    end
                end
            end
        end
        

        if not canInteract then
            HideHelpNotification()
        end
        
        Wait(sleep)
    end
end)


