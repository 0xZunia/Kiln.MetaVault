using Microsoft.JSInterop;

namespace MetaVault.App.Services;

public interface IWeb3Service
{
    Task<string> GetConnectedAddress();
    Task<bool> ConnectWallet();
    Task<string> CreateMetaVault();
    Task<bool> HasMetaVault(string address);
    Task<string> GetUserMetaVault(string address);
    Task<bool> UpdateAllocation(string vaultId, decimal allocation);
    Task<dynamic> CallContract(string address, string methodName, params object[] args);
    Task<dynamic> SendContractTransaction(string address, string methodName, params object[] args);
    Task<int> GetNetworkId();
}