using MetaVault.App.Models;

namespace MetaVault.App.Services;

public class MetaVaultService : IMetaVaultService
{
    private readonly IWeb3Service _web3Service;
    private readonly ILogger<MetaVaultService> _logger;

    public MetaVaultService(
        IWeb3Service web3Service,
        ILogger<MetaVaultService> logger)
    {
        _web3Service = web3Service;
        _logger = logger;
    }

    public async Task<List<VaultInfo>> GetVaults(string metaVaultAddress)
    {
        try
        {
            // Appel du smart contract pour récupérer les vaults actifs
            var result = await _web3Service.CallContract(
                metaVaultAddress,
                "getActiveVaults"
            );

            // Transformation du résultat en List<VaultInfo>
            var vaultsList = new List<VaultInfo>();
            
            if (result != null)
            {
                // Extraction des données du résultat dynamique
                var ids = ((object[])result.GetProperty("ids").GetArray()).Select(id => id.ToString()).ToArray();
                var addresses = ((object[])result.GetProperty("addresses").GetArray()).Select(addr => addr.ToString()).ToArray();
                var allocations = ((object[])result.GetProperty("allocations").GetArray()).Select(alloc => Convert.ToDecimal(alloc)).ToArray();

                for (var i = 0; i < ids.Length; i++)
                {
                    vaultsList.Add(new VaultInfo
                    {
                        Id = ids[i],
                        Address = addresses[i],
                        Allocation = allocations[i] / 100, // Conversion des basis points
                        Name = $"Vault {i + 1}",
                        Apy = await GetVaultApy(addresses[i]),
                        IsActive = true
                    });
                }
            }

            return vaultsList;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting vaults for address {Address}", metaVaultAddress);
            throw;
        }
    }

    public async Task<bool> UpdateVaultAllocation(string metaVaultAddress, string vaultId, decimal newAllocation)
    {
        try
        {
            // Vérification que l'allocation totale ne dépasse pas 100%
            var currentTotal = await GetTotalAllocation(metaVaultAddress);
            var currentVaults = await GetVaults(metaVaultAddress);
            var currentVault = currentVaults.FirstOrDefault(v => v.Id == vaultId);
            
            if (currentVault == null)
            {
                throw new InvalidOperationException($"Vault {vaultId} not found");
            }

            var newTotal = currentTotal - currentVault.Allocation + newAllocation;
            if (newTotal > 100)
            {
                throw new InvalidOperationException("Total allocation would exceed 100%");
            }

            return await _web3Service.UpdateAllocation(vaultId, newAllocation);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating allocation for vault {VaultId}", vaultId);
            return false;
        }
    }

    public async Task<decimal> GetTotalAllocation(string metaVaultAddress)
    {
        var vaults = await GetVaults(metaVaultAddress);
        return vaults.Sum(v => v.Allocation);
    }

    public async Task<bool> IsVaultActive(string metaVaultAddress, string vaultId)
    {
        var vaults = await GetVaults(metaVaultAddress);
        return vaults.Any(v => v.Id == vaultId && v.IsActive);
    }

    private async Task<decimal> GetVaultApy(string vaultAddress)
    {
        try
        {
            var result = await _web3Service.CallContract(
                vaultAddress,
                "getAPY"
            );

            return Convert.ToDecimal(result) / 100; // Conversion des basis points
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting APY for vault {Address}", vaultAddress);
            return 0;
        }
    }
}