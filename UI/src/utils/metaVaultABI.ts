export const metaVaultABI = [
	{
		inputs: [],
		name: "AllocationTooHigh",
		type: "error",
	},
	{
		inputs: [],
		name: "DailyLimitExceeded",
		type: "error",
	},
	{
		inputs: [],
		name: "InvalidAllocation",
		type: "error",
	},
	{
		inputs: [],
		name: "InvalidInitialization",
		type: "error",
	},
	{
		inputs: [],
		name: "NoRebalanceNeeded",
		type: "error",
	},
	{
		inputs: [],
		name: "NotInitializing",
		type: "error",
	},
	{
		inputs: [],
		name: "ReentrancyGuardReentrantCall",
		type: "error",
	},
	{
		inputs: [
			{
				internalType: "address",
				name: "token",
				type: "address",
			},
		],
		name: "SafeERC20FailedOperation",
		type: "error",
	},
	{
		inputs: [],
		name: "SlippageExceeded",
		type: "error",
	},
	{
		inputs: [],
		name: "TotalAllocationExceeded",
		type: "error",
	},
	{
		inputs: [],
		name: "Unauthorized",
		type: "error",
	},
	{
		inputs: [],
		name: "VaultAlreadyAdded",
		type: "error",
	},
	{
		inputs: [],
		name: "VaultNotFound",
		type: "error",
	},
	{
		anonymous: false,
		inputs: [
			{
				indexed: true,
				internalType: "address",
				name: "vault",
				type: "address",
			},
			{
				indexed: false,
				internalType: "uint256",
				name: "newAllocation",
				type: "uint256",
			},
		],
		name: "AllocationUpdated",
		type: "event",
	},
	{
		anonymous: false,
		inputs: [
			{
				indexed: true,
				internalType: "address",
				name: "user",
				type: "address",
			},
			{
				indexed: false,
				internalType: "uint256",
				name: "newLimit",
				type: "uint256",
			},
		],
		name: "DailyLimitUpdated",
		type: "event",
	},
	{
		anonymous: false,
		inputs: [
			{
				indexed: false,
				internalType: "uint256",
				name: "totalAmount",
				type: "uint256",
			},
			{
				indexed: false,
				internalType: "address[]",
				name: "vaults",
				type: "address[]",
			},
			{
				indexed: false,
				internalType: "uint256[]",
				name: "amounts",
				type: "uint256[]",
			},
		],
		name: "Deposited",
		type: "event",
	},
	{
		anonymous: false,
		inputs: [
			{
				indexed: false,
				internalType: "uint64",
				name: "version",
				type: "uint64",
			},
		],
		name: "Initialized",
		type: "event",
	},
	{
		anonymous: false,
		inputs: [
			{
				indexed: true,
				internalType: "address",
				name: "vault",
				type: "address",
			},
			{
				indexed: false,
				internalType: "uint256",
				name: "apr",
				type: "uint256",
			},
			{
				indexed: false,
				internalType: "uint256",
				name: "tvl",
				type: "uint256",
			},
			{
				indexed: false,
				internalType: "uint256",
				name: "utilizationRate",
				type: "uint256",
			},
		],
		name: "PerformanceUpdated",
		type: "event",
	},
	{
		anonymous: false,
		inputs: [
			{
				indexed: false,
				internalType: "address[]",
				name: "vaults",
				type: "address[]",
			},
			{
				indexed: false,
				internalType: "uint256[]",
				name: "allocations",
				type: "uint256[]",
			},
		],
		name: "Rebalanced",
		type: "event",
	},
	{
		anonymous: false,
		inputs: [
			{
				indexed: true,
				internalType: "address",
				name: "vault",
				type: "address",
			},
			{
				indexed: false,
				internalType: "uint256",
				name: "allocation",
				type: "uint256",
			},
		],
		name: "VaultAdded",
		type: "event",
	},
	{
		anonymous: false,
		inputs: [
			{
				indexed: true,
				internalType: "address",
				name: "vault",
				type: "address",
			},
		],
		name: "VaultRemoved",
		type: "event",
	},
	{
		anonymous: false,
		inputs: [
			{
				indexed: false,
				internalType: "uint256",
				name: "totalAmount",
				type: "uint256",
			},
			{
				indexed: false,
				internalType: "address[]",
				name: "vaults",
				type: "address[]",
			},
			{
				indexed: false,
				internalType: "uint256[]",
				name: "amounts",
				type: "uint256[]",
			},
		],
		name: "Withdrawn",
		type: "event",
	},
	{
		inputs: [],
		name: "MAX_BPS",
		outputs: [
			{
				internalType: "uint256",
				name: "",
				type: "uint256",
			},
		],
		stateMutability: "view",
		type: "function",
	},
	{
		inputs: [],
		name: "MAX_SLIPPAGE",
		outputs: [
			{
				internalType: "uint256",
				name: "",
				type: "uint256",
			},
		],
		stateMutability: "view",
		type: "function",
	},
	{
		inputs: [],
		name: "REBALANCE_THRESHOLD",
		outputs: [
			{
				internalType: "uint256",
				name: "",
				type: "uint256",
			},
		],
		stateMutability: "view",
		type: "function",
	},
	{
		inputs: [
			{
				internalType: "uint256",
				name: "",
				type: "uint256",
			},
		],
		name: "activeVaults",
		outputs: [
			{
				internalType: "address",
				name: "",
				type: "address",
			},
		],
		stateMutability: "view",
		type: "function",
	},
	{
		inputs: [
			{
				internalType: "address",
				name: "vault",
				type: "address",
			},
			{
				internalType: "uint256",
				name: "allocation",
				type: "uint256",
			},
		],
		name: "addVault",
		outputs: [],
		stateMutability: "nonpayable",
		type: "function",
	},
	{
		inputs: [
			{
				internalType: "address",
				name: "",
				type: "address",
			},
		],
		name: "dailyLimits",
		outputs: [
			{
				internalType: "uint256",
				name: "",
				type: "uint256",
			},
		],
		stateMutability: "view",
		type: "function",
	},
	{
		inputs: [
			{
				internalType: "address",
				name: "",
				type: "address",
			},
		],
		name: "dailyVolume",
		outputs: [
			{
				internalType: "uint256",
				name: "",
				type: "uint256",
			},
		],
		stateMutability: "view",
		type: "function",
	},
	{
		inputs: [
			{
				internalType: "address",
				name: "asset",
				type: "address",
			},
			{
				internalType: "uint256",
				name: "amount",
				type: "uint256",
			},
		],
		name: "deposit",
		outputs: [],
		stateMutability: "nonpayable",
		type: "function",
	},
	{
		inputs: [],
		name: "factory",
		outputs: [
			{
				internalType: "address",
				name: "",
				type: "address",
			},
		],
		stateMutability: "view",
		type: "function",
	},
	{
		inputs: [],
		name: "getActiveVaults",
		outputs: [
			{
				internalType: "address[]",
				name: "",
				type: "address[]",
			},
		],
		stateMutability: "view",
		type: "function",
	},
	{
		inputs: [],
		name: "getTotalAllocation",
		outputs: [
			{
				internalType: "uint256",
				name: "",
				type: "uint256",
			},
		],
		stateMutability: "view",
		type: "function",
	},
	{
		inputs: [
			{
				internalType: "address",
				name: "_owner",
				type: "address",
			},
		],
		name: "initialize",
		outputs: [],
		stateMutability: "nonpayable",
		type: "function",
	},
	{
		inputs: [
			{
				internalType: "address",
				name: "",
				type: "address",
			},
		],
		name: "lastActivityTime",
		outputs: [
			{
				internalType: "uint256",
				name: "",
				type: "uint256",
			},
		],
		stateMutability: "view",
		type: "function",
	},
	{
		inputs: [],
		name: "owner",
		outputs: [
			{
				internalType: "address",
				name: "",
				type: "address",
			},
		],
		stateMutability: "view",
		type: "function",
	},
	{
		inputs: [],
		name: "rebalance",
		outputs: [],
		stateMutability: "nonpayable",
		type: "function",
	},
	{
		inputs: [
			{
				internalType: "address",
				name: "vault",
				type: "address",
			},
		],
		name: "removeVault",
		outputs: [],
		stateMutability: "nonpayable",
		type: "function",
	},
	{
		inputs: [],
		name: "shouldRebalance",
		outputs: [
			{
				internalType: "bool",
				name: "",
				type: "bool",
			},
		],
		stateMutability: "view",
		type: "function",
	},
	{
		inputs: [
			{
				internalType: "address",
				name: "",
				type: "address",
			},
		],
		name: "vaultAllocations",
		outputs: [
			{
				internalType: "address",
				name: "vault",
				type: "address",
			},
			{
				internalType: "uint256",
				name: "allocation",
				type: "uint256",
			},
			{
				internalType: "bool",
				name: "active",
				type: "bool",
			},
			{
				internalType: "uint256",
				name: "lastUpdateTime",
				type: "uint256",
			},
			{
				internalType: "uint256",
				name: "lastBalance",
				type: "uint256",
			},
			{
				internalType: "uint256",
				name: "lastPrice",
				type: "uint256",
			},
		],
		stateMutability: "view",
		type: "function",
	},
	{
		inputs: [
			{
				internalType: "address",
				name: "",
				type: "address",
			},
		],
		name: "vaultPerformance",
		outputs: [
			{
				internalType: "uint256",
				name: "apr",
				type: "uint256",
			},
			{
				internalType: "uint256",
				name: "tvl",
				type: "uint256",
			},
			{
				internalType: "uint256",
				name: "utilizationRate",
				type: "uint256",
			},
		],
		stateMutability: "view",
		type: "function",
	},
	{
		inputs: [
			{
				internalType: "uint256",
				name: "percentage",
				type: "uint256",
			},
		],
		name: "withdraw",
		outputs: [
			{
				internalType: "uint256",
				name: "totalWithdrawn",
				type: "uint256",
			},
		],
		stateMutability: "nonpayable",
		type: "function",
	},
] as const;
