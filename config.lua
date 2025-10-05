Config = {}

-- Framework Settings
Config.Framework = 'qb' -- Options: 'esx', 'qb'

-- Notification Settings
Config.NotificationType = 'ox' -- Options: 'esx', 'ox', 'qb'

-- General Settings
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
    allowSavingsAccounts = false, -- Set to false to disable savings account functionality
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

-- Language Configuration
Config.DefaultLanguage = 'en' -- Default language: 'en', 'es', 'fr', 'ar', 'de', 'pt'

-- Translations
Config.Translations = {
    ['en'] = {
        -- General
        ['bank_name'] = 'Fleeca Bank',
        ['welcome'] = 'Welcome to Banking',
        ['balance'] = 'Balance',
        ['account'] = 'Account',
        ['amount'] = 'Amount',
        ['confirm'] = 'Confirm',
        ['cancel'] = 'Cancel',
        ['close'] = 'Close',
        ['success'] = 'Success',
        ['error'] = 'Error',
        ['warning'] = 'Warning',
        ['info'] = 'Information',
        
        -- Account Management
        ['checking_account'] = 'Checking Account',
        ['savings_account'] = 'Savings Account',
        ['account_balance'] = 'Account Balance',
        ['insufficient_funds'] = 'Insufficient funds',
        ['account_not_found'] = 'Account not found',
        ['account_created'] = 'Account created successfully',
        ['account_deleted'] = 'Account deleted successfully',
        
        -- Transactions
        ['deposit'] = 'Deposit',
        ['withdraw'] = 'Withdraw',
        ['transfer'] = 'Transfer',
        ['transaction_history'] = 'Transaction History',
        ['transaction_completed'] = 'Transaction completed successfully',
        ['transaction_failed'] = 'Transaction failed',
        ['enter_amount'] = 'Enter amount',
        ['enter_target'] = 'Enter target player ID',
        ['invalid_amount'] = 'Invalid amount',
        ['invalid_target'] = 'Invalid target',
        ['minimum_amount'] = 'Minimum amount is $%s',
        ['maximum_amount'] = 'Maximum amount is $%s',
        ['transfer_fee'] = 'Transfer fee: $%s',
        ['self_transfer'] = 'Cannot transfer to yourself',
        ['player_not_found'] = 'Player not found',
        
        -- ATM
        ['atm_access'] = 'Access ATM',
        ['atm_card_required'] = 'ATM card required',
        ['atm_out_of_service'] = 'ATM out of service',
        
        -- PIN
        ['enter_pin'] = 'Enter PIN',
        ['pin_required'] = 'PIN required',
        ['pin_incorrect'] = 'Incorrect PIN',
        ['pin_changed'] = 'PIN changed successfully',
        ['change_pin'] = 'Change PIN',
        
        -- Interactions
        ['press_to_access'] = 'Press [E] to access banking',
        ['banking_accessed'] = 'Banking system accessed',
        ['too_far'] = 'You are too far from the ATM/Bank',
        
        -- Savings
        ['create_savings'] = 'Create Savings Account',
        ['deposit_savings'] = 'Deposit to Savings',
        ['withdraw_savings'] = 'Withdraw from Savings',
        ['savings_interest'] = 'Interest Rate: %s%%',
        ['savings_created'] = 'Savings account created',
        ['savings_deposit'] = 'Deposited $%s to savings',
        ['savings_withdraw'] = 'Withdrew $%s from savings',
        ['transfer_to'] = 'Transfer to',
        ['transfer_from'] = 'Transfer from',
        ['account_closure'] = 'Account closure',
        
        -- Admin
        ['admin_panel'] = 'Admin Panel',
        ['manage_accounts'] = 'Manage Accounts',
        ['view_logs'] = 'View Logs',
        ['insufficient_permission'] = 'Insufficient permission',
        
        -- Errors
        ['database_error'] = 'Database error occurred',
        ['connection_error'] = 'Connection error',
        ['timeout_error'] = 'Request timeout',
        ['unknown_error'] = 'Unknown error occurred'
    },
    
    ['es'] = {
        -- General
        ['bank_name'] = 'Banco Fleeca',
        ['welcome'] = 'Bienvenido a la Banca',
        ['balance'] = 'Saldo',
        ['account'] = 'Cuenta',
        ['amount'] = 'Cantidad',
        ['confirm'] = 'Confirmar',
        ['cancel'] = 'Cancelar',
        ['close'] = 'Cerrar',
        ['success'] = 'Éxito',
        ['error'] = 'Error',
        ['warning'] = 'Advertencia',
        ['info'] = 'Información',
        
        -- Account Management
        ['checking_account'] = 'Cuenta Corriente',
        ['savings_account'] = 'Cuenta de Ahorros',
        ['account_balance'] = 'Saldo de la Cuenta',
        ['insufficient_funds'] = 'Fondos insuficientes',
        ['account_not_found'] = 'Cuenta no encontrada',
        ['account_created'] = 'Cuenta creada exitosamente',
        ['account_deleted'] = 'Cuenta eliminada exitosamente',
        
        -- Transactions
        ['deposit'] = 'Depósito',
        ['withdraw'] = 'Retirar',
        ['transfer'] = 'Transferir',
        ['transaction_history'] = 'Historial de Transacciones',
        ['transaction_completed'] = 'Transacción completada exitosamente',
        ['transaction_failed'] = 'Transacción fallida',
        ['enter_amount'] = 'Ingrese la cantidad',
        ['enter_target'] = 'Ingrese ID del jugador objetivo',
        ['invalid_amount'] = 'Cantidad inválida',
        ['invalid_target'] = 'Objetivo inválido',
        ['minimum_amount'] = 'La cantidad mínima es $%s',
        ['maximum_amount'] = 'La cantidad máxima es $%s',
        ['transfer_fee'] = 'Comisión de transferencia: $%s',
        ['self_transfer'] = 'No puedes transferir a ti mismo',
        ['player_not_found'] = 'Jugador no encontrado',
        
        -- ATM
        ['atm_access'] = 'Acceder al Cajero',
        ['atm_card_required'] = 'Tarjeta de cajero requerida',
        ['atm_out_of_service'] = 'Cajero fuera de servicio',
        
        -- PIN
        ['enter_pin'] = 'Ingrese PIN',
        ['pin_required'] = 'PIN requerido',
        ['pin_incorrect'] = 'PIN incorrecto',
        ['pin_changed'] = 'PIN cambiado exitosamente',
        ['change_pin'] = 'Cambiar PIN',
        
        -- Interactions
        ['press_to_access'] = 'Presiona [E] para acceder a la banca',
        ['banking_accessed'] = 'Sistema bancario accedido',
        ['too_far'] = 'Estás muy lejos del Cajero/Banco',
        
        -- Savings
        ['create_savings'] = 'Crear Cuenta de Ahorros',
        ['deposit_savings'] = 'Depositar en Ahorros',
        ['withdraw_savings'] = 'Retirar de Ahorros',
        ['savings_interest'] = 'Tasa de Interés: %s%%',
        ['savings_created'] = 'Cuenta de ahorros creada',
        ['savings_deposit'] = 'Depositado $%s en ahorros',
        ['savings_withdraw'] = 'Retirado $%s de ahorros',
        ['transfer_to'] = 'Transferir a',
        ['transfer_from'] = 'Transferir de',
        ['account_closure'] = 'Cierre de cuenta',
        
        -- Admin
        ['admin_panel'] = 'Panel de Administrador',
        ['manage_accounts'] = 'Gestionar Cuentas',
        ['view_logs'] = 'Ver Registros',
        ['insufficient_permission'] = 'Permisos insuficientes',
        
        -- Errors
        ['database_error'] = 'Error de base de datos',
        ['connection_error'] = 'Error de conexión',
        ['timeout_error'] = 'Tiempo de espera agotado',
        ['unknown_error'] = 'Error desconocido'
    },
    
    ['fr'] = {
        -- General
        ['bank_name'] = 'Banque Fleeca',
        ['welcome'] = 'Bienvenue à la Banque',
        ['balance'] = 'Solde',
        ['account'] = 'Compte',
        ['amount'] = 'Montant',
        ['confirm'] = 'Confirmer',
        ['cancel'] = 'Annuler',
        ['close'] = 'Fermer',
        ['success'] = 'Succès',
        ['error'] = 'Erreur',
        ['warning'] = 'Avertissement',
        ['info'] = 'Information',
        
        -- Account Management
        ['checking_account'] = 'Compte Courant',
        ['savings_account'] = 'Compte d\'Épargne',
        ['account_balance'] = 'Solde du Compte',
        ['insufficient_funds'] = 'Fonds insuffisants',
        ['account_not_found'] = 'Compte non trouvé',
        ['account_created'] = 'Compte créé avec succès',
        ['account_deleted'] = 'Compte supprimé avec succès',
        
        -- Transactions
        ['deposit'] = 'Dépôt',
        ['withdraw'] = 'Retirer',
        ['transfer'] = 'Virement',
        ['transaction_history'] = 'Historique des Transactions',
        ['transaction_completed'] = 'Transaction terminée avec succès',
        ['transaction_failed'] = 'Transaction échouée',
        ['enter_amount'] = 'Entrez le montant',
        ['enter_target'] = 'Entrez l\'ID du joueur cible',
        ['invalid_amount'] = 'Montant invalide',
        ['invalid_target'] = 'Cible invalide',
        ['minimum_amount'] = 'Le montant minimum est $%s',
        ['maximum_amount'] = 'Le montant maximum est $%s',
        ['transfer_fee'] = 'Frais de virement: $%s',
        ['self_transfer'] = 'Impossible de virer vers soi-même',
        ['player_not_found'] = 'Joueur non trouvé',
        
        -- ATM
        ['atm_access'] = 'Accéder au GAB',
        ['atm_card_required'] = 'Carte bancaire requise',
        ['atm_out_of_service'] = 'GAB hors service',
        
        -- PIN
        ['enter_pin'] = 'Entrez le PIN',
        ['pin_required'] = 'PIN requis',
        ['pin_incorrect'] = 'PIN incorrect',
        ['pin_changed'] = 'PIN modifié avec succès',
        ['change_pin'] = 'Changer le PIN',
        
        -- Interactions
        ['press_to_access'] = 'Appuyez sur [E] pour accéder à la banque',
        ['banking_accessed'] = 'Système bancaire accédé',
        ['too_far'] = 'Vous êtes trop loin du GAB/Banque',
        
        -- Savings
        ['create_savings'] = 'Créer un Compte d\'Épargne',
        ['deposit_savings'] = 'Déposer sur l\'Épargne',
        ['withdraw_savings'] = 'Retirer de l\'Épargne',
        ['savings_interest'] = 'Taux d\'Intérêt: %s%%',
        ['savings_created'] = 'Compte d\'épargne créé',
        ['savings_deposit'] = 'Déposé $%s sur l\'épargne',
        ['savings_withdraw'] = 'Retiré $%s de l\'épargne',
        ['transfer_to'] = 'Virement vers',
        ['transfer_from'] = 'Virement de',
        ['account_closure'] = 'Fermeture de compte',
        
        -- Admin
        ['admin_panel'] = 'Panneau Administrateur',
        ['manage_accounts'] = 'Gérer les Comptes',
        ['view_logs'] = 'Voir les Journaux',
        ['insufficient_permission'] = 'Permissions insuffisantes',
        
        -- Errors
        ['database_error'] = 'Erreur de base de données',
        ['connection_error'] = 'Erreur de connexion',
        ['timeout_error'] = 'Délai d\'attente dépassé',
        ['unknown_error'] = 'Erreur inconnue'
    },
    
    ['ar'] = {
        -- General
        ['bank_name'] = 'بنك فليكا',
        ['welcome'] = 'مرحباً بك في البنك',
        ['balance'] = 'الرصيد',
        ['account'] = 'الحساب',
        ['amount'] = 'المبلغ',
        ['confirm'] = 'تأكيد',
        ['cancel'] = 'إلغاء',
        ['close'] = 'إغلاق',
        ['success'] = 'نجح',
        ['error'] = 'خطأ',
        ['warning'] = 'تحذير',
        ['info'] = 'معلومات',
        
        -- Account Management
        ['checking_account'] = 'الحساب الجاري',
        ['savings_account'] = 'حساب التوفير',
        ['account_balance'] = 'رصيد الحساب',
        ['insufficient_funds'] = 'رصيد غير كافٍ',
        ['account_not_found'] = 'لم يتم العثور على الحساب',
        ['account_created'] = 'تم إنشاء الحساب بنجاح',
        ['account_deleted'] = 'تم حذف الحساب بنجاح',
        
        -- Transactions
        ['deposit'] = 'إيداع',
        ['withdraw'] = 'سحب',
        ['transfer'] = 'تحويل',
        ['transaction_history'] = 'تاريخ المعاملات',
        ['transaction_completed'] = 'تمت المعاملة بنجاح',
        ['transaction_failed'] = 'فشلت المعاملة',
        ['enter_amount'] = 'أدخل المبلغ',
        ['enter_target'] = 'أدخل معرف اللاعب المستهدف',
        ['invalid_amount'] = 'مبلغ غير صحيح',
        ['invalid_target'] = 'هدف غير صحيح',
        ['minimum_amount'] = 'الحد الأدنى للمبلغ هو %s$',
        ['maximum_amount'] = 'الحد الأقصى للمبلغ هو %s$',
        ['transfer_fee'] = 'رسوم التحويل: %s$',
        ['self_transfer'] = 'لا يمكن التحويل لنفسك',
        ['player_not_found'] = 'لم يتم العثور على اللاعب',
        
        -- ATM
        ['atm_access'] = 'الوصول إلى الصراف الآلي',
        ['atm_card_required'] = 'بطاقة الصراف الآلي مطلوبة',
        ['atm_out_of_service'] = 'الصراف الآلي خارج الخدمة',
        
        -- PIN
        ['enter_pin'] = 'أدخل الرقم السري',
        ['pin_required'] = 'الرقم السري مطلوب',
        ['pin_incorrect'] = 'الرقم السري غير صحيح',
        ['pin_changed'] = 'تم تغيير الرقم السري بنجاح',
        ['change_pin'] = 'تغيير الرقم السري',
        
        -- Interactions
        ['press_to_access'] = 'اضغط [E] للوصول إلى البنك',
        ['banking_accessed'] = 'تم الوصول إلى النظام المصرفي',
        ['too_far'] = 'أنت بعيد جداً عن الصراف الآلي/البنك',
        
        -- Savings
        ['create_savings'] = 'إنشاء حساب توفير',
        ['deposit_savings'] = 'إيداع في التوفير',
        ['withdraw_savings'] = 'سحب من التوفير',
        ['savings_interest'] = 'معدل الفائدة: %s%%',
        ['savings_created'] = 'تم إنشاء حساب التوفير',
        ['savings_deposit'] = 'تم إيداع %s$ في التوفير',
        ['savings_withdraw'] = 'تم سحب %s$ من التوفير',
        ['transfer_to'] = 'تحويل إلى',
        ['transfer_from'] = 'تحويل من',
        ['account_closure'] = 'إغلاق حساب',
        
        -- Admin
        ['admin_panel'] = 'لوحة الإدارة',
        ['manage_accounts'] = 'إدارة الحسابات',
        ['view_logs'] = 'عرض السجلات',
        ['insufficient_permission'] = 'صلاحيات غير كافية',
        
        -- Errors
        ['database_error'] = 'حدث خطأ في قاعدة البيانات',
        ['connection_error'] = 'خطأ في الاتصال',
        ['timeout_error'] = 'انتهت مهلة الطلب',
        ['unknown_error'] = 'حدث خطأ غير معروف'
    },
    
    ['de'] = {
        -- General
        ['bank_name'] = 'Fleeca Bank',
        ['welcome'] = 'Willkommen beim Banking',
        ['balance'] = 'Saldo',
        ['account'] = 'Konto',
        ['amount'] = 'Betrag',
        ['confirm'] = 'Bestätigen',
        ['cancel'] = 'Abbrechen',
        ['close'] = 'Schließen',
        ['success'] = 'Erfolg',
        ['error'] = 'Fehler',
        ['warning'] = 'Warnung',
        ['info'] = 'Information',
        
        -- Account Management
        ['checking_account'] = 'Girokonto',
        ['savings_account'] = 'Sparkonto',
        ['account_balance'] = 'Kontostand',
        ['insufficient_funds'] = 'Unzureichende Mittel',
        ['account_not_found'] = 'Konto nicht gefunden',
        ['account_created'] = 'Konto erfolgreich erstellt',
        ['account_deleted'] = 'Konto erfolgreich gelöscht',
        
        -- Transactions
        ['deposit'] = 'Einzahlung',
        ['withdraw'] = 'Abheben',
        ['transfer'] = 'Überweisung',
        ['transaction_history'] = 'Transaktionsverlauf',
        ['transaction_completed'] = 'Transaktion erfolgreich abgeschlossen',
        ['transaction_failed'] = 'Transaktion fehlgeschlagen',
        ['enter_amount'] = 'Betrag eingeben',
        ['enter_target'] = 'Ziel-Spieler-ID eingeben',
        ['invalid_amount'] = 'Ungültiger Betrag',
        ['invalid_target'] = 'Ungültiges Ziel',
        ['minimum_amount'] = 'Mindestbetrag ist %s$',
        ['maximum_amount'] = 'Höchstbetrag ist %s$',
        ['transfer_fee'] = 'Überweisungsgebühr: %s$',
        ['self_transfer'] = 'Überweisung an sich selbst nicht möglich',
        ['player_not_found'] = 'Spieler nicht gefunden',
        
        -- ATM
        ['atm_access'] = 'Geldautomat verwenden',
        ['atm_card_required'] = 'Bankkarte erforderlich',
        ['atm_out_of_service'] = 'Geldautomat außer Betrieb',
        
        -- PIN
        ['enter_pin'] = 'PIN eingeben',
        ['pin_required'] = 'PIN erforderlich',
        ['pin_incorrect'] = 'Falsche PIN',
        ['pin_changed'] = 'PIN erfolgreich geändert',
        ['change_pin'] = 'PIN ändern',
        
        -- Interactions
        ['press_to_access'] = 'Drücken Sie [E] für Banking-Zugang',
        ['banking_accessed'] = 'Banking-System aufgerufen',
        ['too_far'] = 'Sie sind zu weit vom Geldautomaten/Bank entfernt',
        
        -- Savings
        ['create_savings'] = 'Sparkonto erstellen',
        ['deposit_savings'] = 'Auf Sparkonto einzahlen',
        ['withdraw_savings'] = 'Vom Sparkonto abheben',
        ['savings_interest'] = 'Zinssatz: %s%%',
        ['savings_created'] = 'Sparkonto erstellt',
        ['savings_deposit'] = '%s$ auf Sparkonto eingezahlt',
        ['savings_withdraw'] = '%s$ vom Sparkonto abgehoben',
        ['transfer_to'] = 'Überweisung an',
        ['transfer_from'] = 'Überweisung von',
        ['account_closure'] = 'Kontenschließung',
        
        -- Admin
        ['admin_panel'] = 'Admin-Panel',
        ['manage_accounts'] = 'Konten verwalten',
        ['view_logs'] = 'Protokolle anzeigen',
        ['insufficient_permission'] = 'Unzureichende Berechtigung',
        
        -- Errors
        ['database_error'] = 'Datenbankfehler aufgetreten',
        ['connection_error'] = 'Verbindungsfehler',
        ['timeout_error'] = 'Anfrage-Timeout',
        ['unknown_error'] = 'Unbekannter Fehler aufgetreten'
    },
    
    ['pt'] = {
        -- General
        ['bank_name'] = 'Banco Fleeca',
        ['welcome'] = 'Bem-vindo ao Banking',
        ['balance'] = 'Saldo',
        ['account'] = 'Conta',
        ['amount'] = 'Quantia',
        ['confirm'] = 'Confirmar',
        ['cancel'] = 'Cancelar',
        ['close'] = 'Fechar',
        ['success'] = 'Sucesso',
        ['error'] = 'Erro',
        ['warning'] = 'Aviso',
        ['info'] = 'Informação',
        
        -- Account Management
        ['checking_account'] = 'Conta Corrente',
        ['savings_account'] = 'Conta Poupança',
        ['account_balance'] = 'Saldo da Conta',
        ['insufficient_funds'] = 'Fundos insuficientes',
        ['account_not_found'] = 'Conta não encontrada',
        ['account_created'] = 'Conta criada com sucesso',
        ['account_deleted'] = 'Conta excluída com sucesso',
        
        -- Transactions
        ['deposit'] = 'Depósito',
        ['withdraw'] = 'Saque',
        ['transfer'] = 'Transferência',
        ['transaction_history'] = 'Histórico de Transações',
        ['transaction_completed'] = 'Transação concluída com sucesso',
        ['transaction_failed'] = 'Transação falhou',
        ['enter_amount'] = 'Digite a quantia',
        ['enter_target'] = 'Digite o ID do jogador de destino',
        ['invalid_amount'] = 'Quantia inválida',
        ['invalid_target'] = 'Destino inválido',
        ['minimum_amount'] = 'Quantia mínima é %s$',
        ['maximum_amount'] = 'Quantia máxima é %s$',
        ['transfer_fee'] = 'Taxa de transferência: %s$',
        ['self_transfer'] = 'Não é possível transferir para si mesmo',
        ['player_not_found'] = 'Jogador não encontrado',
        
        -- ATM
        ['atm_access'] = 'Acessar Caixa Eletrônico',
        ['atm_card_required'] = 'Cartão do banco necessário',
        ['atm_out_of_service'] = 'Caixa eletrônico fora de serviço',
        
        -- PIN
        ['enter_pin'] = 'Digite o PIN',
        ['pin_required'] = 'PIN necessário',
        ['pin_incorrect'] = 'PIN incorreto',
        ['pin_changed'] = 'PIN alterado com sucesso',
        ['change_pin'] = 'Alterar PIN',
        
        -- Interactions
        ['press_to_access'] = 'Pressione [E] para acessar o banco',
        ['banking_accessed'] = 'Sistema bancário acessado',
        ['too_far'] = 'Você está muito longe do Caixa Eletrônico/Banco',
        
        -- Savings
        ['create_savings'] = 'Criar Conta Poupança',
        ['deposit_savings'] = 'Depositar na Poupança',
        ['withdraw_savings'] = 'Sacar da Poupança',
        ['savings_interest'] = 'Taxa de Juros: %s%%',
        ['savings_created'] = 'Conta poupança criada',
        ['savings_deposit'] = 'Depositado %s$ na poupança',
        ['savings_withdraw'] = 'Sacado %s$ da poupança',
        ['transfer_to'] = 'Transferir para',
        ['transfer_from'] = 'Transferir de',
        ['account_closure'] = 'Fechamento de conta',
        
        -- Admin
        ['admin_panel'] = 'Painel de Administração',
        ['manage_accounts'] = 'Gerenciar Contas',
        ['view_logs'] = 'Ver Registros',
        ['insufficient_permission'] = 'Permissão insuficiente',
        
        -- Errors
        ['database_error'] = 'Erro de banco de dados ocorreu',
        ['connection_error'] = 'Erro de conexão',
        ['timeout_error'] = 'Tempo limite da solicitação',
        ['unknown_error'] = 'Erro desconhecido ocorreu'
    }
}
