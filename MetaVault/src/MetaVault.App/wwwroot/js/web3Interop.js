window.web3Interop = {
    // Initialize any required state
    init: function() {
        console.log("Web3 Interop initialized");
        // You can add any initialization logic here
    },

    // Connect wallet function
    connectWallet: async function() {
        try {
            // Check if MetaMask is installed
            if (typeof window.ethereum === 'undefined') {
                throw new Error("MetaMask is not installed");
            }

            // Request account access
            const accounts = await window.ethereum.request({
                method: 'eth_requestAccounts'
            });

            // Return true if we have at least one account
            return accounts.length > 0;

        } catch (error) {
            console.error("Error connecting wallet:", error);
            return false;
        }
    },

    // Get connected address
    getConnectedAddress: async function() {
        try {
            if (typeof window.ethereum === 'undefined') {
                return '';
            }

            const accounts = await window.ethereum.request({
                method: 'eth_accounts'
            });

            return accounts[0] || '';
        } catch (error) {
            console.error("Error getting address:", error);
            return '';
        }
    },

    // Call a read-only contract method
    callContract: async function(contractAddress, methodName, params) {
        try {
            const provider = new ethers.BrowserProvider(window.ethereum);
            const signer = await provider.getSigner();

            // Create contract instance
            const contract = new ethers.Contract(
                contractAddress,
                this.getContractABI(methodName),
                signer
            );

            // Call the method
            return await contract[methodName](...(params || []));
        } catch (error) {
            console.error(`Error calling ${methodName}:`, error);
            throw error;
        }
    },

    // Send a transaction to the contract
    sendContractTransaction: async function(contractAddress, methodName, params) {
        try {
            const provider = new ethers.BrowserProvider(window.ethereum);
            const signer = await provider.getSigner();

            // Create contract instance
            const contract = new ethers.Contract(
                contractAddress,
                this.getContractABI(methodName),
                signer
            );

            // Send transaction
            const tx = await contract[methodName](...(params || []));
            const receipt = await tx.wait();
            return receipt.hash;
        } catch (error) {
            console.error(`Error in transaction ${methodName}:`, error);
            throw error;
        }
    },

    // Helper to get appropriate ABI based on method
    getContractABI: function(methodName) {
        const contractABIs = {
            metaVaultFactory: [
                "function createMetaVault() external returns (address)",
                "function hasMetaVault(address user) external view returns (bool)",
                "function getUserMetaVault(address user) external view returns (address)",
                "function beacon() external view returns (address)"
            ],
            metaVault: [
                "function initialize() external",
                "function updateAllocation(uint256 _vaultId, uint256 _newAllocation) external",
                "function getActiveVaults() external view returns (uint256[] memory ids, address[] memory addresses, uint256[] memory allocations)",
                "function owner() external view returns (address)"
            ],
            beacon: [
                "function implementation() external view returns (address)"
            ]
        };

        // Return appropriate ABI based on method name
        return methodName.includes('MetaVault') ?
            contractABIs.metaVaultFactory :
            contractABIs.metaVault;
    }
};

// Initialize when the document is ready
document.addEventListener('DOMContentLoaded', function() {
    window.web3Interop.init();
});