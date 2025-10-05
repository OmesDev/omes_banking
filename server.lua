local Framework = nil
local FrameworkName = Config.Framework

if FrameworkName == 'esx' then
    Framework = exports['es_extended']:getSharedObject()
elseif FrameworkName == 'qb' then
    Framework = exports['qb-core']:GetCoreObject()
end

-- Translation function
local function GetTranslation(key, ...)
    local lang = Config.DefaultLanguage or 'en'
    local translations = Config.Translations[lang] or Config.Translations['en']
    local translation = translations[key] or Config.Translations['en'][key] or key
    
    -- Handle string formatting if arguments are provided
    if ... then
        return string.format(translation, ...)
    end
    
    return translation
end


local function GetPlayer(source)
    if FrameworkName == 'esx' then
        return Framework.GetPlayerFromId(source)
    elseif FrameworkName == 'qb' then
        return Framework.Functions.GetPlayer(source)
    end
end

local function GetPlayerIdentifier(player)
    if FrameworkName == 'esx' then
        return player.identifier
    elseif FrameworkName == 'qb' then
        return player.PlayerData.citizenid
    end
end

local function GetPlayerName(player)
    if FrameworkName == 'esx' then
        return player.getName()
    elseif FrameworkName == 'qb' then
        return player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    end
end

local function GetPlayerCash(player)
    if FrameworkName == 'esx' then
        return player.getMoney()
    elseif FrameworkName == 'qb' then
        return player.PlayerData.money.cash
    end
end

local function GetPlayerBank(player)
    if FrameworkName == 'esx' then
        return player.getAccount('bank').money
    elseif FrameworkName == 'qb' then
        return player.PlayerData.money.bank
    end
end

local function AddPlayerCash(player, amount)
    if FrameworkName == 'esx' then
        player.addMoney(amount)
    elseif FrameworkName == 'qb' then
        player.Functions.AddMoney('cash', amount)
    end
end

local function RemovePlayerCash(player, amount)
    if FrameworkName == 'esx' then
        player.removeMoney(amount)
    elseif FrameworkName == 'qb' then
        player.Functions.RemoveMoney('cash', amount)
    end
end

local function AddPlayerBank(player, amount)
    if FrameworkName == 'esx' then
        player.addAccountMoney('bank', amount)
    elseif FrameworkName == 'qb' then
        player.Functions.AddMoney('bank', amount)
    end
end

local function RemovePlayerBank(player, amount)
    if FrameworkName == 'esx' then
        player.removeAccountMoney('bank', amount)
    elseif FrameworkName == 'qb' then
        player.Functions.RemoveMoney('bank', amount)
    end
end

local function RegisterCallback(name, callback)
    if FrameworkName == 'esx' then
        Framework.RegisterServerCallback(name, callback)
    elseif FrameworkName == 'qb' then
        Framework.Functions.CreateCallback(name, callback)
    end
end

local function RegisterCommand(name, permission, callback, restricted, suggestion)
    if FrameworkName == 'esx' then
        Framework.RegisterCommand(name, permission, callback, restricted, suggestion)
    elseif FrameworkName == 'qb' then
        Framework.Commands.Add(name, suggestion.help, {}, restricted, callback, permission)
    end
end

local function FormatMoney(amount)
    if FrameworkName == 'esx' then
        return Framework.Math.GroupDigits(amount)
    elseif FrameworkName == 'qb' then
        local formatted = tostring(amount)
        local k
        while true do
            formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
            if k == 0 then
                break
            end
        end
        return formatted
    end
end


function SendNotification(source, message, type)
    type = type or 'info'
    
    if Config.NotificationType == 'ox' then

        TriggerClientEvent('ox_lib:notify', source, {
            title = GetTranslation('bank_name'),
            description = message,
            type = type,
            duration = 5000
        })
    elseif Config.NotificationType == 'esx' then

        TriggerClientEvent('esx:showNotification', source, message)
    elseif Config.NotificationType == 'qb' then

        TriggerClientEvent('QBCore:Notify', source, message, type, 5000)
    end
end


