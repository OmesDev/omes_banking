const { useState, useEffect, useRef } = React;

const BankingApp = () => {
    const [isVisible, setIsVisible] = useState(false);
    const [activeTab, setActiveTab] = useState('overview');
    const [bankName, setBankName] = useState('Bank');
    const [savingsAccountOpened, setSavingsAccountOpened] = useState(false);
    const [isATMMode, setIsATMMode] = useState(false);
    const [playerData, setPlayerData] = useState({
        name: 'John Doe',
        balance: 15750,
        accountNumber: '****-****-1234',
        savingsBalance: 8500,
        savingsAccountNumber: '****-****-5678',
        hasPin: false,
        pin: null
    });

    // PIN Setup State
    const [isPinModalOpen, setIsPinModalOpen] = useState(false);
    const [pinStep, setPinStep] = useState('setup'); // 'setup' or 'confirm'
    const [enteredPin, setEnteredPin] = useState('');
    const [confirmPin, setConfirmPin] = useState('');
    const [firstPin, setFirstPin] = useState('');
    const [isPinVisible, setIsPinVisible] = useState(false);
    const [pinError, setPinError] = useState('');
    
    // PIN Entry State (for ATM access)
    const [isPinEntryOpen, setIsPinEntryOpen] = useState(false);
    const [atmPin, setAtmPin] = useState('');
    const [atmPinError, setAtmPinError] = useState('');
    
    // Clear Confirmation Modal State
    const [isClearConfirmOpen, setIsClearConfirmOpen] = useState(false);
    
    // Quick actions modals
    const [isQuickActionModalOpen, setIsQuickActionModalOpen] = useState(false);
    const [quickActionType, setQuickActionType] = useState(''); // 'toSavings', 'toChecking', 'summary'
    const [quickActionAmount, setQuickActionAmount] = useState('');
    
    // Close savings account modal
    const [isCloseSavingsModalOpen, setIsCloseSavingsModalOpen] = useState(false);
    
    // Translation state
    const [translations, setTranslations] = useState({});
    
    // Translation function
    const t = (key, ...args) => {
        let translation = translations[key] || key;
        if (args.length > 0) {
            args.forEach((arg, index) => {
                translation = translation.replace('%s', arg);
            });
        }
        return translation;
    };

    // Generate random card number
    const generateCardNumber = (seed = '') => {
        // Use player name or identifier as seed for consistency
        let hash = 0;
        for (let i = 0; i < seed.length; i++) {
            const char = seed.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash; // Convert to 32-bit integer
        }
        
        // Generate 4 digits based on hash
        const num = Math.abs(hash) % 10000;
        return num.toString().padStart(4, '0');
    };

    // Generate savings card number (different from main card)
    const generateSavingsCardNumber = (seed = '') => {
        let hash = 0;
        for (let i = 0; i < seed.length; i++) {
            const char = seed.charCodeAt(i);
            hash = ((hash << 7) - hash) + char; // Different multiplier for different result
            hash = hash & hash;
        }
        
        const num = Math.abs(hash) % 10000;
        return num.toString().padStart(4, '0');
    };
    const [transferData, setTransferData] = useState({
        recipient: '',
        amount: '',
        description: ''
    });
    const [depositAmount, setDepositAmount] = useState('');
    const [withdrawAmount, setWithdrawAmount] = useState('');

    // Format currency input with dollar sign and commas
    const formatCurrencyInput = (value) => {
        // Remove all non-numeric characters except decimal point
        const numericValue = value.replace(/[^\d.]/g, '');
        
        // Handle empty input
        if (!numericValue) return '';
        
        // Split by decimal point
        const parts = numericValue.split('.');
        
        // Format the integer part with commas
        const integerPart = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ',');
        
        // Reconstruct the number with decimal if present
        let formattedValue = integerPart;
        if (parts.length > 1) {
            // Limit decimal places to 2
            const decimalPart = parts[1].substring(0, 2);
            formattedValue = `${integerPart}.${decimalPart}`;
        }
        
        return `$${formattedValue}`;
    };

    // Extract numeric value from formatted currency string
    const extractNumericValue = (formattedValue) => {
        return formattedValue.replace(/[$,]/g, '');
    };

    const [transferAmount, setTransferAmount] = useState('');
    const [transferDirection, setTransferDirection] = useState('checking-to-savings');
    const [transactions, setTransactions] = useState([]);
    const [balanceHistory, setBalanceHistory] = useState([]);
    const [searchTerm, setSearchTerm] = useState('');
    const [filterType, setFilterType] = useState('all');
    const [sortBy, setSortBy] = useState('date');
    const chartRef = useRef(null);
    const chartInstance = useRef(null);

    useEffect(() => {
        const handleMessage = (event) => {
            const data = event.data;
            if (data.type === 'openBank') {
                setIsVisible(true);
                setIsATMMode(data.isATM || false); // Set ATM mode based on flag
                setPlayerData(data.playerData || playerData);
                setBankName(data.bankName || 'Bank');
                setTransactions(data.transactions || []);
                setBalanceHistory(data.balanceHistory || []);
                setTranslations(data.translations || {});
                
                // Set default tab based on mode
                if (data.isATM) {
                    setActiveTab('withdraw'); // Start with withdraw for ATM
                } else {
                    setActiveTab('overview'); // Start with overview for bank
                }
            } else if (data.type === 'closeBank') {
                setIsVisible(false);
                setIsATMMode(false); // Reset ATM mode
            } else if (data.type === 'updateTransactions') {
                setTransactions(data.transactions || []);
            } else if (data.type === 'updateBankingData') {
                setPlayerData(data.playerData || playerData);
                setTransactions(data.transactions || []);
                setBalanceHistory(data.balanceHistory || []);
            } else if (data.type === 'pinSetupSuccess') {
                setPlayerData(prev => ({
                    ...prev,
                    hasPin: true,
                    pin: data.pin
                }));
            } else if (data.type === 'showPinEntry') {
                setIsPinEntryOpen(true);
                setAtmPin('');
                setAtmPinError('');
                setIsVisible(false);
            } else if (data.type === 'pinVerificationSuccess') {
                setIsPinEntryOpen(false);
                setAtmPin('');
                setAtmPinError('');
            } else if (data.type === 'pinVerificationFailed') {
                setAtmPinError('Incorrect PIN. Please try again.');
                setAtmPin('');
                setTimeout(() => {
                    setAtmPinError('');
                }, 3000);
            } else if (data.type === 'savingsAccountClosed') {
                // Refresh player data from server after savings account closure
                fetch(`https://${GetParentResourceName()}/getPlayerData`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({})
                }).then(response => response.json())
                .then(data => {
                    setPlayerData(data);
                });
            }
        };

        const handleKeyDown = (event) => {
            if (event.key === 'Escape' && isVisible) {
                closeBank();
            }
        };

        window.addEventListener('message', handleMessage);
        window.addEventListener('keydown', handleKeyDown);

        return () => {
            window.removeEventListener('message', handleMessage);
            window.removeEventListener('keydown', handleKeyDown);
        };
    }, [isVisible]);

    // Cleanup chart when switching away from overview tab or component unmounts
    useEffect(() => {
        return () => {
            if (chartInstance.current) {
                chartInstance.current.destroy();
                chartInstance.current = null;
            }
        };
    }, [activeTab]);

    // Create or update chart when balance history changes or when switching to overview tab
    useEffect(() => {
        if (isVisible && activeTab === 'overview' && balanceHistory.length > 0 && chartRef.current) {
            // Small delay to ensure the canvas is properly mounted
            setTimeout(() => {
                createBalanceChart();
            }, 100);
        }
        
        return () => {
            if (chartInstance.current) {
                chartInstance.current.destroy();
                chartInstance.current = null;
            }
        };
    }, [balanceHistory, isVisible, activeTab]);

    const createBalanceChart = () => {
        if (!chartRef.current) return;
        
        if (chartInstance.current) {
            chartInstance.current.destroy();
            chartInstance.current = null;
        }

        const ctx = chartRef.current.getContext('2d');
        
        // Create diagonal line pattern for background
        const createDiagonalPattern = () => {
            const patternCanvas = document.createElement('canvas');
            const patternContext = patternCanvas.getContext('2d');
            
            // Set pattern size (smaller for more lines)
            patternCanvas.width = 6;
            patternCanvas.height = 6;
            
            // Set line style (less transparent and thicker)
            patternContext.strokeStyle = 'rgba(34, 197, 94, 0.35)';
            patternContext.lineWidth = 1.5;
            patternContext.lineCap = 'round';
            
            // Draw diagonal lines (more lines in smaller space)
            patternContext.beginPath();
            patternContext.moveTo(0, 6);
            patternContext.lineTo(6, 0);
            patternContext.moveTo(-1, 1);
            patternContext.lineTo(1, -1);
            patternContext.moveTo(5, 7);
            patternContext.lineTo(7, 5);
            patternContext.stroke();
            
            return ctx.createPattern(patternCanvas, 'repeat');
        };
        
        // Improved date formatting for better readability
        const labels = balanceHistory.map(item => {
            const date = new Date(item.date + 'T00:00:00'); // Ensure proper date parsing
            const today = new Date();
            const yesterday = new Date(today);
            yesterday.setDate(yesterday.getDate() - 1);
            
            // Format dates more clearly
            if (date.toDateString() === today.toDateString()) {
                return 'Today';
            } else if (date.toDateString() === yesterday.toDateString()) {
                return 'Yesterday';
            } else {
                return date.toLocaleDateString('en-US', { 
                    weekday: 'short',
                    month: 'short', 
                    day: 'numeric' 
                });
            }
        });
        
        const data = balanceHistory.map(item => item.balance);

        chartInstance.current = new Chart(ctx, {
            type: 'line',
            data: {
                labels: labels,
                datasets: [{
                    label: t('account_balance') || 'Account Balance',
                    data: data,
                    borderColor: '#22c55e',
                    backgroundColor: createDiagonalPattern(),
                    borderWidth: 2,
                    fill: true,
                    tension: 0.4,
                    pointRadius: 0,
                    pointHoverRadius: 6,
                    pointHoverBackgroundColor: '#22c55e',
                    pointHoverBorderColor: '#ffffff',
                    pointHoverBorderWidth: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                interaction: {
                    intersect: false,
                    mode: 'index'
                },
                plugins: {
                    legend: {
                        display: false
                    },
                    tooltip: {
                        backgroundColor: 'rgba(26, 26, 26, 0.95)',
                        titleColor: '#ffffff',
                        bodyColor: '#22c55e',
                        borderColor: '#2d2d2d',
                        borderWidth: 1,
                        cornerRadius: 8,
                        displayColors: false,
                        titleFont: {
                            size: 12,
                            weight: '600'
                        },
                        bodyFont: {
                            size: 14,
                            weight: '700'
                        },
                        callbacks: {
                            title: function(context) {
                                return context[0].label;
                            },
                            label: function(context) {
                                return '$' + context.parsed.y.toLocaleString();
                            }
                        }
                    }
                },
                scales: {
                    x: {
                        display: true,
                        grid: {
                            display: false
                        },
                        border: {
                            display: false
                        },
                        ticks: {
                            color: '#94a3b8',
                            font: {
                                size: 11,
                                weight: '500'
                            },
                            padding: 10
                        }
                    },
                    y: {
                        display: false,
                        grid: {
                            display: false
                        },
                        border: {
                            display: false
                        }
                    }
                },
                elements: {
                    point: {
                        hoverBackgroundColor: '#22c55e'
                    }
                },
                animation: {
                    duration: 1000,
                    easing: 'easeInOutQuart'
                }
            }
        });
    };

    const closeBank = () => {
        setIsVisible(false);
        fetch(`https://${GetParentResourceName()}/closeBank`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    };

    const handleTransfer = () => {
        const numericAmount = extractNumericValue(transferData.amount);
        if (!transferData.recipient || !numericAmount || numericAmount <= 0) {
            return;
        }

        fetch(`https://${GetParentResourceName()}/transfer`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                ...transferData,
                amount: numericAmount
            })
        }).then(() => {
            setTransferData({ recipient: '', amount: '', description: '' });
        });
    };

    const handleDeposit = () => {
        const numericAmount = extractNumericValue(depositAmount);
        if (!numericAmount || numericAmount <= 0) return;

        fetch(`https://${GetParentResourceName()}/deposit`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ amount: numericAmount })
        }).then(() => {
            setDepositAmount('');
        });
    };

    const handleWithdraw = () => {
        const numericAmount = extractNumericValue(withdrawAmount);
        if (!numericAmount || numericAmount <= 0) return;

        fetch(`https://${GetParentResourceName()}/withdraw`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ amount: numericAmount })
        }).then(() => {
            setWithdrawAmount('');
        });
    };

    const openSavingsAccount = () => {
        if (!playerData.allowSavingsAccounts) {
            return;
        }
        fetch(`https://${GetParentResourceName()}/openSavingsAccount`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    };



        const handleAccountTransfer = () => {
        const numericAmount = extractNumericValue(transferAmount);
        if (!numericAmount || numericAmount <= 0) return;

        const [fromAccount, toAccount] = transferDirection.split('-to-');
        
        if (!playerData.allowSavingsAccounts && (fromAccount === 'savings' || toAccount === 'savings')) {
            return;
        }
        
        fetch(`https://${GetParentResourceName()}/transferBetweenAccounts`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                fromAccount: fromAccount,
                toAccount: toAccount,
                amount: numericAmount
            })
        }).then(() => {
            setTransferAmount('');
        });
    };

    // PIN Setup Functions
    const openPinModal = () => {
        setIsPinModalOpen(true);
        setPinStep('setup');
        setEnteredPin('');
        setConfirmPin('');
        setFirstPin('');
        setPinError('');
    };

    const closePinModal = () => {
        setIsPinModalOpen(false);
        setPinStep('setup');
        setEnteredPin('');
        setConfirmPin('');
        setFirstPin('');
        setPinError('');
    };

    const handleNumberPad = (digit) => {
        if (pinStep === 'setup') {
            if (enteredPin.length < 4) {
                setEnteredPin(enteredPin + digit);
            }
        } else if (pinStep === 'confirm') {
            if (confirmPin.length < 4) {
                setConfirmPin(confirmPin + digit);
            }
        }
    };

    const handlePinBackspace = () => {
        if (pinStep === 'setup') {
            setEnteredPin(enteredPin.slice(0, -1));
        } else if (pinStep === 'confirm') {
            setConfirmPin(confirmPin.slice(0, -1));
        }
    };

    const handlePinNext = () => {
        if (pinStep === 'setup' && enteredPin.length === 4) {
            setFirstPin(enteredPin);
            setPinStep('confirm');
            setConfirmPin('');
            setPinError(''); // Clear any previous errors
        } else if (pinStep === 'confirm' && confirmPin.length === 4) {
            if (firstPin === confirmPin) {
                // PIN matches, send to backend
                fetch(`https://${GetParentResourceName()}/setupPin`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ pin: confirmPin })
        }).then(() => {
                    // Update local state immediately
                    setPlayerData(prev => ({
                        ...prev,
                        hasPin: true,
                        pin: confirmPin
                    }));
                    closePinModal();
                });
            } else {
                // PIN doesn't match, show error and reset to setup
                setPinError('PINs do not match. Please try again.');
                setPinStep('setup');
                setEnteredPin('');
                setConfirmPin('');
                setFirstPin('');
                
                // Clear error after 3 seconds
                setTimeout(() => {
                    setPinError('');
                }, 3000);
            }
        }
    };

    const togglePinVisibility = () => {
        setIsPinVisible(!isPinVisible);
    };

    // PIN Entry Functions (for ATM access)
    const handleAtmPinEntry = (digit) => {
        if (atmPin.length < 4) {
            setAtmPin(atmPin + digit);
        }
    };

    const handleAtmPinBackspace = () => {
        setAtmPin(atmPin.slice(0, -1));
    };

    const handleAtmPinSubmit = () => {
        if (atmPin.length === 4) {
            fetch(`https://${GetParentResourceName()}/verifyPin`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ pin: atmPin })
            });
        }
    };

    const closeAtmPinEntry = () => {
        setIsPinEntryOpen(false);
        setAtmPin('');
        setAtmPinError('');
        fetch(`https://${GetParentResourceName()}/closePinEntry`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    };

    const handleClearAllTransactions = () => {
        setIsClearConfirmOpen(true);
    };

    const confirmClearTransactions = () => {
        fetch(`https://${GetParentResourceName()}/clearAllTransactions`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).then(() => {
            setTransactions([]);
            setIsClearConfirmOpen(false);
        });
    };

    const cancelClearTransactions = () => {
        setIsClearConfirmOpen(false);
    };

    // Quick Action Functions
    const openQuickActionModal = (type) => {
        if (!playerData.allowSavingsAccounts && (type === 'toSavings' || type === 'toChecking')) {
            return;
        }
        setQuickActionType(type);
        setQuickActionAmount('');
        setIsQuickActionModalOpen(true);
    };

    const closeQuickActionModal = () => {
        setIsQuickActionModalOpen(false);
        setQuickActionType('');
        setQuickActionAmount('');
    };

    const handleQuickActionSubmit = () => {
        if (quickActionType === 'summary') {
            // Close modal and show summary
            closeQuickActionModal();
            return;
        }

        const amount = parseFloat(quickActionAmount);
        if (!amount || amount <= 0) return;

        if (quickActionType === 'toSavings') {
            setTransferDirection('checking-to-savings');
            setTransferAmount(amount.toString());
            handleAccountTransfer();
        } else if (quickActionType === 'toChecking') {
            setTransferDirection('savings-to-checking');
            setTransferAmount(amount.toString());
            handleAccountTransfer();
        }

        closeQuickActionModal();
    };

    // Close Savings Account Functions
    const openCloseSavingsModal = () => {
        if (!playerData.allowSavingsAccounts) {
            return;
        }
        setIsCloseSavingsModalOpen(true);
    };

    const closeCloseSavingsModal = () => {
        setIsCloseSavingsModalOpen(false);
    };

    const handleCloseSavingsAccount = () => {
        fetch(`https://${GetParentResourceName()}/closeSavingsAccount`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).then(() => {
            // Close the modal first
            closeCloseSavingsModal();
            // Switch to overview tab after closing savings
            setActiveTab('overview');
            // The server will send a refresh event that will update the data
        });
    };

    const formatCurrency = (amount) => {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(amount);
    };

    const formatTransactionDate = (dateString) => {
        // Handle MySQL datetime format (YYYY-MM-DD HH:MM:SS)
        // Convert to a format that JavaScript Date can properly parse
        let date;
        if (typeof dateString === 'string' && dateString.includes(' ')) {
            // MySQL datetime format: "2024-01-15 14:30:00"
            // Replace space with 'T' to make it ISO format compatible
            const isoString = dateString.replace(' ', 'T');
            date = new Date(isoString);
        } else {
            date = new Date(dateString);
        }
        
        // Check if date is valid
        if (isNaN(date.getTime())) {
            console.error('Invalid date string:', dateString);
            return { date: 'Invalid Date', time: 'Invalid Time' };
        }
        
        const dateStr = date.toLocaleDateString('en-US', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit'
        });
        const timeStr = date.toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit',
            hour12: false
        });
        return { date: dateStr, time: timeStr };
    };

    const getTransactionIcon = (type) => {
        switch (type) {
            case 'deposit': return 'fas fa-arrow-down';
            case 'withdrawal': return 'fas fa-arrow-up';
            case 'transfer_out': return 'fas fa-arrow-right';
            case 'transfer_in': return 'fas fa-arrow-left';
            case 'fee': return 'fas fa-percentage';
            case 'savings_deposit': return 'fas fa-piggy-bank';
            case 'savings_withdrawal': return 'fas fa-coins';
            case 'savings_opened': return 'fas fa-plus-circle';
            case 'account_transfer': return 'fas fa-exchange-alt';
            default: return 'fas fa-dollar-sign';
        }
    };

    const getTransactionAmount = (transaction) => {
        // For outgoing transactions (withdrawal, transfer_out, fee, savings_deposit), show as negative
        if (transaction.type === 'withdrawal' || transaction.type === 'transfer_out' || transaction.type === 'fee' || transaction.type === 'savings_deposit') {
            return -Math.abs(transaction.amount);
        }
        // For incoming transactions (deposit, transfer_in, savings_withdrawal), show as positive
        if (transaction.type === 'deposit' || transaction.type === 'transfer_in' || transaction.type === 'savings_withdrawal') {
            return Math.abs(transaction.amount);
        }
        // For account transfers, show as positive (just the amount being moved)
        if (transaction.type === 'account_transfer') {
            return Math.abs(transaction.amount);
        }
        // For savings account opening (no money involved), show as 0
        if (transaction.type === 'savings_opened') {
            return 0;
        }
        // Default to positive
        return Math.abs(transaction.amount);
    };

    const handleQuickWithdraw = (amount) => {
        if (amount <= playerData.balance) {
            fetch(`https://${GetParentResourceName()}/withdraw`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ amount: amount })
            });
        }
    };

    const handleQuickDeposit = (amount) => {
        fetch(`https://${GetParentResourceName()}/deposit`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ amount: amount })
        });
    };

    const renderATMOverview = () => (
        <div>
            <div className="atm-layout">
                <div className="atm-card-section">
                    <div className="credit-card">
                        <div className="card-background">
                            <div className="card-header">
                                <div className="bank-name">{bankName}</div>
                                <div className="card-type">DEBIT</div>
                            </div>
                            <div className="card-number">
                                <span>•••• •••• •••• {generateCardNumber(playerData.name || 'default')}</span>
                            </div>
                            <div className="card-footer">
                                <div className="card-holder">
                                    <div className="label">CARD HOLDER</div>
                                    <div className="name">{playerData.name || 'Unknown'}</div>
                                </div>
                                <div className="card-balance">
                                    <div className="label">BALANCE</div>
                                    <div className="amount">{formatCurrency(playerData.balance || 0)}</div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div className="atm-info-section">
                    <div className="atm-balance-display">
                        <div className="balance-label-small">{t('account_balance')}</div>
                        <div className="balance-amount-small">{formatCurrency(playerData.balance || 0)}</div>
                    </div>
                    
                    <div className="transaction-history">
                        <h3 className="section-title">{t('transaction_history')}</h3>
                        {transactions.length > 0 ? (
                            transactions.slice(0, 3).map(transaction => {
                                const { date, time } = formatTransactionDate(transaction.date);
                                const amount = getTransactionAmount(transaction);
                                return (
                                    <div key={transaction.id} className="transaction-item">
                                        <div className="transaction-info">
                                            <div className="transaction-icon">
                                                <i className={getTransactionIcon(transaction.type)}></i>
                                            </div>
                                            <div className="transaction-details">
                                                <h4>{transaction.description}</h4>
                                                <p>{date} at {time}</p>
                                            </div>
                                        </div>
                                        <div className={`transaction-amount ${amount < 0 ? 'negative' : ''}`}>
                                            {formatCurrency(Math.abs(amount))}
                                        </div>
                                    </div>
                                );
                            })
                        ) : (
                            <div className="no-transactions-overview">
                                <i className="fas fa-history"></i>
                                <h3>{t('transaction_history')}</h3>
                                <p>{t('transaction_history')}</p>
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );

    const renderATMInterface = () => (
        <div>
            <div className="atm-single-layout">
                <div className="atm-card-section">
                    <div className="credit-card">
                        <div className="card-background">
                            <div className="card-header">
                                <div className="bank-name">{bankName}</div>
                                <div className="card-type">DEBIT</div>
                            </div>
                            <div className="card-number">
                                <span>•••• •••• •••• {generateCardNumber(playerData.name || 'default')}</span>
                            </div>
                            <div className="card-footer">
                                <div className="card-holder">
                                    <div className="label">CARD HOLDER</div>
                                    <div className="name">{playerData.name || 'Unknown'}</div>
                                </div>
                                <div className="card-balance">
                                    <div className="label">BALANCE</div>
                                    <div className="amount">{formatCurrency(playerData.balance || 0)}</div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <div className="atm-transfer-section">
                        <div className="action-header">
                            <i className="fas fa-paper-plane"></i>
                            <h3>{t('transfer')}</h3>
                        </div>
                        <div className="atm-transfer-form">
                            <div className="form-group-enhanced">
                                <input
                                    type="text"
                                    className="form-input-enhanced"
                                    placeholder={t('enter_target')}
                                    value={transferData.recipient}
                                    onChange={(e) => setTransferData({...transferData, recipient: e.target.value})}
                                />
                            </div>
                            <div className="form-group-enhanced">
                                <input
                                    type="number"
                                    className="form-input-enhanced"
                                    placeholder={t('amount')}
                                    value={transferData.amount}
                                    onChange={(e) => setTransferData({...transferData, amount: e.target.value})}
                                />
                            </div>
                            <div className="form-group-enhanced">
                                <input
                                    type="text"
                                    className="form-input-enhanced"
                                    placeholder={t('enter_amount')}
                                    value={transferData.description}
                                    onChange={(e) => setTransferData({...transferData, description: e.target.value})}
                                />
                            </div>
                            <button 
                                className="atm-transfer-btn" 
                                onClick={handleTransfer}
                                disabled={!transferData.recipient || !transferData.amount || parseFloat(transferData.amount) <= 0 || parseFloat(transferData.amount) > (playerData.balance || 0)}
                            >
                                <i className="fas fa-paper-plane"></i>
                                Send Transfer
                            </button>
                        </div>
                    </div>
                </div>
                
                <div className="atm-functions-section">
                    <div className="atm-balance-display">
                        <div className="balance-label-small">{t('account_balance')}</div>
                        <div className="balance-amount-small">{formatCurrency(playerData.balance || 0)}</div>
                    </div>
                    
                    <div className="atm-quick-actions">
                        <div className="atm-action-grid">
                            <div className="atm-action-card withdraw-card">
                                <div className="action-header">
                                    <i className="fas fa-minus"></i>
                                    <h3>{t('withdraw')}</h3>
                                </div>
                                <div className="quick-amounts">
                                    {[20, 50, 100, 200, 500, 1000].map(amount => (
                                        <button
                                            key={amount}
                                            className="quick-amount-btn"
                                            onClick={() => handleQuickWithdraw(amount)}
                                            disabled={amount > (playerData.balance || 0)}
                                        >
                                            {formatCurrency(amount)}
                                        </button>
                                    ))}
                                </div>
                                <div className="custom-amount-section">
                                    <input
                                        type="number"
                                        className="custom-amount-input"
                                        placeholder="Other amount"
                                        value={withdrawAmount}
                                        onChange={(e) => setWithdrawAmount(e.target.value)}
                                    />
                                    <button 
                                        className="custom-withdraw-btn"
                                        onClick={handleWithdraw}
                                        disabled={!withdrawAmount || withdrawAmount <= 0 || withdrawAmount > (playerData.balance || 0)}
                                    >
                                        Withdraw
                                    </button>
                                </div>
                            </div>
                            
                            <div className="atm-action-card deposit-card">
                                <div className="action-header">
                                    <i className="fas fa-plus"></i>
                                    <h3>{t('deposit')}</h3>
                                </div>
                                <div className="quick-amounts">
                                    {[100, 500, 1000, 2500, 5000, 10000].map(amount => (
                                        <button
                                            key={amount}
                                            className="quick-amount-btn deposit"
                                            onClick={() => handleQuickDeposit(amount)}
                                        >
                                            {formatCurrency(amount)}
                                        </button>
                                    ))}
                                </div>
                                <div className="custom-amount-section">
                                    <input
                                        type="number"
                                        className="custom-amount-input"
                                        placeholder="Other amount"
                                        value={depositAmount}
                                        onChange={(e) => setDepositAmount(e.target.value)}
                                    />
                                    <button 
                                        className="custom-deposit-btn"
                                        onClick={handleDeposit}
                                        disabled={!depositAmount || depositAmount <= 0}
                                    >
                                        Deposit
                                    </button>
                                </div>
                            </div>
                        </div>
                        
                        <div className="atm-history-section">
                            <div className="action-header">
                                <i className="fas fa-history"></i>
                                <h3>Recent Transactions</h3>
                            </div>
                            <div className="atm-transactions">
                                {transactions.length > 0 ? (
                                    transactions.slice(0, 4).map(transaction => {
                                        const { date, time } = formatTransactionDate(transaction.date);
                                        const amount = getTransactionAmount(transaction);
                                        return (
                                            <div key={transaction.id} className="atm-transaction-item">
                                                <div className="transaction-info">
                                                    <div className="transaction-icon">
                                                        <i className={getTransactionIcon(transaction.type)}></i>
                                                    </div>
                                                    <div className="transaction-details">
                                                        <h4>{transaction.description}</h4>
                                                        <p>{date}</p>
                                                    </div>
                                                </div>
                                                <div className={`transaction-amount ${amount < 0 ? 'negative' : ''}`}>
                                                    {formatCurrency(Math.abs(amount))}
                                                </div>
                                            </div>
                                        );
                                    })
                                ) : (
                                    <div className="no-transactions-overview">
                                        <i className="fas fa-history"></i>
                                        <h3>{t('transaction_history')}</h3>
                                        <p>{t('transaction_history')}</p>
                                    </div>
                                )}
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );

    const renderOverview = () => (
        <div>
            <div className="overview-layout">
                <div className="left-section">
                    <div className="credit-card">
                        <div className="card-background">
                            <div className="card-header">
                                <div className="bank-name">{bankName}</div>
                                <div className="card-type-section">
                                    {!playerData.hasPin ? (
                                        <button className="pin-setup-btn" onClick={openPinModal}>
                                            <i className="fas fa-lock"></i>
                                            Set up PIN
                                        </button>
                                    ) : (
                                        <div className="pin-display-section">
                                            <button className="pin-edit-btn" onClick={openPinModal}>
                                                <i className="fas fa-pencil-alt"></i>
                                            </button>
                                            <button className="pin-toggle-btn" onClick={togglePinVisibility}>
                                                <i className={`fas ${isPinVisible ? 'fa-eye-slash' : 'fa-eye'}`}></i>
                                            </button>
                                            <span className="pin-text">
                                                {isPinVisible ? playerData.pin : '••••'}
                                            </span>
                                        </div>
                                    )}
                                <div className="card-type">DEBIT</div>
                                </div>
                            </div>
                            <div className="card-number">
                                <span>•••• •••• •••• {generateCardNumber(playerData.name || 'default')}</span>
                            </div>
                            <div className="card-footer">
                                <div className="card-holder">
                                    <div className="label">CARD HOLDER</div>
                                    <div className="name">{playerData.name || 'Unknown'}</div>
                                </div>
                                <div className="card-balance">
                                    <div className="label">BALANCE</div>
                                    <div className="amount">{formatCurrency(playerData.balance || 0)}</div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    {playerData.allowSavingsAccounts && (
                        <div className="credit-card">
                            <div className={`card-background savings-card ${!playerData.hasSavingsAccount ? 'blurred' : ''}`}>
                                <div className="card-header">
                                    <div className="bank-name">{bankName}</div>
                                    <div className="card-type">SAVINGS</div>
                                </div>
                                <div className="card-number">
                                    <span>•••• •••• •••• {generateSavingsCardNumber(playerData.name || 'default')}</span>
                                </div>
                                <div className="card-footer">
                                    <div className="card-holder">
                                        <div className="label">CARD HOLDER</div>
                                        <div className="name">{playerData.name || 'Unknown'}</div>
                                    </div>
                                    <div className="card-balance">
                                        <div className="label">BALANCE</div>
                                        <div className="amount">{formatCurrency(playerData.savingsBalance || 0)}</div>
                                    </div>
                                </div>
                                
                                {!playerData.hasSavingsAccount && (
                                    <div className="savings-overlay" onClick={openSavingsAccount}>
                                        <div className="overlay-content">
                                            <div className="plus-icon">
                                                <i className="fas fa-plus"></i>
                                            </div>
                                            <div className="overlay-text">{t('create_savings')}</div>
                                        </div>
                                    </div>
                                )}
                            </div>
                        </div>
                    )}
                </div>
                
                <div className="right-section">
                    <div className="balance-chart-container">
                        <div className="chart-title-container">
                            <h3 className="section-title">Balance Trend</h3>
                            <span className="time-period-tag">Last 7 Days</span>
                        </div>
                        <div className="chart-wrapper">
                            <canvas ref={chartRef} id="balanceChart"></canvas>
                        </div>
                    </div>
                    
                    <div className="transaction-history">
                        <h3 className="section-title">{t('transaction_history')}</h3>
                        {transactions.length > 0 ? (
                            transactions.slice(0, 5).map(transaction => {
                                const { date, time } = formatTransactionDate(transaction.date);
                                const amount = getTransactionAmount(transaction);
                                return (
                            <div key={transaction.id} className="transaction-item">
                                <div className="transaction-info">
                                    <div className="transaction-icon">
                                        <i className={getTransactionIcon(transaction.type)}></i>
                                    </div>
                                    <div className="transaction-details">
                                        <h4>{transaction.description}</h4>
                                                <p>{date} at {time}</p>
                                            </div>
                                        </div>
                                        <div className={`transaction-amount ${amount < 0 ? 'negative' : ''}`}>
                                            {formatCurrency(Math.abs(amount))}
                                        </div>
                                    </div>
                                );
                            })
                        ) : (
                            <div className="no-transactions-overview">
                                <i className="fas fa-history"></i>
                                <h3>{t('transaction_history')}</h3>
                                <p>{t('transaction_history')}</p>
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );

    const renderTransfer = () => {
        const numericTransferAmount = extractNumericValue(transferData.amount);
        const isFormValid = transferData.recipient && numericTransferAmount && parseFloat(numericTransferAmount) > 0;
        const transferAmount = parseFloat(numericTransferAmount) || 0;
        const hasEnoughBalance = transferAmount <= playerData.balance;

        return (
            <div className="transfer-layout">
                <div className="transfer-form-section">
                    <h3 className="section-title">Send Money</h3>
                    <div className="form-group-enhanced">
                        <label className="form-label-enhanced">Recipient ID</label>
                <input
                    type="text"
                            className="form-input-enhanced"
                            placeholder={t('enter_target')}
                    value={transferData.recipient}
                    onChange={(e) => setTransferData({...transferData, recipient: e.target.value})}
                />
            </div>
                    <div className="form-group-enhanced">
                        <label className="form-label-enhanced">Amount</label>
                <input
                    type="text"
                            className="form-input-enhanced"
                            placeholder={t('amount')}
                    value={transferData.amount}
                    onChange={(e) => setTransferData({...transferData, amount: formatCurrencyInput(e.target.value)})}
                />
            </div>
                    <div className="form-group-enhanced">
                        <label className="form-label-enhanced">Description (Optional)</label>
                <input
                    type="text"
                            className="form-input-enhanced"
                            placeholder={t('enter_amount')}
                    value={transferData.description}
                    onChange={(e) => setTransferData({...transferData, description: e.target.value})}
                />
            </div>
                    <button 
                        className="transfer-action-btn" 
                        onClick={handleTransfer}
                        disabled={!isFormValid || !hasEnoughBalance}
                    >
                <i className="fas fa-paper-plane"></i>
                Send Transfer
            </button>
                    {!hasEnoughBalance && transferAmount > 0 && (
                        <p style={{color: '#ef4444', fontSize: '14px', marginTop: '10px', textAlign: 'center'}}>
                            Insufficient balance for this transfer
                        </p>
                    )}
                </div>
                
                <div className="transfer-preview-section">
                    <div className="account-balance-card">
                        <div className="balance-label-small">{t('account_balance')}</div>
                        <div className="balance-amount-small">{formatCurrency(playerData.balance || 0)}</div>
                    </div>
                    
                    <div className="transfer-preview-card">
                        <div className="preview-header">
                            <div className="preview-icon">
                                <i className="fas fa-paper-plane"></i>
                            </div>
                            <div className="preview-title">Transfer Preview</div>
                        </div>
                        <div className="preview-details">
                            <div className="preview-row">
                                <span className="preview-label">To:</span>
                                <span className="preview-value">{transferData.recipient || 'Not specified'}</span>
                            </div>
                            <div className="preview-row">
                                <span className="preview-label">Description:</span>
                                <span className="preview-value">{transferData.description || 'No description'}</span>
                            </div>
                            <div className="preview-row">
                                <span className="preview-label">Amount:</span>
                                <span className="preview-amount">{formatCurrency(transferAmount)}</span>
                            </div>
                        </div>
                    </div>
                </div>
        </div>
    );
    };

    const renderDeposit = () => {
        const numericDepositAmount = extractNumericValue(depositAmount);
        const isValidAmount = numericDepositAmount && parseFloat(numericDepositAmount) > 0;
        const depositValue = parseFloat(numericDepositAmount) || 0;
        const newBalance = (playerData.balance || 0) + depositValue;
        
        const suggestedAmounts = [100, 500, 1000, 2500, 5000, 10000];
        
        return (
            <div className="deposit-layout">
                <div className="deposit-form-section">
            <h3 className="section-title">{t('deposit')}</h3>
                    
                    <div className="form-group-enhanced">
                <input
                    type="text"
                            className="form-input-enhanced"
                            placeholder={t('amount')}
                    value={depositAmount}
                    onChange={(e) => setDepositAmount(formatCurrencyInput(e.target.value))}
                />
            </div>
                    
                    <div className="amount-suggestions">
                        {suggestedAmounts.map(amount => (
                            <button
                                key={amount}
                                className="suggestion-btn"
                                onClick={() => setDepositAmount(formatCurrencyInput(amount.toString()))}
                            >
                                ${amount.toLocaleString()}
                            </button>
                        ))}
                    </div>
                    
                    <button 
                        className="deposit-action-btn" 
                        onClick={handleDeposit}
                        disabled={!isValidAmount}
                    >
                <i className="fas fa-plus"></i>
                {t('deposit')}
            </button>
                </div>
                
                <div className="deposit-info-section">
                    <div className="account-balance-card">
                        <div className="balance-label-small">{t('account_balance')}</div>
                        <div className="balance-amount-small">{formatCurrency(playerData.balance || 0)}</div>
                    </div>
                    
                    <div className="deposit-preview-card">
                        <div className="preview-header">
                            <div className="preview-icon">
                                <i className="fas fa-plus"></i>
                            </div>
                            <div className="preview-title">Deposit Preview</div>
                        </div>
                        
                        <div className="preview-details">
                            <div className="preview-row">
                                <span className="preview-label">Deposit Amount:</span>
                                <span className="preview-amount">{formatCurrency(depositValue)}</span>
                            </div>
                            <div className="preview-row">
                                <span className="preview-label">New Balance:</span>
                                <span className="preview-value">{formatCurrency(newBalance)}</span>
                            </div>
                        </div>
                    </div>
                </div>
        </div>
    );
    };

    const renderWithdraw = () => {
        const numericWithdrawAmount = extractNumericValue(withdrawAmount);
        const isValidAmount = numericWithdrawAmount && parseFloat(numericWithdrawAmount) > 0;
        const withdrawValue = parseFloat(numericWithdrawAmount) || 0;
        const newBalance = (playerData.balance || 0) - withdrawValue;
        const hasEnoughBalance = withdrawValue <= (playerData.balance || 0);
        
        const suggestedAmounts = [50, 100, 200, 500, 1000, 2000];
        
        return (
            <div className="withdraw-layout">
                <div className="withdraw-form-section">
            <h3 className="section-title">{t('withdraw')}</h3>
                    
                    <div className="form-group-enhanced">
                <input
                    type="text"
                            className="form-input-enhanced"
                            placeholder={t('amount')}
                    value={withdrawAmount}
                    onChange={(e) => setWithdrawAmount(formatCurrencyInput(e.target.value))}
                />
            </div>
                    
                    <div className="amount-suggestions">
                        {suggestedAmounts.map(amount => (
                            <button
                                key={amount}
                                className="suggestion-btn"
                                onClick={() => setWithdrawAmount(formatCurrencyInput(amount.toString()))}
                                disabled={amount > (playerData.balance || 0)}
                                style={{
                                    opacity: amount > (playerData.balance || 0) ? 0.5 : 1,
                                    cursor: amount > (playerData.balance || 0) ? 'not-allowed' : 'pointer'
                                }}
                            >
                                ${amount.toLocaleString()}
                            </button>
                        ))}
                    </div>
                    
                    <button 
                        className="withdraw-action-btn" 
                        onClick={handleWithdraw}
                        disabled={!isValidAmount || !hasEnoughBalance}
                    >
                <i className="fas fa-minus"></i>
                {t('withdraw')}
            </button>
                    
                    {!hasEnoughBalance && withdrawValue > 0 && (
                        <p style={{color: '#ef4444', fontSize: '14px', marginTop: '10px', textAlign: 'center'}}>
                            Insufficient balance for this withdrawal
                        </p>
                    )}
                </div>
                
                <div className="withdraw-info-section">
                    <div className="account-balance-card">
                        <div className="balance-label-small">{t('account_balance')}</div>
                        <div className="balance-amount-small">{formatCurrency(playerData.balance || 0)}</div>
                    </div>
                    
                    <div className="withdraw-preview-card">
                        <div className="preview-header">
                            <div className="withdraw-preview-icon">
                                <i className="fas fa-minus"></i>
                            </div>
                            <div className="preview-title">Withdrawal Preview</div>
                        </div>
                        
                        <div className="preview-details">
                            <div className="preview-row">
                                <span className="preview-label">Withdrawal Amount:</span>
                                <span className="withdraw-amount">{formatCurrency(withdrawValue)}</span>
                            </div>
                            <div className="preview-row">
                                <span className="preview-label">Remaining Balance:</span>
                                <span className="preview-value">{formatCurrency(Math.max(0, newBalance))}</span>
                            </div>
                        </div>
                    </div>
                </div>
        </div>
    );
    };

    const filterAndSortTransactions = () => {
        let filtered = transactions.filter(transaction => {
            // Filter by type
            if (filterType !== 'all' && transaction.type !== filterType) {
                return false;
            }
            
            // Filter by search term
            if (searchTerm && !transaction.description.toLowerCase().includes(searchTerm.toLowerCase())) {
                return false;
            }
            
            return true;
        });
        
        // Sort transactions
        if (sortBy === 'date') {
            filtered.sort((a, b) => new Date(b.date) - new Date(a.date));
        } else if (sortBy === 'amount') {
            filtered.sort((a, b) => Math.abs(getTransactionAmount(b)) - Math.abs(getTransactionAmount(a)));
        }
        
        return filtered;
    };

    const calculateStats = () => {
        const totalDeposits = transactions
            .filter(t => t.type === 'deposit' || t.type === 'transfer_in' || t.type === 'savings_withdrawal')
            .reduce((sum, t) => sum + Math.abs(t.amount), 0);
            
        const totalWithdrawals = transactions
            .filter(t => t.type === 'withdrawal' || t.type === 'transfer_out' || t.type === 'fee' || t.type === 'savings_deposit')
            .reduce((sum, t) => sum + Math.abs(t.amount), 0);
            
        return {
            totalDeposits,
            totalWithdrawals,
            netChange: totalDeposits - totalWithdrawals,
            transactionCount: transactions.length
        };
    };

    const renderHistory = () => {
        const filteredTransactions = filterAndSortTransactions();
        const stats = calculateStats();
        
        return (
            <div className="history-layout">
                <div className="history-main-section">
                    <div className="history-header">
            <h3 className="section-title">{t('transaction_history')}</h3>
                        <button 
                            className="clear-all-btn" 
                            onClick={handleClearAllTransactions}
                            disabled={transactions.length === 0}
                        >
                            <i className="fas fa-trash"></i>
                            Clear All
                        </button>
                    </div>
                    
                    <input
                        type="text"
                        className="search-box"
                        placeholder={t('transaction_history')}
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                    />
                    
                    <div className="transaction-list-enhanced">
                        {filteredTransactions.length > 0 ? (
                            filteredTransactions.map(transaction => {
                    const { date, time } = formatTransactionDate(transaction.date);
                    const amount = getTransactionAmount(transaction);
                    return (
                                    <div key={transaction.id} className="transaction-item-enhanced">
                                        <div className="transaction-info-enhanced">
                                            <div className={`transaction-icon-enhanced ${transaction.type}`}>
                            <i className={getTransactionIcon(transaction.type)}></i>
                        </div>
                                            <div className="transaction-details-enhanced">
                            <h4>{transaction.description}</h4>
                                                <p>{date}</p>
                                            </div>
                                        </div>
                                        <div className="transaction-amount-enhanced">
                                            <div className={`amount ${amount < 0 ? 'negative' : 'positive'}`}>
                                                {amount < 0 ? '-' : '+'}{formatCurrency(Math.abs(amount))}
                                            </div>
                                            <div className="time">{time}</div>
                                        </div>
                                    </div>
                                );
                            })
                        ) : (
                            <div className="no-transactions-enhanced">
                                <i className="fas fa-history"></i>
                                <h3>No transactions found</h3>
                                <p>No transactions match your current filters.</p>
                            </div>
                        )}
                    </div>
                </div>
                
                <div className="history-sidebar">
                    <div className="history-stats-card">
                        <h4 className="section-title" style={{fontSize: '14px', marginBottom: '15px'}}>Summary</h4>
                        <div className="stats-summary">
                            <div className="summary-item">
                                <div className="summary-label">Total In</div>
                                <div className="summary-value positive">{formatCurrency(stats.totalDeposits)}</div>
                            </div>
                            <div className="summary-item">
                                <div className="summary-label">Total Out</div>
                                <div className="summary-value negative">{formatCurrency(stats.totalWithdrawals)}</div>
                            </div>
                            <div className="summary-item">
                                <div className="summary-label">Net Change</div>
                                <div className={`summary-value ${stats.netChange >= 0 ? 'positive' : 'negative'}`}>
                                    {formatCurrency(Math.abs(stats.netChange))}
                                </div>
                            </div>
                            <div className="summary-item">
                                <div className="summary-label">Transactions</div>
                                <div className="summary-value">{stats.transactionCount}</div>
                            </div>
                        </div>
                    </div>
                    
                    <div className="history-filters-card">
                        <h4 className="section-title" style={{fontSize: '14px', marginBottom: '15px'}}>Filters</h4>
                        
                        <div className="filter-group">
                            <label className="filter-label">Transaction Type</label>
                            <div className="filter-buttons">
                                {[
                                    {value: 'all', label: 'All'},
                                    {value: 'deposit', label: 'Deposits'},
                                    {value: 'withdrawal', label: 'Withdrawals'},
                                    {value: 'transfer_in', label: 'Received'},
                                    {value: 'transfer_out', label: 'Sent'},
                                    ...(playerData.allowSavingsAccounts ? [
                                        {value: 'savings_deposit', label: 'Savings Deposits'},
                                        {value: 'savings_withdrawal', label: 'Savings Withdrawals'},
                                        {value: 'account_transfer', label: 'Account Transfers'}
                                    ] : [])
                                ].map(filter => (
                                    <button
                                        key={filter.value}
                                        className={`filter-btn ${filterType === filter.value ? 'active' : ''}`}
                                        onClick={() => setFilterType(filter.value)}
                                    >
                                        {filter.label}
                                    </button>
                                ))}
                            </div>
                        </div>
                        
                        <div className="filter-group">
                            <label className="filter-label">Sort By</label>
                            <select 
                                className="filter-select" 
                                value={sortBy} 
                                onChange={(e) => setSortBy(e.target.value)}
                            >
                                <option value="date">Date (Newest First)</option>
                                <option value="amount">Amount (Highest First)</option>
                            </select>
                        </div>
                    </div>
                </div>
        </div>
    );
    };

    const renderSavings = () => {
        const numericTransferAmount = extractNumericValue(transferAmount);
        const transferValue = parseFloat(numericTransferAmount) || 0;
        const [fromAccount, toAccount] = transferDirection.split('-to-');
        const fromBalance = fromAccount === 'checking' ? playerData.balance : playerData.savingsBalance;
        const hasEnoughBalance = transferValue <= fromBalance;
        
        const suggestedAmounts = [100, 500, 1000, 2500, 5000];
        
        return (
            <div className="savings-layout">
                    <h3 className="section-title">{t('savings_account')}</h3>
                    
                <div className="savings-modern-layout">
                    <div className="savings-left-section">
                        <div className="savings-balances">
                            <div className="balance-card-modern checking">
                                <div className="balance-icon">
                                <i className="fas fa-university"></i>
                            </div>
                                <div className="balance-info">
                                    <div className="balance-label">Checking Account</div>
                                    <div className="balance-amount">{formatCurrency(playerData.balance || 0)}</div>
                                </div>
                        </div>
                        
                            <div className="balance-card-modern savings">
                                <div className="balance-icon">
                                <i className="fas fa-piggy-bank"></i>
                            </div>
                                <div className="balance-info">
                                    <div className="balance-label">{t('savings_account')}</div>
                                    <div className="balance-amount">{formatCurrency(playerData.savingsBalance || 0)}</div>
                                </div>
                        </div>
                    </div>
                    
                        <div className="transfer-modern-card">
                            <div className="card-header-modern">
                                <i className="fas fa-exchange-alt"></i>
                                <span>{t('transfer')}</span>
                            </div>
                            
                            <div className="transfer-controls">
                                <div className="direction-selector">
                                    <button 
                                        className={`direction-btn ${transferDirection === 'checking-to-savings' ? 'active' : ''}`}
                                        onClick={() => setTransferDirection('checking-to-savings')}
                                    >
                                        <i className="fas fa-university"></i>
                                        <i className="fas fa-arrow-right"></i>
                                        <i className="fas fa-piggy-bank"></i>
                                    </button>
                                    <button 
                                        className={`direction-btn ${transferDirection === 'savings-to-checking' ? 'active' : ''}`}
                                        onClick={() => setTransferDirection('savings-to-checking')}
                                    >
                                        <i className="fas fa-piggy-bank"></i>
                                        <i className="fas fa-arrow-right"></i>
                                        <i className="fas fa-university"></i>
                                    </button>
                            </div>
                            
                                <div className="amount-input-modern">
                                <input
                                    type="text"
                                        className="transfer-amount-input"
                                        placeholder={t('amount')}
                                    value={transferAmount}
                                    onChange={(e) => setTransferAmount(formatCurrencyInput(e.target.value))}
                                />
                            </div>
                            
                                <div className="quick-amounts-modern">
                                {suggestedAmounts.map(amount => (
                                    <button
                                        key={amount}
                                            className="quick-amount-modern"
                                        onClick={() => setTransferAmount(formatCurrencyInput(amount.toString()))}
                                        disabled={amount > fromBalance}
                                    >
                                            {amount >= 1000 ? `$${amount/1000}k` : `$${amount}`}
                                    </button>
                                ))}
                            </div>
                            
                            <button 
                                    className="transfer-execute-btn" 
                                onClick={handleAccountTransfer}
                                disabled={!numericTransferAmount || transferValue <= 0 || !hasEnoughBalance}
                            >
                                <i className="fas fa-exchange-alt"></i>
                                Transfer {formatCurrency(transferValue)}
                            </button>
                            
                            {!hasEnoughBalance && transferValue > 0 && (
                                    <div className="error-message">
                                        Insufficient balance in {fromAccount === 'checking' ? 'checking' : 'savings'} account
                                    </div>
                                )}
                            </div>
                        </div>
                        </div>
                        
                    <div className="savings-right-section">
                        <div className="quick-actions-modern">
                            <div className="quick-action-header">
                                <i className="fas fa-bolt"></i>
                                <span>Quick Actions</span>
                            </div>
                            
                            <div className="action-buttons-grid">
                            <button 
                                    className="action-btn-modern deposit"
                                    onClick={() => openQuickActionModal('toSavings')}
                                    disabled={!playerData.balance || playerData.balance <= 0}
                            >
                                <i className="fas fa-plus"></i>
                                    <div>
                                        <span>{t('deposit_savings')}</span>
                                        <small>From Checking</small>
                                    </div>
                            </button>
                            
                                <button 
                                    className="action-btn-modern withdraw"
                                    onClick={() => openQuickActionModal('toChecking')}
                                    disabled={!playerData.savingsBalance || playerData.savingsBalance <= 0}
                                >
                                    <i className="fas fa-minus"></i>
                                    <div>
                                        <span>Move to Checking</span>
                                        <small>{t('withdraw_savings')}</small>
                                    </div>
                                </button>
                                
                                <button 
                                    className="action-btn-modern info"
                                    onClick={() => openQuickActionModal('summary')}
                                >
                                    <i className="fas fa-chart-line"></i>
                                    <div>
                                        <span>Account Summary</span>
                                        <small>View Totals</small>
                                    </div>
                                </button>
                                
                                <button 
                                    className="action-btn-modern close-account"
                                    onClick={openCloseSavingsModal}
                                >
                                    <i className="fas fa-times-circle"></i>
                                    <div>
                                        <span>Close Account</span>
                                        <small>{t('savings_account')}</small>
                                    </div>
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        );
    };

    // PIN Setup Modal Component
    const renderPinModal = () => {
        if (!isPinModalOpen) return null;

        const currentPin = pinStep === 'setup' ? enteredPin : confirmPin;
        const isNextDisabled = currentPin.length !== 4;

        return (
            <div className="pin-modal-overlay" onClick={closePinModal}>
                <div className="pin-modal" onClick={(e) => e.stopPropagation()}>
                    <div className="pin-modal-header">
                        <h3 className="pin-modal-title">
                            {pinStep === 'setup' ? 'Set up your PIN' : 'Confirm your PIN'}
                        </h3>
                        <button className="pin-modal-close" onClick={closePinModal}>
                            <i className="fas fa-times"></i>
                        </button>
                    </div>
                    
                    <div className="pin-modal-content">
                        <div className="pin-display">
                            {[0, 1, 2, 3].map(index => (
                                <div key={index} className={`pin-digit ${currentPin.length > index ? 'filled' : ''}`}>
                                    {currentPin.length > index ? '●' : ''}
                                </div>
                            ))}
                        </div>
                        
                        <div className="pin-description">
                            {pinStep === 'setup' 
                                ? 'Enter a 4-digit PIN for your debit card' 
                                : 'Re-enter your PIN to confirm'
                            }
                        </div>
                        
                        {pinError && (
                            <div className="pin-error-message">
                                <i className="fas fa-exclamation-triangle"></i>
                                {pinError}
                            </div>
                        )}
                        
                        <div className="number-pad">
                            {[1, 2, 3, 4, 5, 6, 7, 8, 9].map(num => (
                                <button 
                                    key={num} 
                                    className="number-btn" 
                                    onClick={() => handleNumberPad(num.toString())}
                                    disabled={currentPin.length >= 4}
                                >
                                    {num}
                                </button>
                            ))}
                            <button className="number-btn empty"></button>
                            <button 
                                className="number-btn" 
                                onClick={() => handleNumberPad('0')}
                                disabled={currentPin.length >= 4}
                            >
                                0
                            </button>
                            <button 
                                className="number-btn backspace-btn" 
                                onClick={handlePinBackspace}
                                disabled={currentPin.length === 0}
                            >
                                <i className="fas fa-backspace"></i>
                            </button>
                        </div>
                        
                        <div className="pin-modal-actions">
                            <button className="pin-cancel-btn" onClick={closePinModal}>
                                Cancel
                            </button>
                            <button 
                                className="pin-next-btn" 
                                onClick={handlePinNext}
                                disabled={isNextDisabled}
                            >
                                {pinStep === 'setup' ? 'Next' : 'Confirm'}
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        );
    };

    // PIN Entry Modal Component (for ATM access)
    const renderPinEntryModal = () => {
        if (!isPinEntryOpen) return null;

        const isSubmitDisabled = atmPin.length !== 4;

        return (
            <div className="pin-modal-overlay" onClick={closeAtmPinEntry}>
                <div className="pin-modal" onClick={(e) => e.stopPropagation()}>
                    <div className="pin-modal-header">
                        <h3 className="pin-modal-title">Enter your PIN</h3>
                        <button className="pin-modal-close" onClick={closeAtmPinEntry}>
                            <i className="fas fa-times"></i>
                        </button>
                    </div>
                    
                    <div className="pin-modal-content">
                        <div className="pin-display">
                            {[0, 1, 2, 3].map(index => (
                                <div key={index} className={`pin-digit ${atmPin.length > index ? 'filled' : ''}`}>
                                    {atmPin.length > index ? '●' : ''}
                                </div>
                            ))}
                        </div>
                        
                        <div className="pin-description">
                            Enter your 4-digit PIN to access the ATM
                        </div>
                        
                        {atmPinError && (
                            <div className="pin-error-message">
                                <i className="fas fa-exclamation-triangle"></i>
                                {atmPinError}
                            </div>
                        )}
                        
                        <div className="number-pad">
                            {[1, 2, 3, 4, 5, 6, 7, 8, 9].map(num => (
                                <button 
                                    key={num} 
                                    className="number-btn" 
                                    onClick={() => handleAtmPinEntry(num.toString())}
                                    disabled={atmPin.length >= 4}
                                >
                                    {num}
                                </button>
                            ))}
                            <button className="number-btn empty"></button>
                            <button 
                                className="number-btn" 
                                onClick={() => handleAtmPinEntry('0')}
                                disabled={atmPin.length >= 4}
                            >
                                0
                            </button>
                            <button 
                                className="number-btn backspace-btn" 
                                onClick={handleAtmPinBackspace}
                                disabled={atmPin.length === 0}
                            >
                                <i className="fas fa-backspace"></i>
                            </button>
                        </div>
                        
                        <div className="pin-modal-actions">
                            <button className="pin-cancel-btn" onClick={closeAtmPinEntry}>
                                Cancel
                            </button>
                            <button 
                                className="pin-next-btn" 
                                onClick={handleAtmPinSubmit}
                                disabled={isSubmitDisabled}
                            >
                                Submit
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        );
    };

    // Clear Confirmation Modal Component
    const renderClearConfirmModal = () => {
        if (!isClearConfirmOpen) return null;

        return (
            <div className="pin-modal-overlay" onClick={cancelClearTransactions}>
                <div className="confirm-modal" onClick={(e) => e.stopPropagation()}>
                    <div className="confirm-modal-header">
                        <h3 className="confirm-modal-title">Confirm Action</h3>
                        <button className="pin-modal-close" onClick={cancelClearTransactions}>
                            <i className="fas fa-times"></i>
                        </button>
                    </div>
                    
                    <div className="confirm-modal-content">
                        <div className="confirm-icon">
                            <i className="fas fa-exclamation-triangle"></i>
                        </div>
                        
                        <div className="confirm-message">
                            <h4>{t('transaction_history')}?</h4>
                            <p>Are you sure you want to delete all transaction history? This action cannot be undone and will permanently remove all your banking records.</p>
                        </div>
                        
                        <div className="confirm-modal-actions">
                            <button className="confirm-cancel-btn" onClick={cancelClearTransactions}>
                                Cancel
                            </button>
                            <button className="confirm-delete-btn" onClick={confirmClearTransactions}>
                                <i className="fas fa-trash"></i>
                                Clear All
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        );
    };

    const renderQuickActionModal = () => {
        if (!isQuickActionModalOpen) return null;

        const getModalTitle = () => {
            switch (quickActionType) {
                case 'toSavings': return t('deposit_savings');
                case 'toChecking': return 'Move to Checking';
                case 'summary': return 'Account Summary';
                default: return 'Quick Action';
            }
        };

        const getModalIcon = () => {
            switch (quickActionType) {
                case 'toSavings': return 'fas fa-piggy-bank';
                case 'toChecking': return 'fas fa-university';
                case 'summary': return 'fas fa-chart-line';
                default: return 'fas fa-bolt';
            }
        };

        const getFromAccount = () => {
            return quickActionType === 'toSavings' ? 'checking' : 'savings';
        };

        const getToAccount = () => {
            return quickActionType === 'toSavings' ? 'savings' : 'checking';
        };

        const getMaxAmount = () => {
            return quickActionType === 'toSavings' ? playerData.balance || 0 : playerData.savingsBalance || 0;
        };

        if (quickActionType === 'summary') {
            const totalBalance = (playerData.balance || 0) + (playerData.savingsBalance || 0);
            return (
                <div className="pin-modal-overlay" onClick={closeQuickActionModal}>
                    <div className="confirm-modal quick-action-modal-summary" onClick={(e) => e.stopPropagation()}>
                        <div className="confirm-modal-header">
                            <h3 className="confirm-modal-title">
                                <i className={getModalIcon()}></i>
                                {getModalTitle()}
                            </h3>
                            <button className="pin-modal-close" onClick={closeQuickActionModal}>
                                <i className="fas fa-times"></i>
                            </button>
                        </div>
                        
                        <div className="confirm-modal-content">
                            <div className="summary-grid">
                                <div className="summary-item">
                                    <div className="summary-label">
                                        <i className="fas fa-university"></i>
                                        Checking Account
                                    </div>
                                    <div className="summary-value checking">{formatCurrency(playerData.balance || 0)}</div>
                                </div>
                                <div className="summary-item">
                                    <div className="summary-label">
                                        <i className="fas fa-piggy-bank"></i>
                                        {t('savings_account')}
                                    </div>
                                    <div className="summary-value savings">{formatCurrency(playerData.savingsBalance || 0)}</div>
                                </div>
                                <div className="summary-item total">
                                    <div className="summary-label">
                                        <i className="fas fa-calculator"></i>
                                        Total Balance
                                    </div>
                                    <div className="summary-value total-value">{formatCurrency(totalBalance)}</div>
                                </div>
                            </div>
                            
                            <div className="confirm-modal-actions">
                                <button className="confirm-cancel-btn" onClick={closeQuickActionModal}>
                                    Close
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            );
        }

        const getModalClass = () => {
            switch (quickActionType) {
                case 'toSavings': return 'quick-action-modal-savings';
                case 'toChecking': return 'quick-action-modal-checking';
                default: return '';
            }
        };

        return (
            <div className="pin-modal-overlay" onClick={closeQuickActionModal}>
                <div className={`confirm-modal ${getModalClass()}`} onClick={(e) => e.stopPropagation()}>
                    <div className="confirm-modal-header">
                        <h3 className="confirm-modal-title">
                            <i className={getModalIcon()}></i>
                            {getModalTitle()}
                        </h3>
                        <button className="pin-modal-close" onClick={closeQuickActionModal}>
                            <i className="fas fa-times"></i>
                        </button>
                    </div>
                    
                    <div className="confirm-modal-content">
                        <div className="transfer-info">
                            <div className="transfer-route">
                                <span className="from-account">{getFromAccount().toUpperCase()}</span>
                                <i className="fas fa-arrow-right"></i>
                                <span className="to-account">{getToAccount().toUpperCase()}</span>
                            </div>
                            <div className="available-balance">
                                Available: {formatCurrency(getMaxAmount())}
                            </div>
                        </div>
                        
                        <div className="amount-input-section">
                            <label>Enter Amount:</label>
                                <input
                                    type="number"
                                className="quick-action-input"
                                    placeholder="0.00"
                                value={quickActionAmount}
                                onChange={(e) => setQuickActionAmount(e.target.value)}
                                max={getMaxAmount()}
                                min="0.01"
                                step="0.01"
                                />
                            </div>
                            
                        <div className="quick-amounts">
                            {[25, 50, 100, 250, 500].map(amount => {
                                const maxAmount = getMaxAmount();
                                return (
                            <button 
                                        key={amount}
                                        className="quick-amount-btn"
                                        onClick={() => setQuickActionAmount(amount.toString())}
                                        disabled={amount > maxAmount}
                                    >
                                        ${amount}
                            </button>
                                );
                            })}
                        </div>
                        
                        <div className="confirm-modal-actions">
                            <button className="confirm-cancel-btn" onClick={closeQuickActionModal}>
                                Cancel
                            </button>
                            <button 
                                className="confirm-delete-btn" 
                                onClick={handleQuickActionSubmit}
                                disabled={!quickActionAmount || parseFloat(quickActionAmount) <= 0 || parseFloat(quickActionAmount) > getMaxAmount()}
                            >
                                <i className="fas fa-exchange-alt"></i>
                                Transfer {quickActionAmount ? formatCurrency(parseFloat(quickActionAmount)) : '$0.00'}
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        );
    };

    const renderCloseSavingsModal = () => {
        if (!isCloseSavingsModalOpen) return null;

        const savingsAmount = playerData.savingsBalance || 0;

        return (
            <div className="pin-modal-overlay" onClick={closeCloseSavingsModal}>
                <div className="confirm-modal" onClick={(e) => e.stopPropagation()}>
                    <div className="confirm-modal-header">
                        <h3 className="confirm-modal-title">
                            <i className="fas fa-exclamation-triangle"></i>
                            {t('savings_account')}
                        </h3>
                        <button className="pin-modal-close" onClick={closeCloseSavingsModal}>
                            <i className="fas fa-times"></i>
                        </button>
                    </div>
                    
                    <div className="confirm-modal-content">
                        <div className="confirm-icon">
                            <i className="fas fa-piggy-bank"></i>
                        </div>
                        
                        <div className="confirm-message">
                            <h4>Are you sure you want to close your savings account?</h4>
                            <p>
                                Your current savings balance of <strong>{formatCurrency(savingsAmount)}</strong> will be 
                                automatically transferred to your checking account.
                            </p>
                            <p>
                                <strong>This action cannot be undone.</strong> You will need to open a new savings account 
                                if you wish to use savings features again.
                            </p>
                        </div>
                        
                        <div className="confirm-modal-actions">
                            <button className="confirm-cancel-btn" onClick={closeCloseSavingsModal}>
                                Cancel
                            </button>
                            <button className="confirm-delete-btn" onClick={handleCloseSavingsAccount}>
                                <i className="fas fa-times-circle"></i>
                                Close Account
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        );
    };

    const renderContent = () => {
        // In ATM mode, show single page interface
        if (isATMMode) {
            return renderATMInterface();
        }
        
        // In bank mode, show full interface
        switch (activeTab) {
            case 'overview': return renderOverview();
            case 'transfer': return renderTransfer();
            case 'deposit': return renderDeposit();
            case 'withdraw': return renderWithdraw();
            case 'history': return renderHistory();
            case 'savings': return playerData.allowSavingsAccounts ? renderSavings() : renderOverview();
            default: return renderOverview();
        }
    };

    if (!isVisible && !isPinEntryOpen) return null;

    return (
        <div>
            {isVisible && (
        <div className="banking-container">
            <div className="banking-header">
                <div className="header-left">
                    <div className="bank-logo">
                        <div className="logo-icon">
                            <i className="fas fa-university"></i>
                        </div>
                        <div className="bank-info">
                            <h1 className="bank-title">{bankName}</h1>
                        </div>
                    </div>
                </div>
                
                <div className="header-center">
                    <div className="user-info">
                        <div className="user-name">
                            <div className="user-avatar">
                                <i className="fas fa-user"></i>
                            </div>
                            <span>{playerData.name || 'Guest'}</span>
                        </div>
                    </div>
                </div>
                
                <div className="header-right">
                    <div className="header-actions">
                        <div className="current-time">
                            {new Date().toLocaleTimeString('en-US', { 
                                hour: 'numeric', 
                                minute: '2-digit',
                                hour12: true 
                            })}
                        </div>
                        <button className="close-btn" onClick={closeBank} title={t('close')}>
                            <i className="fas fa-times"></i>
                        </button>
                    </div>
                </div>
            </div>
            
            <div className="banking-content">
                        {!isATMMode && (
                <div className="tab-navigation">
                    <div className="tab-items">
                        <button 
                            className={`tab-item ${activeTab === 'overview' ? 'active' : ''}`}
                            onClick={() => setActiveTab('overview')}
                        >
                            <i className="fas fa-home"></i>
                            {t('account')}
                        </button>
                        <button 
                            className={`tab-item ${activeTab === 'transfer' ? 'active' : ''}`}
                            onClick={() => setActiveTab('transfer')}
                        >
                            <i className="fas fa-paper-plane"></i>
                            {t('transfer')}
                        </button>
                        <button 
                            className={`tab-item ${activeTab === 'deposit' ? 'active' : ''}`}
                            onClick={() => setActiveTab('deposit')}
                        >
                            <i className="fas fa-plus"></i>
                            {t('deposit')}
                        </button>
                        <button 
                            className={`tab-item ${activeTab === 'withdraw' ? 'active' : ''}`}
                            onClick={() => setActiveTab('withdraw')}
                        >
                            <i className="fas fa-minus"></i>
                            {t('withdraw')}
                        </button>
                        <button 
                            className={`tab-item ${activeTab === 'history' ? 'active' : ''}`}
                            onClick={() => setActiveTab('history')}
                        >
                            <i className="fas fa-history"></i>
                            {t('transaction_history')}
                        </button>
                        {playerData.allowSavingsAccounts && playerData.hasSavingsAccount && (
                            <button 
                                className={`tab-item ${activeTab === 'savings' ? 'active' : ''}`}
                                onClick={() => setActiveTab('savings')}
                            >
                                <i className="fas fa-piggy-bank"></i>
                                {t('savings_account')}
                            </button>
                        )}
                    </div>
                </div>
                        )}
                
                <div className="main-content">
                    {renderContent()}
                </div>
            </div>
                    
                    {renderPinModal()}
                </div>
            )}
            
            {renderPinEntryModal()}
            {renderClearConfirmModal()}
            {renderQuickActionModal()}
            {renderCloseSavingsModal()}
        </div>
    );
};

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<BankingApp />); 