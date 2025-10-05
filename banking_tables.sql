-- OMES Banking System Database Tables
-- Compatible with both ESX and QB Core frameworks

-- Banking transactions table
CREATE TABLE IF NOT EXISTS `banking_transactions` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `identifier` varchar(50) NOT NULL COMMENT 'Player identifier (ESX) or citizenid (QB)',
    `type` varchar(50) NOT NULL COMMENT 'Transaction type: deposit, withdrawal, transfer_in, transfer_out, fee, savings_deposit, savings_withdrawal, account_transfer, savings_opened, savings_closed',
    `amount` int(11) NOT NULL COMMENT 'Transaction amount',
    `description` text COMMENT 'Transaction description',
    `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Transaction timestamp',
    PRIMARY KEY (`id`),
    KEY `identifier` (`identifier`),
    KEY `type` (`type`),
    KEY `date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Banking savings accounts table
CREATE TABLE IF NOT EXISTS `banking_savings` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `identifier` varchar(50) NOT NULL COMMENT 'Player identifier (ESX) or citizenid (QB)',
    `balance` int(11) NOT NULL DEFAULT 0 COMMENT 'Savings account balance',
    `status` varchar(20) NOT NULL DEFAULT 'active' COMMENT 'Account status: active, inactive',
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Account creation date',
    `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last update date',
    PRIMARY KEY (`id`),
    UNIQUE KEY `identifier` (`identifier`),
    KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Banking PINs table for ATM access
CREATE TABLE IF NOT EXISTS `banking_pins` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `identifier` varchar(50) NOT NULL COMMENT 'Player identifier (ESX) or citizenid (QB)',
    `pin` varchar(4) NOT NULL COMMENT '4-digit PIN for ATM access',
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'PIN creation date',
    `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last PIN update',
    PRIMARY KEY (`id`),
    UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 