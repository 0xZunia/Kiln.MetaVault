using MetaVault.Shared;
using Microsoft.JSInterop;

namespace MetaVault.App.Services;

public class Web3Service : IWeb3Service
{
    private readonly IJSRuntime _jsRuntime;
    private string MetaVaultFactoryAddress = "";

    public Web3Service(IJSRuntime jsRuntime)
    {
        _jsRuntime = jsRuntime;
    }

    public async Task<bool> ConnectWallet()
    {
        try
        {
            return await _jsRuntime.InvokeAsync<bool>("web3Interop.connectWallet");
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"Error connecting wallet: {ex.Message}");
            return false;
        }
    }

    public async Task<string> GetConnectedAddress()
    {
        try
        {
            return await _jsRuntime.InvokeAsync<string>("web3Interop.getConnectedAddress");
        }
        catch (Exception)
        {
            return string.Empty;
        }
    }

    public async Task<dynamic> CallContract(string address, string methodName, params object[] args)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(address))
            {
                return null;
            }
            return await _jsRuntime.InvokeAsync<dynamic>(
                "web3Interop.callContract",
                address,
                methodName,
                args
            );
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"Error calling contract method: {ex.Message}");
            throw;
        }
    }

    public async Task<dynamic> SendContractTransaction(string address, string methodName, params object[] args)
    {
        try
        {
            return await _jsRuntime.InvokeAsync<dynamic>(
                "web3Interop.sendContractTransaction",
                address,
                methodName,
                args
            );
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"Error sending transaction: {ex.Message}");
            throw;
        }
    }

    public async Task<bool> HasMetaVault(string address)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(address))
            {
                return false;
            }
            return await CallContract(
                Constants.ContractAddresses.MetaVaultFactory,
                "hasMetaVault",
                address
            );
        }
        catch (Exception)
        {
            return false;
        }
    }

    public async Task<string> GetUserMetaVault(string address)
    {
        try
        {
            return await CallContract(
                Constants.ContractAddresses.MetaVaultFactory,
                "getUserMetaVault",
                address
            );
        }
        catch (Exception)
        {
            return string.Empty;
        }
    }

    public async Task<string> CreateMetaVault()
    {
        try
        {
            return await SendContractTransaction(
                Constants.ContractAddresses.MetaVaultFactory,
                "createMetaVault"
            );
        }
        catch (Exception)
        {
            return string.Empty;
        }
    }

    public async Task<bool> UpdateAllocation(string vaultId, decimal allocation)
    {
        try
        {
            var basisPoints = (int)(allocation * 100);
            await SendContractTransaction(
                Constants.ContractAddresses.MetaVaultFactory,
                "updateAllocation",
                vaultId,
                basisPoints
            );
            return true;
        }
        catch (Exception)
        {
            return false;
        }
    }

    public async Task<int> GetNetworkId()
    {
        try
        {
            return await _jsRuntime.InvokeAsync<int>("web3Interop.getNetworkId");
        }
        catch (Exception)
        {
            return 0;
        }
    }
    
    public async Task<string> DeployFactory()
    {
        try
        {
            return await _jsRuntime.InvokeAsync<string>(
                "web3Interop.deployFactory"
            );
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"Error deploying factory: {ex.Message}");
            throw;
        }
    }
}