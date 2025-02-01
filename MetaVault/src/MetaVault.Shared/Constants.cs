namespace MetaVault.Shared;

public static class Constants
{
    public static class ContractAddresses
    {
        public const string MetaVaultFactory = "YOUR_FACTORY_ADDRESS";
            
        // Réseaux supportés
        public static readonly Dictionary<int, string> NetworkFactoryAddresses = new()
        {
            { 1, "MAINNET_FACTORY_ADDRESS" },
            { 5, "GOERLI_FACTORY_ADDRESS" },
            { 11155111, "SEPOLIA_FACTORY_ADDRESS" }
        };
    }

    public static class NetworkInfo
    {
        public const int MainnetChainId = 1;
        public const int GoerliChainId = 5;
        public const int SepoliaChainId = 11155111;

        public static readonly Dictionary<int, string> NetworkNames = new()
        {
            { MainnetChainId, "Ethereum Mainnet" },
            { GoerliChainId, "Goerli Testnet" },
            { SepoliaChainId, "Sepolia Testnet" }
        };
    }

    public static class ErrorMessages
    {
        public const string WalletNotConnected = "Please connect your wallet to continue";
        public const string WrongNetwork = "Please switch to a supported network";
        public const string TransactionFailed = "Transaction failed. Please try again";
        public const string InvalidAllocation = "Total allocation cannot exceed 100%";
    }

    public static class LocalStorage
    {
        public const string WalletAddressKey = "walletAddress";
        public const string SelectedNetworkKey = "selectedNetwork";
    }
}