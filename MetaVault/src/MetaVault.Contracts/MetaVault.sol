pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IVault {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function getAPY() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

contract MetaVault is Ownable {
    struct VaultAllocation {
        address vaultAddress;
        uint256 allocation; // en basis points (100 = 1%)
        bool isActive;
    }

    mapping(uint256 => VaultAllocation) public vaults;
    uint256[] public activeVaultIds;

    event AllocationUpdated(uint256 vaultId, uint256 newAllocation);
    event VaultAdded(uint256 vaultId, address vaultAddress);
    event VaultRemoved(uint256 vaultId);
    event DepositDistributed(uint256 totalAmount);
    event WithdrawalProcessed(uint256 totalAmount);

    constructor() Ownable(msg.sender) {}

    // Permet d'ajouter un vault existant au système
    function addVault(uint256 _vaultId, address _vaultAddress) external onlyOwner {
        require(_vaultAddress != address(0), "Invalid vault address");
        require(!vaults[_vaultId].isActive, "Vault ID already active");

        // Vérifier que l'adresse est bien un contrat
        require(_vaultAddress.code.length > 0, "Not a contract address");

        vaults[_vaultId] = VaultAllocation({
            vaultAddress: _vaultAddress,
            allocation: 0,
            isActive: true
        });

        activeVaultIds.push(_vaultId);
        emit VaultAdded(_vaultId, _vaultAddress);
    }

    // Met à jour l'allocation pour un vault spécifique
    function updateAllocation(uint256 _vaultId, uint256 _newAllocation) external onlyOwner {
        require(vaults[_vaultId].isActive, "Vault not active");
        require(_newAllocation <= 10000, "Allocation exceeds 100%");

        uint256 totalAllocation = 0;
        for (uint256 i = 0; i < activeVaultIds.length; i++) {
            uint256 vaultId = activeVaultIds[i];
            if (vaultId != _vaultId) {
                totalAllocation += vaults[vaultId].allocation;
            }
        }

        require(totalAllocation + _newAllocation <= 10000, "Total allocation would exceed 100%");

        vaults[_vaultId].allocation = _newAllocation;
        emit AllocationUpdated(_vaultId, _newAllocation);
    }

    // Distribue les ETH reçus selon les allocations
    receive() external payable {
        require(msg.value > 0, "No ETH sent");
        _distributeDeposit(msg.value);
    }

    // Fonction interne pour distribuer les dépôts
    function _distributeDeposit(uint256 _amount) internal {
        uint256 remaining = _amount;
        uint256 totalProcessed = 0;

        for (uint256 i = 0; i < activeVaultIds.length; i++) {
            uint256 vaultId = activeVaultIds[i];
            VaultAllocation storage vault = vaults[vaultId];

            if (vault.allocation > 0) {
                uint256 vaultShare = (_amount * vault.allocation) / 10000;
                if (vaultShare > 0) {
                    IVault(vault.vaultAddress).deposit{value: vaultShare}();
                    totalProcessed += vaultShare;
                }
            }
        }

        // Gérer la poussière d'ETH restante si nécessaire
        if (totalProcessed < _amount) {
            uint256 dust = _amount - totalProcessed;
            if (dust > 0 && activeVaultIds.length > 0) {
                // Envoyer la poussière au premier vault actif
                IVault(vaults[activeVaultIds[0]].vaultAddress).deposit{value: dust}();
            }
        }

        emit DepositDistributed(_amount);
    }

    // Retire des fonds d'un vault spécifique
    function withdrawFromVault(uint256 _vaultId, uint256 _amount) external onlyOwner {
        require(vaults[_vaultId].isActive, "Vault not active");
        IVault vault = IVault(vaults[_vaultId].vaultAddress);
        require(vault.balanceOf(address(this)) >= _amount, "Insufficient balance");

        vault.withdraw(_amount);
        emit WithdrawalProcessed(_amount);
    }

    // Retourne la liste des vaults actifs et leurs allocations
    function getActiveVaults() external view returns (
        uint256[] memory ids,
        address[] memory addresses,
        uint256[] memory allocations
    ) {
        uint256 length = activeVaultIds.length;
        ids = new uint256[](length);
        addresses = new address[](length);
        allocations = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            uint256 vaultId = activeVaultIds[i];
            ids[i] = vaultId;
            addresses[i] = vaults[vaultId].vaultAddress;
            allocations[i] = vaults[vaultId].allocation;
        }
    }

    // Retourne l'APY d'un vault spécifique
    function getVaultAPY(uint256 _vaultId) external view returns (uint256) {
        require(vaults[_vaultId].isActive, "Vault not active");
        return IVault(vaults[_vaultId].vaultAddress).getAPY();
    }
}