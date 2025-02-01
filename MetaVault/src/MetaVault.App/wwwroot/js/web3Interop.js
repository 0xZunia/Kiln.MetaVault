window.web3Interop = {
    // Initialize any required state
    init: function() {
        console.log("Web3 Interop initialized");
        this.ensureEthereumProviderExists();
    },
    
    ensureEthereumProviderExists: function() {
        if (typeof window.ethereum === 'undefined') {
            console.error("MetaMask is not installed");
            throw new Error("MetaMask is not installed");
        }
    },

    // Connect wallet function
    connectWallet: async function() {
        try {
            console.log("Connecting wallet...");
            this.ensureEthereumProviderExists();

            // Request account access
            console.log("Requesting account access...");
            const accounts = await window.ethereum.request({
                method: 'eth_requestAccounts'
            });

            console.log("Accounts received:", accounts);
            // Return true if we have at least one account
            const result = accounts.length > 0;
            console.log("Connection result:", result);
            return result;
        } catch (error) {
            console.error("Error connecting wallet:", error);
            // Renvoyer plus d'informations sur l'erreur
            throw new Error(`Failed to connect wallet: ${error.message}`);
        }
    },
    
    // Get connected address
    getConnectedAddress: async function() {
        try {
            this.ensureEthereumProviderExists();

            const accounts = await window.ethereum.request({
                method: 'eth_accounts'
            });

            return accounts[0] || '';
        } catch (error) {
            console.error("Error getting address:", error);
            return '';
        }
    },

    // Get network ID
    getNetworkId: async function() {
        try {
            this.ensureEthereumProviderExists();

            const chainId = await window.ethereum.request({
                method: 'eth_chainId'
            });

            return parseInt(chainId, 16);
        } catch (error) {
            console.error("Error getting network ID:", error);
            throw error;
        }
    },

    // Deploy factory contract
    deployFactory: async function() {
        try {
            this.ensureEthereumProviderExists();

            // Création du provider et du signer
            const provider = new ethers.BrowserProvider(window.ethereum);
            const signer = await provider.getSigner();

            // Création de la factory de contrat
            const factory = new ethers.ContractFactory(
                MetaVaultFactoryABI,
                MetaVaultFactoryBytecode,
                signer
            );

            // Déploiement du contrat
            console.log("Deploying factory contract...");
            const contract = await factory.deploy();

            // Attente de la confirmation
            console.log("Waiting for deployment confirmation...");
            const receipt = await contract.waitForDeployment();

            // Récupération de l'adresse du contrat déployé
            const deployedAddress = await contract.getAddress();
            console.log("Factory deployed at:", deployedAddress);

            return deployedAddress;
        } catch (error) {
            console.error("Error deploying factory:", error);
            throw error;
        }
    },

    // Call a read-only contract method
    callContract: async function(contractAddress, methodName, params) {
        try {
            this.ensureEthereumProviderExists();

            const provider = new ethers.BrowserProvider(window.ethereum);
            const contract = this.getContract(contractAddress, methodName, provider);
            
            console.log(`Calling ${methodName} on ${contractAddress}...`);
            return await contract[methodName](...(params || []));
        } catch (error) {
            console.error(`Error calling ${methodName}:`, error);
            throw error;
        }
    },

    // Send a contract transaction
    sendContractTransaction: async function(contractAddress, methodName, params) {
        try {
            this.ensureEthereumProviderExists();

            const provider = new ethers.BrowserProvider(window.ethereum);
            const signer = await provider.getSigner();
            const contract = this.getContract(contractAddress, methodName, signer);
            
            console.log(`Sending transaction ${methodName} to ${contractAddress}...`);
            const tx = await contract[methodName](...(params || []));
            
            console.log("Waiting for transaction confirmation...");
            const receipt = await tx.wait();

            return receipt.hash;
        } catch (error) {
            console.error(`Error in transaction ${methodName}:`, error);
            throw error;
        }
    },

    // Helper to get contract instance
    getContract: function(address, methodName, signerOrProvider) {
        // Select appropriate ABI based on method name
        const abi = this.getContractABI(methodName);
        return new ethers.Contract(address, abi, signerOrProvider);
    },

    // Helper to get appropriate ABI based on method
    getContractABI: function(methodName) {
        // ABIs of the different contracts
        const contractABIs = {
            metaVaultFactory: [
                "function createMetaVault() external returns (address)",
                "function hasMetaVault(address user) external view returns (bool)",
                "function getUserMetaVault(address user) external view returns (address)",
                "function beacon() external view returns (address)",
                "function initialize(address initialAdmin, uint48 initialDelay) external"
            ],
            metaVault: [
                "function initialize() external",
                "function addVault(address vault, uint256 allocation) external",
                "function updateAllocation(address vault, uint256 newAllocation) external",
                "function getActiveVaults() external view returns (address[] memory vaults, uint256[] memory allocations)",
                "function owner() external view returns (address)",
                "function deposit(uint256 assets, address receiver) external returns (uint256)",
                "function withdraw(uint256 assets, address receiver, address owner) external returns (uint256)"
            ]
        };

        // Return appropriate ABI based on method name
        if (methodName.toLowerCase().includes('metavault')) {
            return contractABIs.metaVaultFactory;
        }
        return contractABIs.metaVault;
    }
};

// Initialize when the document is ready
document.addEventListener('DOMContentLoaded', function() {
    window.web3Interop.init();
});