function SendDiscordLog(logType, title, description, fields, color)
    if not Config.DiscordLogging.enabled or not Config.DiscordLogging.webhook or Config.DiscordLogging.webhook == "" then
        return
    end
    

    if not Config.DiscordLogging.logEvents[logType] then
        return
    end
    
    local embed = {
        {
            ["title"] = title,
            ["description"] = description,
            ["type"] = "rich",
            ["color"] = color or Config.DiscordLogging.color.admin,
            ["fields"] = fields or {},
            ["footer"] = {
                ["text"] = "Banking System • " .. os.date("%Y-%m-%d %H:%M:%S"),
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
    
    local payload = {
        ["username"] = Config.DiscordLogging.botName,
        ["avatar_url"] = Config.DiscordLogging.botAvatar,
        ["embeds"] = embed
    }
    
    PerformHttpRequest(Config.DiscordLogging.webhook, function(err, text, headers) end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json'
    })
end


RegisterCallback('omes_banking:getPlayerData', function(source, cb)
    local xPlayer = GetPlayer(source)
    if not xPlayer then return cb(nil) end
    
    local identifier = GetPlayerIdentifier(xPlayer)
    

    MySQL.Async.fetchScalar('SELECT balance FROM banking_savings WHERE identifier = @identifier AND status = "active"', {
        ['@identifier'] = identifier
    }, function(savingsBalance)

        MySQL.Async.fetchScalar('SELECT status FROM banking_savings WHERE identifier = @identifier', {
            ['@identifier'] = identifier
        }, function(savingsStatus)

            MySQL.Async.fetchScalar('SELECT pin FROM banking_pins WHERE identifier = @identifier', {
                ['@identifier'] = identifier
            }, function(pin)
                local playerData = {
                    name = GetPlayerName(xPlayer),
                    balance = GetPlayerBank(xPlayer),
                    accountNumber = '****-****-' .. string.sub(identifier, -4),
                    savingsBalance = Config.Banking.allowSavingsAccounts and (savingsBalance or 0) or 0,
                    savingsAccountNumber = '****-****-' .. string.sub(identifier, -4):reverse(),
                    hasSavingsAccount = Config.Banking.allowSavingsAccounts and (savingsStatus == 'active') or false,
                    hasPin = pin ~= nil,
                    pin = pin,
                    allowSavingsAccounts = Config.Banking.allowSavingsAccounts
                }
                
                cb(playerData)
            end)
        end)
    end)
end)


RegisterCallback('omes_banking:getTransactionHistory', function(source, cb)
    local xPlayer = GetPlayer(source)
    if not xPlayer then return cb({}) end
    
    local identifier = GetPlayerIdentifier(xPlayer)
    
    MySQL.Async.fetchAll('SELECT * FROM banking_transactions WHERE identifier = @identifier ORDER BY date DESC LIMIT @limit', {
        ['@identifier'] = identifier,
        ['@limit'] = Config.Banking.maxHistoryEntries or 50
    }, function(result)
        local transactions = {}
        for i = 1, #result do
            local transaction = result[i]
            table.insert(transactions, {
                id = transaction.id,
                type = transaction.type,
                description = transaction.description,
                amount = transaction.amount,
                date = transaction.date
            })
        end
        cb(transactions)
    end)
end)


RegisterCallback('omes_banking:getBalanceHistory', function(source, cb)
    local xPlayer = GetPlayer(source)
    if not xPlayer then return cb({}) end
    
    local identifier = GetPlayerIdentifier(xPlayer)
    

    MySQL.Async.fetchAll('SELECT * FROM banking_transactions WHERE identifier = @identifier AND date >= DATE_SUB(NOW(), INTERVAL 7 DAY) ORDER BY date ASC', {
        ['@identifier'] = identifier
    }, function(result)
        local balanceHistory = {}
        local currentBalance = GetPlayerBank(xPlayer)
        

        local days = {}
        for i = 6, 0, -1 do
            local date = os.date('%Y-%m-%d', os.time() - (i * 24 * 60 * 60))
            table.insert(days, date)
        end
        

        if #result == 0 then
            for _, date in ipairs(days) do
                table.insert(balanceHistory, {
                    date = date,
                    balance = currentBalance
                })
            end
            return cb(balanceHistory)
        end
        

        local tempBalance = currentBalance
        

        for i = #result, 1, -1 do
            local transaction = result[i]
            if transaction.type == 'deposit' or transaction.type == 'transfer_in' then
                tempBalance = tempBalance - transaction.amount
            elseif transaction.type == 'withdrawal' or transaction.type == 'transfer_out' or transaction.type == 'fee' then
                tempBalance = tempBalance + transaction.amount
            end
        end
        
        local startBalance = tempBalance
        

        local transactionsByDate = {}
        local runningBalance = startBalance
        
        for i = 1, #result do
            local transaction = result[i]
            local transactionDate = string.sub(transaction.date, 1, 10)
            

            if transaction.type == 'deposit' or transaction.type == 'transfer_in' then
                runningBalance = runningBalance + transaction.amount
            elseif transaction.type == 'withdrawal' or transaction.type == 'transfer_out' or transaction.type == 'fee' then
                runningBalance = runningBalance - transaction.amount
            end
            

            transactionsByDate[transactionDate] = runningBalance
        end
        

        local lastKnownBalance = startBalance
        for _, date in ipairs(days) do
            if transactionsByDate[date] then
                lastKnownBalance = transactionsByDate[date]
            end
            
            table.insert(balanceHistory, {
                date = date,
                balance = lastKnownBalance
            })
        end
        
        balanceHistory[#balanceHistory].balance = currentBalance
        
        cb(balanceHistory)
    end)
end)

RegisterServerEvent('omes_banking:deposit')
AddEventHandler('omes_banking:deposit', function(amount)
    local source = source
    local xPlayer = GetPlayer(source)
    
    if not xPlayer then return end
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        SendNotification(source, GetTranslation('invalid_amount'), 'error')
        return
    end
    
    if amount > Config.Banking.maxTransferAmount then
        SendNotification(source, GetTranslation('maximum_amount', FormatMoney(Config.Banking.maxTransferAmount)), 'error')
        return
    end
    
    local cashMoney = GetPlayerCash(xPlayer)
    if cashMoney < amount then
        SendNotification(source, GetTranslation('insufficient_funds'), 'error')
        return
    end
    
    RemovePlayerCash(xPlayer, amount)
    AddPlayerBank(xPlayer, amount)
    
    SendNotification(source, GetTranslation('transaction_completed'), 'success')
    
    LogTransaction(GetPlayerIdentifier(xPlayer), 'deposit', amount, GetTranslation('deposit'))
    
    SendDiscordLog('deposits', '💰 Cash Deposit', 
        'A player has made a cash deposit to their bank account.',
        {
            {
                ["name"] = "Player",
                ["value"] = GetPlayerName(xPlayer) .. ' (' .. source .. ')',
                ["inline"] = true
            },
            {
                ["name"] = "Amount",
                ["value"] = '$' .. FormatMoney(amount),
                ["inline"] = true
            },
            {
                ["name"] = "New Balance",
                ["value"] = '$' .. FormatMoney(GetPlayerBank(xPlayer)),
                ["inline"] = true
            }
        },
        Config.DiscordLogging.color.deposit
    )
end)

RegisterServerEvent('omes_banking:withdraw')
AddEventHandler('omes_banking:withdraw', function(amount)
    local source = source
    local xPlayer = GetPlayer(source)
    
    if not xPlayer then return end
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        SendNotification(source, GetTranslation('invalid_amount'), 'error')
        return
    end
    
    if amount > Config.Banking.maxTransferAmount then
        SendNotification(source, GetTranslation('maximum_amount', FormatMoney(Config.Banking.maxTransferAmount)), 'error')
        return
    end
    
    local bankMoney = GetPlayerBank(xPlayer)
    if bankMoney < amount then
        SendNotification(source, GetTranslation('insufficient_funds'), 'error')
        return
    end
    
    RemovePlayerBank(xPlayer, amount)
    AddPlayerCash(xPlayer, amount)
    
    SendNotification(source, GetTranslation('transaction_completed'), 'success')
    
    LogTransaction(GetPlayerIdentifier(xPlayer), 'withdrawal', amount, GetTranslation('withdraw'))
    
    SendDiscordLog('withdrawals', '💸 Cash Withdrawal', 
        'A player has withdrawn cash from their bank account.',
        {
            {
                ["name"] = "Player",
                ["value"] = GetPlayerName(xPlayer) .. ' (' .. source .. ')',
                ["inline"] = true
            },
            {
                ["name"] = "Amount",
                ["value"] = '$' .. FormatMoney(amount),
                ["inline"] = true
            },
            {
                ["name"] = "Remaining Balance",
                ["value"] = '$' .. FormatMoney(GetPlayerBank(xPlayer)),
                ["inline"] = true
            }
        },
        Config.DiscordLogging.color.withdrawal
    )
end)

RegisterServerEvent('omes_banking:transfer')
AddEventHandler('omes_banking:transfer', function(targetId, amount, description)
    local source = source
    local xPlayer = GetPlayer(source)
    local xTarget = GetPlayer(targetId)
    
    if not xPlayer then return end
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        SendNotification(source, GetTranslation('invalid_amount'), 'error')
        return
    end
    
    if amount < Config.Banking.minTransferAmount then
        SendNotification(source, 'Amount below minimum limit', 'error')
        return
    end
    
    if amount > Config.Banking.maxTransferAmount then
        SendNotification(source, GetTranslation('maximum_amount', FormatMoney(Config.Banking.maxTransferAmount)), 'error')
        return
    end
    
    if not xTarget then
        SendNotification(source, GetTranslation('player_not_found'), 'error')
        return
    end
    
    if source == targetId then
        SendNotification(source, GetTranslation('self_transfer'), 'error')
        return
    end
    
    local bankMoney = GetPlayerBank(xPlayer)
    local transferFee = math.floor(amount * (Config.Banking.transferFee / 100))
    local totalAmount = amount + transferFee
    
    if bankMoney < totalAmount then
        SendNotification(source, 'Insufficient funds (including fee)', 'error')
        return
    end
    
    RemovePlayerBank(xPlayer, totalAmount)
    AddPlayerBank(xTarget, amount)
    
    local senderMsg = 'Transferred $' .. FormatMoney(amount) .. ' to ' .. GetPlayerName(xTarget)
    if transferFee > 0 then
        senderMsg = senderMsg .. ' (Fee: $' .. FormatMoney(transferFee) .. ')'
    end
    
    SendNotification(source, senderMsg, 'success')
    SendNotification(targetId, 'Received $' .. FormatMoney(amount) .. ' from ' .. GetPlayerName(xPlayer), 'success')
    
    LogTransaction(GetPlayerIdentifier(xPlayer), 'transfer_out', amount, GetTranslation('transfer') .. ' ' .. GetPlayerName(xTarget) .. ': ' .. (description or GetTranslation('transfer')))
    LogTransaction(GetPlayerIdentifier(xTarget), 'transfer_in', amount, GetTranslation('transfer') .. ' ' .. GetPlayerName(xPlayer) .. ': ' .. (description or GetTranslation('transfer')))
    
    SendDiscordLog('transfers', '💳 Bank Transfer', 
        'A player has transferred money to another player.',
        {
            {
                ["name"] = "From",
                ["value"] = GetPlayerName(xPlayer) .. ' (' .. source .. ')',
                ["inline"] = true
            },
            {
                ["name"] = "To",
                ["value"] = GetPlayerName(xTarget) .. ' (' .. targetId .. ')',
                ["inline"] = true
            },
            {
                ["name"] = "Amount",
                ["value"] = '$' .. FormatMoney(amount),
                ["inline"] = true
            },
            {
                ["name"] = "Transfer Fee",
                ["value"] = '$' .. FormatMoney(transferFee),
                ["inline"] = true
            },
            {
                ["name"] = "Description",
                ["value"] = description or 'No description provided',
                ["inline"] = false
            },
            {
                ["name"] = "Sender's New Balance",
                ["value"] = '$' .. FormatMoney(GetPlayerBank(xPlayer)),
                ["inline"] = true
            },
            {
                ["name"] = "Recipient's New Balance",
                ["value"] = '$' .. FormatMoney(GetPlayerBank(xTarget)),
                ["inline"] = true
            }
        },
        Config.DiscordLogging.color.transfer
    )
    
    if transferFee > 0 then
        LogTransaction(GetPlayerIdentifier(xPlayer), 'fee', transferFee, GetTranslation('transfer_fee', FormatMoney(transferFee)))
    end
end)

function LogTransaction(identifier, type, amount, description)
    if not Config.Banking.enableTransactionHistory then return end
    

    MySQL.Async.execute('INSERT INTO banking_transactions (identifier, type, amount, description, date) VALUES (@identifier, @type, @amount, @description, NOW())', {
        ['@identifier'] = identifier,
        ['@type'] = type,
        ['@amount'] = amount,
        ['@description'] = description
    }, function(rowsChanged)
        if rowsChanged > 0 then
            print(string.format('[BANKING] Transaction logged: %s - %s: $%s - %s', identifier, type, amount, description))
        end
    end)
end


if FrameworkName == 'esx' then
    RegisterCommand('bank', 'user', function(xPlayer, args, showError)
        TriggerClientEvent('omes_banking:openUI', xPlayer.source)
    end, false, {help = 'Open banking interface'})
elseif FrameworkName == 'qb' then
    Framework.Commands.Add('bank', 'Open banking interface', {}, false, function(source, args)
        TriggerClientEvent('omes_banking:openUI', source)
    end, 'user')
end


RegisterServerEvent('omes_banking:openSavingsAccount')
AddEventHandler('omes_banking:openSavingsAccount', function()
    local source = source
    local xPlayer = GetPlayer(source)
    
    if not xPlayer then return end
    
    -- Check if savings accounts are enabled in config
    if not Config.Banking.allowSavingsAccounts then
        SendNotification(source, 'Savings accounts are currently disabled', 'error')
        return
    end
    
    local identifier = GetPlayerIdentifier(xPlayer)
    

    MySQL.Async.fetchScalar('SELECT status FROM banking_savings WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(status)
        if status == 'active' then
            SendNotification(source, 'You already have an active savings account', 'error')
            return
        end
        
        if status == 'inactive' then

            MySQL.Async.execute('UPDATE banking_savings SET status = "active" WHERE identifier = @identifier', {
                ['@identifier'] = identifier
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    SendNotification(source, 'Savings account reactivated successfully!', 'success')
                    LogTransaction(identifier, 'savings_opened', 0, GetTranslation('savings_created'))
                    

                    SendDiscordLog('accountOperations', '🏦 Savings Account Reactivated', 
                        'A player has reactivated their savings account.',
                        {
                            {
                                ["name"] = "Player",
                                ["value"] = GetPlayerName(xPlayer) .. ' (' .. source .. ')',
                                ["inline"] = true
                            },
                            {
                                ["name"] = "Action",
                                ["value"] = "Account Reactivated",
                                ["inline"] = true
                            }
                        },
                        Config.DiscordLogging.color.savings
                    )
                end
            end)
        else

            MySQL.Async.execute('INSERT INTO banking_savings (identifier, balance, status) VALUES (@identifier, 0, "active")', {
                ['@identifier'] = identifier
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    SendNotification(source, 'Savings account opened successfully!', 'success')
                    LogTransaction(identifier, 'savings_opened', 0, GetTranslation('savings_created'))
                    

                    SendDiscordLog('accountOperations', '🏦 New Savings Account Opened', 
                        'A player has opened a new savings account.',
                        {
                            {
                                ["name"] = "Player",
                                ["value"] = GetPlayerName(xPlayer) .. ' (' .. source .. ')',
                                ["inline"] = true
                            },
                            {
                                ["name"] = "Action",
                                ["value"] = "New Account Created",
                                ["inline"] = true
                            }
                        },
                        Config.DiscordLogging.color.savings
                    )
                end
            end)
        end
    end)
end)


RegisterServerEvent('omes_banking:depositSavings')
AddEventHandler('omes_banking:depositSavings', function(amount)
    local source = source
    local xPlayer = GetPlayer(source)
    
    if not xPlayer then return end
    
    -- Check if savings accounts are enabled in config
    if not Config.Banking.allowSavingsAccounts then
        SendNotification(source, 'Savings accounts are currently disabled', 'error')
        return
    end
    
    local identifier = GetPlayerIdentifier(xPlayer)
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        SendNotification(source, GetTranslation('invalid_amount'), 'error')
        return
    end
    
    if amount > Config.Banking.maxTransferAmount then
        SendNotification(source, GetTranslation('maximum_amount', FormatMoney(Config.Banking.maxTransferAmount)), 'error')
        return
    end
    

    MySQL.Async.fetchScalar('SELECT status FROM banking_savings WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(status)
        if status ~= 'active' then
            SendNotification(source, 'You need to open a savings account first', 'error')
            return
        end
        
        local bankMoney = GetPlayerBank(xPlayer)
        if bankMoney < amount then
            SendNotification(source, 'Insufficient funds in checking account', 'error')
            return
        end
        

        RemovePlayerBank(xPlayer, amount)
        
        MySQL.Async.execute('UPDATE banking_savings SET balance = balance + @amount WHERE identifier = @identifier', {
            ['@identifier'] = identifier,
            ['@amount'] = amount
        }, function(rowsChanged)
            if rowsChanged > 0 then
                SendNotification(source, 'Deposited $' .. FormatMoney(amount) .. ' to savings account', 'success')
                LogTransaction(identifier, 'savings_deposit', amount, GetTranslation('deposit_savings'))
            end
        end)
    end)
end)


RegisterServerEvent('omes_banking:withdrawSavings')
AddEventHandler('omes_banking:withdrawSavings', function(amount)
    local source = source
    local xPlayer = GetPlayer(source)
    
    if not xPlayer then return end
    
    -- Check if savings accounts are enabled in config
    if not Config.Banking.allowSavingsAccounts then
        SendNotification(source, 'Savings accounts are currently disabled', 'error')
        return
    end
    
    local identifier = GetPlayerIdentifier(xPlayer)
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        SendNotification(source, GetTranslation('invalid_amount'), 'error')
        return
    end
    
    if amount > Config.Banking.maxTransferAmount then
        SendNotification(source, GetTranslation('maximum_amount', FormatMoney(Config.Banking.maxTransferAmount)), 'error')
        return
    end
    

    MySQL.Async.fetchScalar('SELECT balance FROM banking_savings WHERE identifier = @identifier AND status = "active"', {
        ['@identifier'] = identifier
    }, function(savingsBalance)
        if not savingsBalance then
            SendNotification(source, 'You need to open a savings account first', 'error')
            return
        end
        
        if savingsBalance < amount then
            SendNotification(source, 'Insufficient funds in savings account', 'error')
            return
        end
        

        MySQL.Async.execute('UPDATE banking_savings SET balance = balance - @amount WHERE identifier = @identifier', {
            ['@identifier'] = identifier,
            ['@amount'] = amount
        }, function(rowsChanged)
            if rowsChanged > 0 then
                AddPlayerBank(xPlayer, amount)
                SendNotification(source, 'Transferred $' .. FormatMoney(amount) .. ' from savings to checking account', 'success')
                LogTransaction(identifier, 'savings_withdrawal', amount, GetTranslation('withdraw_savings'))
            end
        end)
    end)
end)


RegisterServerEvent('omes_banking:transferBetweenAccounts')
AddEventHandler('omes_banking:transferBetweenAccounts', function(fromAccount, toAccount, amount)
    local source = source
    local xPlayer = GetPlayer(source)
    
    if not xPlayer then return end
    
    -- Check if savings accounts are enabled in config
    if not Config.Banking.allowSavingsAccounts and (fromAccount == 'savings' or toAccount == 'savings') then
        SendNotification(source, 'Savings accounts are currently disabled', 'error')
        return
    end
    
    local identifier = GetPlayerIdentifier(xPlayer)
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        SendNotification(source, GetTranslation('invalid_amount'), 'error')
        return
    end
    
    if amount > Config.Banking.maxTransferAmount then
        SendNotification(source, GetTranslation('maximum_amount', FormatMoney(Config.Banking.maxTransferAmount)), 'error')
        return
    end
    
    if fromAccount == toAccount then
        SendNotification(source, 'Cannot transfer to the same account', 'error')
        return
    end
    

    local checkingBalance = GetPlayerBank(xPlayer)
    
    MySQL.Async.fetchScalar('SELECT balance FROM banking_savings WHERE identifier = @identifier AND status = "active"', {
        ['@identifier'] = identifier
    }, function(savingsBalance)
        if not savingsBalance then
            SendNotification(source, 'You need to open a savings account first', 'error')
            return
        end
        
        if fromAccount == 'checking' then
            if checkingBalance < amount then
                SendNotification(source, 'Insufficient funds in checking account', 'error')
                return
            end
            

            RemovePlayerBank(xPlayer, amount)
            MySQL.Async.execute('UPDATE banking_savings SET balance = balance + @amount WHERE identifier = @identifier', {
                ['@identifier'] = identifier,
                ['@amount'] = amount
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    SendNotification(source, 'Transferred $' .. FormatMoney(amount) .. ' from checking to savings', 'success')
                    LogTransaction(identifier, 'account_transfer', amount, GetTranslation('deposit_savings'))
                    

                    SendDiscordLog('savingsOperations', '💰 Account Transfer', 
                        'A player has transferred money from checking to savings.',
                        {
                            {
                                ["name"] = "Player",
                                ["value"] = GetPlayerName(xPlayer) .. ' (' .. source .. ')',
                                ["inline"] = true
                            },
                            {
                                ["name"] = "Transfer Direction",
                                ["value"] = "Checking → Savings",
                                ["inline"] = true
                            },
                            {
                                ["name"] = "Amount",
                                ["value"] = '$' .. FormatMoney(amount),
                                ["inline"] = true
                            },
                            {
                                ["name"] = "New Checking Balance",
                                ["value"] = '$' .. FormatMoney(GetPlayerBank(xPlayer)),
                                ["inline"] = true
                            }
                        },
                        Config.DiscordLogging.color.savings
                    )
                end
            end)
            
        elseif fromAccount == 'savings' then
            if savingsBalance < amount then
                SendNotification(source, 'Insufficient funds in savings account', 'error')
                return
            end
            

            MySQL.Async.execute('UPDATE banking_savings SET balance = balance - @amount WHERE identifier = @identifier', {
                ['@identifier'] = identifier,
                ['@amount'] = amount
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    AddPlayerBank(xPlayer, amount)
                    SendNotification(source, 'Transferred $' .. FormatMoney(amount) .. ' from savings to checking', 'success')
                    LogTransaction(identifier, 'account_transfer', amount, GetTranslation('withdraw_savings'))
                    

                    SendDiscordLog('savingsOperations', '💰 Account Transfer', 
                        'A player has transferred money from savings to checking.',
                        {
                            {
                                ["name"] = "Player",
                                ["value"] = GetPlayerName(xPlayer) .. ' (' .. source .. ')',
                                ["inline"] = true
                            },
                            {
                                ["name"] = "Transfer Direction",
                                ["value"] = "Savings → Checking",
                                ["inline"] = true
                            },
                            {
                                ["name"] = "Amount",
                                ["value"] = '$' .. FormatMoney(amount),
                                ["inline"] = true
                            },
                            {
                                ["name"] = "New Checking Balance",
                                ["value"] = '$' .. FormatMoney(GetPlayerBank(xPlayer)),
                                ["inline"] = true
                            }
                        },
                        Config.DiscordLogging.color.savings
                    )
                end
            end)
        end
    end)
end)


RegisterServerEvent('omes_banking:closeSavingsAccount')
AddEventHandler('omes_banking:closeSavingsAccount', function()
    local source = source
    local xPlayer = GetPlayer(source)
    
    if not xPlayer then return end
    
    -- Check if savings accounts are enabled in config
    if not Config.Banking.allowSavingsAccounts then
        SendNotification(source, 'Savings accounts are currently disabled', 'error')
        return
    end
    
    local identifier = GetPlayerIdentifier(xPlayer)
    
    print(string.format('[BANKING] Player %s (%s) attempting to close savings account', GetPlayerName(xPlayer), identifier))
    

    MySQL.Async.fetchAll('SELECT balance, status FROM banking_savings WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if not result or #result == 0 then
            print(string.format('[BANKING] No savings account found for %s', identifier))
            SendNotification(source, 'You do not have a savings account', 'error')
            return
        end
        
        local accountData = result[1]
        local savingsBalance = accountData.balance or 0
        local currentStatus = accountData.status
        
        print(string.format('[BANKING] Found savings account for %s - Balance: %s, Status: %s', identifier, savingsBalance, currentStatus))
        
        if currentStatus ~= 'active' then
            SendNotification(source, 'Your savings account is already inactive', 'error')
            return
        end
        

        if savingsBalance > 0 then
            AddPlayerBank(xPlayer, savingsBalance)
            LogTransaction(identifier, 'account_transfer', savingsBalance, GetTranslation('withdraw_savings'))
            print(string.format('[BANKING] Transferred %s from savings to checking for %s', savingsBalance, identifier))
        end
        

        MySQL.Async.execute('UPDATE banking_savings SET status = @status, balance = @balance WHERE identifier = @identifier', {
            ['@identifier'] = identifier,
            ['@status'] = 'inactive',
            ['@balance'] = 0
        }, function(rowsChanged)
            print(string.format('[BANKING] Database update result for %s: %s rows changed', identifier, rowsChanged))
            
            if rowsChanged > 0 then
                local message = 'Savings account closed successfully'
                if savingsBalance > 0 then
                    message = message .. '. $' .. FormatMoney(savingsBalance) .. ' transferred to checking account'
                end
                SendNotification(source, message, 'success')
                LogTransaction(identifier, 'savings_closed', 0, GetTranslation('savings_account'))
                

                SendDiscordLog('accountOperations', '🏦 Savings Account Closed', 
                    'A player has closed their savings account.',
                    {
                        {
                            ["name"] = "Player",
                            ["value"] = GetPlayerName(xPlayer) .. ' (' .. source .. ')',
                            ["inline"] = true
                        },
                        {
                            ["name"] = "Transferred Amount",
                            ["value"] = savingsBalance > 0 and ('$' .. FormatMoney(savingsBalance)) or 'No funds to transfer',
                            ["inline"] = true
                        },
                        {
                            ["name"] = "New Checking Balance",
                            ["value"] = '$' .. FormatMoney(GetPlayerBank(xPlayer)),
                            ["inline"] = true
                        }
                    },
                    Config.DiscordLogging.color.admin
                )
                

                TriggerClientEvent('omes_banking:savingsAccountClosed', source)
                
                print(string.format('[BANKING] Successfully closed savings account for %s', identifier))
            else
                print(string.format('[BANKING] Failed to update database for %s', identifier))
                SendNotification(source, 'Failed to close savings account. Please try again.', 'error')
            end
        end)
    end)
end)


RegisterServerEvent('omes_banking:openUI')
AddEventHandler('omes_banking:openUI', function()
    local source = source
    TriggerClientEvent('omes_banking:openUI', source)
end)


RegisterServerEvent('omes_banking:setupPin')
AddEventHandler('omes_banking:setupPin', function(pin)
    local source = source
    local xPlayer = GetPlayer(source)
    
    if not xPlayer then return end
    
    local identifier = GetPlayerIdentifier(xPlayer)
    
    if not pin or string.len(pin) ~= 4 or not tonumber(pin) then
        SendNotification(source, 'Invalid PIN format', 'error')
        return
    end
    

    MySQL.Async.fetchScalar('SELECT pin FROM banking_pins WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(existingPin)
        if existingPin then

            MySQL.Async.execute('UPDATE banking_pins SET pin = @pin WHERE identifier = @identifier', {
                ['@identifier'] = identifier,
                ['@pin'] = pin
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    SendNotification(source, 'PIN updated successfully', 'success')

                    TriggerClientEvent('omes_banking:pinSetupSuccess', source, { pin = pin })
                    

                    SendDiscordLog('pinOperations', '🔐 PIN Updated', 
                        'A player has updated their banking PIN.',
                        {
                            {
                                ["name"] = "Player",
                                ["value"] = GetPlayerName(xPlayer) .. ' (' .. source .. ')',
                                ["inline"] = true
                            },
                            {
                                ["name"] = "Action",
                                ["value"] = "PIN Updated",
                                ["inline"] = true
                            }
                        },
                        Config.DiscordLogging.color.admin
                    )
                end
            end)
        else

            MySQL.Async.execute('INSERT INTO banking_pins (identifier, pin) VALUES (@identifier, @pin)', {
                ['@identifier'] = identifier,
                ['@pin'] = pin
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    SendNotification(source, 'PIN set up successfully', 'success')

                    TriggerClientEvent('omes_banking:pinSetupSuccess', source, { pin = pin })
                    

                    SendDiscordLog('pinOperations', '🔐 PIN Created', 
                        'A player has created a new banking PIN.',
                        {
                            {
                                ["name"] = "Player",
                                ["value"] = GetPlayerName(xPlayer) .. ' (' .. source .. ')',
                                ["inline"] = true
                            },
                            {
                                ["name"] = "Action",
                                ["value"] = "PIN Created",
                                ["inline"] = true
                            }
                        },
                        Config.DiscordLogging.color.admin
                    )
                end
            end)
        end
    end)
end)


RegisterCallback('omes_banking:verifyPin', function(source, cb, enteredPin)
    local xPlayer = GetPlayer(source)
    if not xPlayer then return cb(false) end
    
    local identifier = GetPlayerIdentifier(xPlayer)
    
    MySQL.Async.fetchScalar('SELECT pin FROM banking_pins WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(storedPin)
        if storedPin and storedPin == enteredPin then
            cb(true)
        else
            cb(false)
        end
    end)
end)


RegisterServerEvent('omes_banking:clearAllTransactions')
AddEventHandler('omes_banking:clearAllTransactions', function()
    local source = source
    local xPlayer = GetPlayer(source)
    
    if not xPlayer then return end
    
    local identifier = GetPlayerIdentifier(xPlayer)
    
    MySQL.Async.execute('DELETE FROM banking_transactions WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(rowsChanged)
        if rowsChanged > 0 then
            SendNotification(source, 'All transaction history cleared (' .. rowsChanged .. ' transactions deleted)', 'success')
            
            
            SendDiscordLog('historyClearing', '🗑️ Transaction History Cleared', 
                'A player has cleared their entire transaction history.',
                {
                    {
                        ["name"] = "Player",
                        ["value"] = GetPlayerName(xPlayer) .. ' (' .. source .. ')',
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Transactions Deleted",
                        ["value"] = tostring(rowsChanged),
                        ["inline"] = true
                    }
                },
                Config.DiscordLogging.color.admin
            )
        else
            SendNotification(source, 'No transaction history to clear', 'info')
        end
    end)
end)

-- ====================================
-- BANKING SYSTEM EXPORTS
-- ====================================

-- Export: Add money to player's bank account
-- Usage: exports['omes_banking']:AddBankMoney(source, amount, description)
exports('AddBankMoney', function(source, amount, description)
    if not source or not amount then
        print('[BANKING ERROR] AddBankMoney: Missing parameters')
        return false
    end
    
    local xPlayer = GetPlayer(source)
    if not xPlayer then
        print('[BANKING ERROR] AddBankMoney: Player not found')
        return false
    end
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        print('[BANKING ERROR] AddBankMoney: Invalid amount')
        return false
    end
    
    AddPlayerBank(xPlayer, amount)
    
    local identifier = GetPlayerIdentifier(xPlayer)
    local desc = description or ('Admin deposit of $' .. FormatMoney(amount))
    LogTransaction(identifier, 'admin_deposit', amount, desc)
    
    SendDiscordLog('adminActions', '💰 Admin Bank Deposit', 
        'An admin has added money to a player\'s bank account.',
        {
            {
                ["name"] = "Player",
                ["value"] = GetPlayerName(xPlayer) .. ' (' .. source .. ')',
                ["inline"] = true
            },
            {
                ["name"] = "Amount Added",
                ["value"] = '$' .. FormatMoney(amount),
                ["inline"] = true
            },
            {
                ["name"] = "New Balance",
                ["value"] = '$' .. FormatMoney(GetPlayerBank(xPlayer)),
                ["inline"] = true
            },
            {
                ["name"] = "Description",
                ["value"] = desc,
                ["inline"] = false
            }
        },
        Config.DiscordLogging.color.admin
    )
    
    print(string.format('[BANKING] Added $%s to %s\'s bank account', FormatMoney(amount), GetPlayerName(xPlayer)))
    return true
end)

-- Export: Remove money from player's bank account
-- Usage: exports['omes_banking']:RemoveBankMoney(source, amount, description)
exports('RemoveBankMoney', function(source, amount, description)
    if not source or not amount then
        print('[BANKING ERROR] RemoveBankMoney: Missing parameters')
        return false
    end
    
    local xPlayer = GetPlayer(source)
    if not xPlayer then
        print('[BANKING ERROR] RemoveBankMoney: Player not found')
        return false
    end
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        print('[BANKING ERROR] RemoveBankMoney: Invalid amount')
        return false
    end
    
    local currentBalance = GetPlayerBank(xPlayer)
    if currentBalance < amount then
        print('[BANKING ERROR] RemoveBankMoney: Insufficient funds')
        return false
    end
    
    RemovePlayerBank(xPlayer, amount)
    
    local identifier = GetPlayerIdentifier(xPlayer)
    local desc = description or ('Admin withdrawal of $' .. FormatMoney(amount))
    LogTransaction(identifier, 'admin_withdrawal', amount, desc)
    
    SendDiscordLog('adminActions', '💸 Admin Bank Withdrawal', 
        'An admin has removed money from a player\'s bank account.',
        {
            {
                ["name"] = "Player",
                ["value"] = GetPlayerName(xPlayer) .. ' (' .. source .. ')',
                ["inline"] = true
            },
            {
                ["name"] = "Amount Removed",
                ["value"] = '$' .. FormatMoney(amount),
                ["inline"] = true
            },
            {
                ["name"] = "New Balance",
                ["value"] = '$' .. FormatMoney(GetPlayerBank(xPlayer)),
                ["inline"] = true
            },
            {
                ["name"] = "Description",
                ["value"] = desc,
                ["inline"] = false
            }
        },
        Config.DiscordLogging.color.admin
    )
    
    print(string.format('[BANKING] Removed $%s from %s\'s bank account', FormatMoney(amount), GetPlayerName(xPlayer)))
    return true
end)

-- Export: Add money to player's cash
-- Usage: exports['omes_banking']:AddCashMoney(source, amount, description)
exports('AddCashMoney', function(source, amount, description)
    if not source or not amount then
        print('[BANKING ERROR] AddCashMoney: Missing parameters')
        return false
    end
    
    local xPlayer = GetPlayer(source)
    if not xPlayer then
        print('[BANKING ERROR] AddCashMoney: Player not found')
        return false
    end
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        print('[BANKING ERROR] AddCashMoney: Invalid amount')
        return false
    end
    
    AddPlayerCash(xPlayer, amount)
    
    local identifier = GetPlayerIdentifier(xPlayer)
    local desc = description or ('Admin cash grant of $' .. FormatMoney(amount))
    LogTransaction(identifier, 'admin_cash_grant', amount, desc)
    
    SendDiscordLog('adminActions', '💵 Admin Cash Grant', 
        'An admin has given cash to a player.',
        {
            {
                ["name"] = "Player",
                ["value"] = GetPlayerName(xPlayer) .. ' (' .. source .. ')',
                ["inline"] = true
            },
            {
                ["name"] = "Cash Added",
                ["value"] = '$' .. FormatMoney(amount),
                ["inline"] = true
            },
            {
                ["name"] = "New Cash Balance",
                ["value"] = '$' .. FormatMoney(GetPlayerCash(xPlayer)),
                ["inline"] = true
            },
            {
                ["name"] = "Description",
                ["value"] = desc,
                ["inline"] = false
            }
        },
        Config.DiscordLogging.color.admin
    )
    
    print(string.format('[BANKING] Added $%s cash to %s', FormatMoney(amount), GetPlayerName(xPlayer)))
    return true
end)

-- Export: Remove money from player's cash
-- Usage: exports['omes_banking']:RemoveCashMoney(source, amount, description)
exports('RemoveCashMoney', function(source, amount, description)
    if not source or not amount then
        print('[BANKING ERROR] RemoveCashMoney: Missing parameters')
        return false
    end
    
    local xPlayer = GetPlayer(source)
    if not xPlayer then
        print('[BANKING ERROR] RemoveCashMoney: Player not found')
        return false
    end
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        print('[BANKING ERROR] RemoveCashMoney: Invalid amount')
        return false
    end
    
    local currentCash = GetPlayerCash(xPlayer)
    if currentCash < amount then
        print('[BANKING ERROR] RemoveCashMoney: Insufficient cash')
        return false
    end
    
    RemovePlayerCash(xPlayer, amount)
    
    local identifier = GetPlayerIdentifier(xPlayer)
    local desc = description or ('Admin cash removal of $' .. FormatMoney(amount))
    LogTransaction(identifier, 'admin_cash_removal', amount, desc)
    
    SendDiscordLog('adminActions', '💸 Admin Cash Removal', 
        'An admin has removed cash from a player.',
        {
            {
                ["name"] = "Player",
                ["value"] = GetPlayerName(xPlayer) .. ' (' .. source .. ')',
                ["inline"] = true
            },
            {
                ["name"] = "Cash Removed",
                ["value"] = '$' .. FormatMoney(amount),
                ["inline"] = true
            },
            {
                ["name"] = "New Cash Balance",
                ["value"] = '$' .. FormatMoney(GetPlayerCash(xPlayer)),
                ["inline"] = true
            },
            {
                ["name"] = "Description",
                ["value"] = desc,
                ["inline"] = false
            }
        },
        Config.DiscordLogging.color.admin
    )
    
    print(string.format('[BANKING] Removed $%s cash from %s', FormatMoney(amount), GetPlayerName(xPlayer)))
    return true
end)

-- Export: Get player's account information
-- Usage: exports['omes_banking']:GetPlayerAccount(source)
exports('GetPlayerAccount', function(source)
    if not source then
        print('[BANKING ERROR] GetPlayerAccount: Missing source parameter')
        return nil
    end
    
    local xPlayer = GetPlayer(source)
    if not xPlayer then
        print('[BANKING ERROR] GetPlayerAccount: Player not found')
        return nil
    end
    
    local identifier = GetPlayerIdentifier(xPlayer)
    local accountData = {
        source = source,
        name = GetPlayerName(xPlayer),
        identifier = identifier,
        bankBalance = GetPlayerBank(xPlayer),
        cashBalance = GetPlayerCash(xPlayer),
        accountNumber = '****-****-' .. string.sub(identifier, -4)
    }
    
    return accountData
end)

-- Export: Get player's bank balance
-- Usage: exports['omes_banking']:GetBankBalance(source)
exports('GetBankBalance', function(source)
    if not source then
        print('[BANKING ERROR] GetBankBalance: Missing source parameter')
        return 0
    end
    
    local xPlayer = GetPlayer(source)
    if not xPlayer then
        print('[BANKING ERROR] GetBankBalance: Player not found')
        return 0
    end
    
    return GetPlayerBank(xPlayer)
end)

-- Export: Get player's cash balance
-- Usage: exports['omes_banking']:GetCashBalance(source)
exports('GetCashBalance', function(source)
    if not source then
        print('[BANKING ERROR] GetCashBalance: Missing source parameter')
        return 0
    end
    
    local xPlayer = GetPlayer(source)
    if not xPlayer then
        print('[BANKING ERROR] GetCashBalance: Player not found')
        return 0
    end
    
    return GetPlayerCash(xPlayer)
end)

-- Export: Transfer money between players
-- Usage: exports['omes_banking']:TransferMoney(fromSource, toSource, amount, description)
exports('TransferMoney', function(fromSource, toSource, amount, description)
    if not fromSource or not toSource or not amount then
        print('[BANKING ERROR] TransferMoney: Missing parameters')
        return false
    end
    
    local xPlayer = GetPlayer(fromSource)
    local xTarget = GetPlayer(toSource)
    
    if not xPlayer then
        print('[BANKING ERROR] TransferMoney: Sender not found')
        return false
    end
    
    if not xTarget then
        print('[BANKING ERROR] TransferMoney: Recipient not found')
        return false
    end
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        print('[BANKING ERROR] TransferMoney: Invalid amount')
        return false
    end
    
    if fromSource == toSource then
        print('[BANKING ERROR] TransferMoney: Cannot transfer to yourself')
        return false
    end
    
    local senderBalance = GetPlayerBank(xPlayer)
    if senderBalance < amount then
        print('[BANKING ERROR] TransferMoney: Insufficient funds')
        return false
    end
    
    RemovePlayerBank(xPlayer, amount)
    AddPlayerBank(xTarget, amount)
    
    local desc = description or ('Admin transfer of $' .. FormatMoney(amount))
    LogTransaction(GetPlayerIdentifier(xPlayer), 'admin_transfer_out', amount, 'Admin transfer to ' .. GetPlayerName(xTarget) .. ': ' .. desc)
    LogTransaction(GetPlayerIdentifier(xTarget), 'admin_transfer_in', amount, 'Admin transfer from ' .. GetPlayerName(xPlayer) .. ': ' .. desc)
    
    SendDiscordLog('adminActions', '💳 Admin Transfer', 
        'An admin has transferred money between players.',
        {
            {
                ["name"] = "From",
                ["value"] = GetPlayerName(xPlayer) .. ' (' .. fromSource .. ')',
                ["inline"] = true
            },
            {
                ["name"] = "To",
                ["value"] = GetPlayerName(xTarget) .. ' (' .. toSource .. ')',
                ["inline"] = true
            },
            {
                ["name"] = "Amount",
                ["value"] = '$' .. FormatMoney(amount),
                ["inline"] = true
            },
            {
                ["name"] = "Description",
                ["value"] = desc,
                ["inline"] = false
            }
        },
        Config.DiscordLogging.color.admin
    )
    
    print(string.format('[BANKING] Admin transferred $%s from %s to %s', FormatMoney(amount), GetPlayerName(xPlayer), GetPlayerName(xTarget)))
    return true
end)

-- Export: Get player's savings account information (if enabled)
-- Usage: exports['omes_banking']:GetSavingsAccount(source, callback)
exports('GetSavingsAccount', function(source, callback)
    if not source then
        print('[BANKING ERROR] GetSavingsAccount: Missing source parameter')
        if callback then callback(nil) end
        return
    end
    
    if not Config.Banking.allowSavingsAccounts then
        print('[BANKING ERROR] GetSavingsAccount: Savings accounts are disabled')
        if callback then callback(nil) end
        return
    end
    
    local xPlayer = GetPlayer(source)
    if not xPlayer then
        print('[BANKING ERROR] GetSavingsAccount: Player not found')
        if callback then callback(nil) end
        return
    end
    
    local identifier = GetPlayerIdentifier(xPlayer)
    
    MySQL.Async.fetchAll('SELECT balance, status FROM banking_savings WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if result and #result > 0 then
            local savingsData = {
                balance = result[1].balance or 0,
                status = result[1].status,
                accountNumber = '****-****-' .. string.sub(identifier, -4):reverse(),
                active = result[1].status == 'active'
            }
            if callback then callback(savingsData) end
        else
            if callback then callback(nil) end
        end
    end)
end)

-- Export: Add money to player's savings account
-- Usage: exports['omes_banking']:AddSavingsMoney(source, amount, description)
exports('AddSavingsMoney', function(source, amount, description)
    if not Config.Banking.allowSavingsAccounts then
        print('[BANKING ERROR] AddSavingsMoney: Savings accounts are disabled')
        return false
    end
    
    if not source or not amount then
        print('[BANKING ERROR] AddSavingsMoney: Missing parameters')
        return false
    end
    
    local xPlayer = GetPlayer(source)
    if not xPlayer then
        print('[BANKING ERROR] AddSavingsMoney: Player not found')
        return false
    end
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        print('[BANKING ERROR] AddSavingsMoney: Invalid amount')
        return false
    end
    
    local identifier = GetPlayerIdentifier(xPlayer)
    
    MySQL.Async.fetchScalar('SELECT status FROM banking_savings WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(status)
        if status ~= 'active' then
            print('[BANKING ERROR] AddSavingsMoney: Player does not have an active savings account')
            return false
        end
        
        MySQL.Async.execute('UPDATE banking_savings SET balance = balance + @amount WHERE identifier = @identifier', {
            ['@identifier'] = identifier,
            ['@amount'] = amount
        }, function(rowsChanged)
            if rowsChanged > 0 then
                local desc = description or ('Admin savings deposit of $' .. FormatMoney(amount))
                LogTransaction(identifier, 'admin_savings_deposit', amount, desc)
                
                SendDiscordLog('adminActions', '🏦 Admin Savings Deposit', 
                    'An admin has added money to a player\'s savings account.',
                    {
                        {
                            ["name"] = "Player",
                            ["value"] = GetPlayerName(xPlayer) .. ' (' .. source .. ')',
                            ["inline"] = true
                        },
                        {
                            ["name"] = "Amount Added",
                            ["value"] = '$' .. FormatMoney(amount),
                            ["inline"] = true
                        },
                        {
                            ["name"] = "Description",
                            ["value"] = desc,
                            ["inline"] = false
                        }
                    },
                    Config.DiscordLogging.color.admin
                )
                
                print(string.format('[BANKING] Added $%s to %s\'s savings account', FormatMoney(amount), GetPlayerName(xPlayer)))
            end
        end)
    end)
    
    return true
end)

-- Export: Log custom transaction
-- Usage: exports['omes_banking']:LogCustomTransaction(source, type, amount, description)
exports('LogCustomTransaction', function(source, type, amount, description)
    if not source or not type or not amount or not description then
        print('[BANKING ERROR] LogCustomTransaction: Missing parameters')
        return false
    end
    
    local xPlayer = GetPlayer(source)
    if not xPlayer then
        print('[BANKING ERROR] LogCustomTransaction: Player not found')
        return false
    end
    
    local identifier = GetPlayerIdentifier(xPlayer)
    LogTransaction(identifier, type, amount, description)
    
    print(string.format('[BANKING] Custom transaction logged for %s: %s - $%s - %s', GetPlayerName(xPlayer), type, FormatMoney(amount), description))
    return true
end)

-- Export: Open banking UI for player
-- Usage: exports['omes_banking']:OpenBankingUI(source)
exports('OpenBankingUI', function(source)
    if not source then
        print('[BANKING ERROR] OpenBankingUI: Missing source parameter')
        return false
    end
    
    TriggerClientEvent('omes_banking:openUI', source)
    print(string.format('[BANKING] Opened banking UI for player %s', source))
    return true
end)

-- Export: Check if player has enough money in bank
-- Usage: exports['omes_banking']:HasEnoughBank(source, amount)
exports('HasEnoughBank', function(source, amount)
    if not source or not amount then
        print('[BANKING ERROR] HasEnoughBank: Missing parameters')
        return false
    end
    
    local xPlayer = GetPlayer(source)
    if not xPlayer then
        print('[BANKING ERROR] HasEnoughBank: Player not found')
        return false
    end
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        print('[BANKING ERROR] HasEnoughBank: Invalid amount')
        return false
    end
    
    return GetPlayerBank(xPlayer) >= amount
end)

-- Export: Check if player has enough cash
-- Usage: exports['omes_banking']:HasEnoughCash(source, amount)
exports('HasEnoughCash', function(source, amount)
    if not source or not amount then
        print('[BANKING ERROR] HasEnoughCash: Missing parameters')
        return false
    end
    
    local xPlayer = GetPlayer(source)
    if not xPlayer then
        print('[BANKING ERROR] HasEnoughCash: Player not found')
        return false
    end
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        print('[BANKING ERROR] HasEnoughCash: Invalid amount')
        return false
    end
    
    return GetPlayerCash(xPlayer) >= amount
end)

