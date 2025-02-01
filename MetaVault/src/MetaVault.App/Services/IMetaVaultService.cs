using MetaVault.App.Models;

namespace MetaVault.App.Services;

public interface IMetaVaultService
{
    Task<List<VaultInfo>> GetVaults(string metaVaultAddress);
    Task<bool> UpdateVaultAllocation(string metaVaultAddress, string vaultId, decimal newAllocation);
    Task<decimal> GetTotalAllocation(string metaVaultAddress);
    Task<bool> IsVaultActive(string metaVaultAddress, string vaultId);
}