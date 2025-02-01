namespace MetaVault.App.Models;

public class VaultInfo
{
    public string Id { get; set; }
    public string Address { get; set; }
    public decimal Allocation { get; set; }
    public string Name { get; set; }
    public decimal Apy { get; set; }
    public bool IsActive { get; set; }
}