// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

// Contrats standards OpenZeppelin
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// Contrats upgradeable OpenZeppelin
import {AccessControlDefaultAdminRulesUpgradeable} from
    "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlDefaultAdminRulesUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// Contrats locaux
import {Vault} from "./Vault.sol";

/**
 * @title PersonalMetaVault
 * @notice Personal vault manager allowing users to manage their allocations across multiple Kiln vaults
 */
contract PersonalMetaVault is Initializable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    struct VaultAllocation {
        address vault;
        uint256 allocation; // Allocation percentage in basis points (100 = 1%)
        bool active;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  CONSTANTS                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Maximum basis points for 100%
    uint256 public constant MAX_BPS = 10000;

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                    */
    /* -------------------------------------------------------------------------- */

    /// @notice Owner of this personal meta vault
    address public owner;

    /// @notice Factory that deployed this vault
    address public factory;

    /// @notice Mapping of vault address to allocation data
    mapping(address => VaultAllocation) public vaultAllocations;

    /// @notice List of active vault addresses
    address[] public activeVaults;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                     */
    /* -------------------------------------------------------------------------- */

    event VaultAdded(address indexed vault, uint256 allocation);
    event VaultRemoved(address indexed vault);
    event AllocationUpdated(address indexed vault, uint256 newAllocation);
    event Rebalanced(address[] vaults, uint256[] allocations);
    event Deposited(uint256 totalAmount, address[] vaults, uint256[] amounts);
    event Withdrawn(uint256 totalAmount, address[] vaults, uint256[] amounts);

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                     */
    /* -------------------------------------------------------------------------- */

    error Unauthorized();
    error InvalidAllocation();
    error VaultAlreadyAdded();
    error VaultNotFound();
    error AllocationTooHigh();
    error TotalAllocationExceeded();

    /* -------------------------------------------------------------------------- */
    /*                                  MODIFIERS                                   */
    /* -------------------------------------------------------------------------- */

    modifier onlyOwner() {
        if(msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier onlyFactory() {
        if(msg.sender != factory) revert Unauthorized();
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZER                                    */
    /* -------------------------------------------------------------------------- */

    function initialize(address _owner) external initializer {
        __ReentrancyGuard_init();
        owner = _owner;
        factory = msg.sender;
    }

    /* -------------------------------------------------------------------------- */
    /*                             VAULT MANAGEMENT                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Add a new vault with allocation
    /// @param vault Vault address to add
    /// @param allocation Allocation percentage in basis points
    function addVault(address vault, uint256 allocation) external onlyOwner {
        if(vaultAllocations[vault].active) revert VaultAlreadyAdded();
        if(allocation > MAX_BPS) revert AllocationTooHigh();

        uint256 totalAllocation = getTotalAllocation() + allocation;
        if(totalAllocation > MAX_BPS) revert TotalAllocationExceeded();

        vaultAllocations[vault] = VaultAllocation({
            vault: vault,
            allocation: allocation,
            active: true
        });
        activeVaults.push(vault);

        emit VaultAdded(vault, allocation);
    }

    /// @notice Remove a vault
    /// @param vault Vault address to remove
    function removeVault(address vault) external onlyOwner {
        if(!vaultAllocations[vault].active) revert VaultNotFound();

        vaultAllocations[vault].active = false;
        vaultAllocations[vault].allocation = 0;

        // Remove from active vaults array
        for(uint i = 0; i < activeVaults.length; i++) {
            if(activeVaults[i] == vault) {
                activeVaults[i] = activeVaults[activeVaults.length - 1];
                activeVaults.pop();
                break;
            }
        }

        emit VaultRemoved(vault);
    }

    /// @notice Update allocation for a vault
    /// @param vault Vault address to update
    /// @param newAllocation New allocation percentage in basis points
    function updateAllocation(address vault, uint256 newAllocation) external onlyOwner {
        if(!vaultAllocations[vault].active) revert VaultNotFound();
        if(newAllocation > MAX_BPS) revert AllocationTooHigh();

        uint256 totalAllocation = getTotalAllocation() - vaultAllocations[vault].allocation + newAllocation;
        if(totalAllocation > MAX_BPS) revert TotalAllocationExceeded();

        vaultAllocations[vault].allocation = newAllocation;

        emit AllocationUpdated(vault, newAllocation);
    }

    /* -------------------------------------------------------------------------- */
    /*                            DEPOSIT/WITHDRAW LOGIC                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Deposit funds according to current allocations
    /// @param asset Asset to deposit
    /// @param amount Total amount to deposit
    function deposit(address asset, uint256 amount) external nonReentrant onlyOwner {
        uint256 totalAllocation = getTotalAllocation();
        if(totalAllocation == 0) revert InvalidAllocation();

        uint256[] memory amounts = new uint256[](activeVaults.length);
        uint256 remainingAmount = amount;

        // Calculate and execute deposits based on allocations
        for(uint i = 0; i < activeVaults.length; i++) {
            address vault = activeVaults[i];
            uint256 vaultAmount;

            if(i == activeVaults.length - 1) {
                vaultAmount = remainingAmount;
            } else {
                vaultAmount = (amount * vaultAllocations[vault].allocation) / totalAllocation;
                remainingAmount -= vaultAmount;
            }

            amounts[i] = vaultAmount;

            if(vaultAmount > 0) {
                IERC20(asset).safeTransferFrom(msg.sender, address(this), vaultAmount);
                IERC20(asset).approve(vault, vaultAmount);
                Vault(vault).deposit(vaultAmount, owner);
            }
        }

        emit Deposited(amount, activeVaults, amounts);
    }

    /// @notice Withdraw funds proportionally from all vaults
    /// @param percentage Percentage of total funds to withdraw in basis points
    function withdraw(uint256 percentage) external nonReentrant onlyOwner {
        if(percentage == 0 || percentage > MAX_BPS) revert InvalidAllocation();

        uint256[] memory amounts = new uint256[](activeVaults.length);

        // Calculate and execute withdrawals
        for(uint i = 0; i < activeVaults.length; i++) {
            address vault = activeVaults[i];
            uint256 vaultShares = IERC20(vault).balanceOf(owner);
            uint256 withdrawAmount = (vaultShares * percentage) / MAX_BPS;

            if(withdrawAmount > 0) {
                amounts[i] = withdrawAmount;
                Vault(vault).withdraw(withdrawAmount, owner, owner);
            }
        }

        emit Withdrawn(percentage, activeVaults, amounts);
    }

    /// @notice Rebalance holdings to match current allocations
    function rebalance() external nonReentrant onlyOwner {
        uint256 totalAllocation = getTotalAllocation();
        if(totalAllocation == 0) revert InvalidAllocation();

        // Calculate total value across all vaults
        uint256 totalValue;
        for(uint i = 0; i < activeVaults.length; i++) {
            address vault = activeVaults[i];
            uint256 vaultShares = IERC20(vault).balanceOf(owner);
            if(vaultShares > 0) {
                totalValue += Vault(vault).convertToAssets(vaultShares);
            }
        }

        if(totalValue == 0) return;

        // Rebalance each vault
        for(uint i = 0; i < activeVaults.length; i++) {
            address vault = activeVaults[i];
            uint256 targetValue = (totalValue * vaultAllocations[vault].allocation) / totalAllocation;
            uint256 currentValue = Vault(vault).convertToAssets(IERC20(vault).balanceOf(owner));

            if(targetValue > currentValue) {
                // Need to deposit more
                uint256 depositAmount = targetValue - currentValue;
                IERC20(Vault(vault).asset()).safeTransferFrom(owner, address(this), depositAmount);
                IERC20(Vault(vault).asset()).approve(vault, depositAmount);
                Vault(vault).deposit(depositAmount, owner);
            } else if(targetValue < currentValue) {
                // Need to withdraw
                uint256 withdrawAmount = currentValue - targetValue;
                Vault(vault).withdraw(withdrawAmount, owner, owner);
            }
        }

        emit Rebalanced(activeVaults, _getAllocations());
    }

    /* -------------------------------------------------------------------------- */
    /*                                   VIEWS                                      */
    /* -------------------------------------------------------------------------- */

    /// @notice Get total allocation across all active vaults
    /// @return Total allocation in basis points
    function getTotalAllocation() public view returns (uint256) {
        uint256 total;
        for(uint i = 0; i < activeVaults.length; i++) {
            total += vaultAllocations[activeVaults[i]].allocation;
        }
        return total;
    }

    /// @notice Get all active vaults
    /// @return Array of active vault addresses
    function getActiveVaults() external view returns (address[] memory) {
        return activeVaults;
    }

    /// @notice Helper to get current allocations
    function _getAllocations() internal view returns (uint256[] memory) {
        uint256[] memory allocations = new uint256[](activeVaults.length);
        for(uint i = 0; i < activeVaults.length; i++) {
            allocations[i] = vaultAllocations[activeVaults[i]].allocation;
        }
        return allocations;
    }
}

/**
 * @title PersonalMetaVaultFactory
 * @notice Factory contract for deploying personal meta vaults
 */
contract PersonalMetaVaultFactory is AccessControlDefaultAdminRulesUpgradeable {
    event MetaVaultCreated(address indexed owner, address metaVault);

    mapping(address => address) public userMetaVaults;

    function initialize(
        address initialAdmin,
        uint48 initialDelay
    ) external initializer {
        __AccessControlDefaultAdminRules_init(initialDelay, initialAdmin);
    }

    /// @notice Create a new personal meta vault
    function createMetaVault() external returns (address) {
        require(userMetaVaults[msg.sender] == address(0), "Already has meta vault");

        PersonalMetaVault metaVault = new PersonalMetaVault();
        metaVault.initialize(msg.sender);

        userMetaVaults[msg.sender] = address(metaVault);

        emit MetaVaultCreated(msg.sender, address(metaVault));
        return address(metaVault);
    }

    /// @notice Get user's meta vault
    function getMetaVault(address user) external view returns (address) {
        return userMetaVaults[user];
    }
}