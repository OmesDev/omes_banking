# OMES Banking System

Showcase: https://www.youtube.com/watch?v=4Ei3ub9WfrE

A comprehensive banking system for FiveM servers that supports both ESX and QB Core frameworks.


Update your police job to use omes_banking instead of qb-banking. You'll need to find this line in your police job server files:

exports['qb-banking']:AddMoney(source, 'bank', amount, reason)

And change it to:

exports['omes_banking']:AddMoney(source, 'bank', amount, reason)


## Features

- **Framework Compatibility**: Supports both ESX and QB Core frameworks
- **Banking Operations**: Deposit, withdraw, and transfer money
- **Savings Accounts**: Open and manage savings accounts
- **ATM Support**: Use ATMs with PIN verification
- **Transaction History**: Track all banking transactions
- **Balance Charts**: Visual representation of balance history
- **Notification System**: Supports ESX, QB Core, and OX Lib notifications
- **Multi-language Support**: Supports 6 languages with easy expansion system

## Installation

1. Download and place the resource in your `resources` folder
2. Add `ensure omes_banking` to your `server.cfg`
3. Import the SQL file to create the required database tables
4. Configure the script in `config.lua`

## Configuration

### Framework Selection

In `config.lua`, set your framework:

```lua
Config.Framework = 'esx' -- Options: 'esx', 'qb'
```

### Notification System

Choose your notification system:

```lua
Config.NotificationType = 'ox' -- Options: 'esx', 'ox'
```

### Language Configuration

The banking system supports multiple languages. Set your preferred language:

```lua
Config.DefaultLanguage = 'en' -- Options: 'en', 'es', 'fr', 'ar', 'de', 'pt'
```

**Available Languages:**
- **English** (`en`) - Default language
- **Spanish** (`es`) - Español
- **French** (`fr`) - Français  
- **Arabic** (`ar`) - العربية
- **German** (`de`) - Deutsch
- **Portuguese** (`pt`) - Português

### Banking Settings

Configure banking limits and features:

```lua
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
```

## Database Tables

The script requires the following database tables:

```sql
-- Banking transactions
CREATE TABLE IF NOT EXISTS `banking_transactions` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `identifier` varchar(50) NOT NULL,
    `type` varchar(50) NOT NULL,
    `amount` int(11) NOT NULL,
    `description` text,
    `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
);

-- Banking savings accounts
CREATE TABLE IF NOT EXISTS `banking_savings` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `identifier` varchar(50) NOT NULL,
    `balance` int(11) NOT NULL DEFAULT 0,
    `status` varchar(20) NOT NULL DEFAULT 'active',
    PRIMARY KEY (`id`)
);

-- Banking PINs
CREATE TABLE IF NOT EXISTS `banking_pins` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `identifier` varchar(50) NOT NULL,
    `pin` varchar(4) NOT NULL,
    PRIMARY KEY (`id`)
);
```

## Framework Compatibility

### ESX Legacy
- Uses `identifier` for player identification
- Money management through ESX account system
- ESX notification system support

### QB Core
- Uses `citizenid` for player identification
- Money management through QB Core money system
- QB Core notification system support

## Commands

- `/bank` - Opens the banking interface (admin/testing)

## Adding New Languages

To add a new language to the banking system:

1. **Open `config.lua`** and locate the `Config.Translations` table
2. **Add your language code** to the `Config.DefaultLanguage` comment options
3. **Create a new translation table** following this structure:

```lua
['your_lang_code'] = {
    -- General
    ['bank_name'] = 'Your Bank Name',
    ['welcome'] = 'Welcome Message',
    ['balance'] = 'Balance',
    ['account'] = 'Account',
    ['amount'] = 'Amount',
    ['confirm'] = 'Confirm',
    ['cancel'] = 'Cancel',
    ['close'] = 'Close',
    -- ... (continue with all translation keys)
}
```

4. **Copy all translation keys** from the English (`en`) section to ensure completeness
5. **Translate each value** to your target language
6. **Update the default language** in config if desired:

```lua
Config.DefaultLanguage = 'your_lang_code'
```

**Translation Keys Include:**
- General UI elements (buttons, labels, messages)
- Account management terms
- Transaction types and messages
- ATM and PIN related text
- Savings account terminology
- Admin panel text
- Error messages and notifications

**Note:** The system automatically falls back to English if a translation key is missing in your selected language.

## Dependencies

- **ESX Legacy** (if using ESX framework)
- **QB Core** (if using QB Core framework)
- **OX Lib** (optional, for enhanced notifications)
- **MySQL-Async** or **oxmysql**

## Support

For support and updates, please visit our GitHub repository or Discord server.

## License

This project is licensed under the MIT License. 
