// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessControlDefaultAdminRulesUpgradeable} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlDefaultAdminRulesUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Vault} from "./Vault.sol";

contract PersonalMetaVault is Initializable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    struct VaultAllocation {
        address vault;
        uint256 allocation;
        bool active;
        uint256 lastUpdateTime;
        uint256 lastBalance;
        uint256 lastPrice;
    }

    struct VaultPerformance {
        uint256 apr;
        uint256 tvl;
        uint256 utilizationRate;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  CONSTANTS                                   */
    /* -------------------------------------------------------------------------- */

    uint256 public constant MAX_BPS = 10000;
    uint256 public constant REBALANCE_THRESHOLD = 500; // 5%
    uint256 public constant MAX_SLIPPAGE = 100; // 1%

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                    */
    /* -------------------------------------------------------------------------- */

    address public owner;
    address public factory;
    mapping(address => VaultAllocation) public vaultAllocations;
    mapping(address => VaultPerformance) public vaultPerformance;
    address[] public activeVaults;
    
    // Limits & Security
    mapping(address => uint256) public dailyLimits;
    mapping(address => uint256) public dailyVolume;
    mapping(address => uint256) public lastActivityTime;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                     */
    /* -------------------------------------------------------------------------- */

    event VaultAdded(address indexed vault, uint256 allocation);
    event VaultRemoved(address indexed vault);
    event AllocationUpdated(address indexed vault, uint256 newAllocation);
    event Rebalanced(address[] vaults, uint256[] allocations);
    event Deposited(uint256 totalAmount, address[] vaults, uint256[] amounts);
    event Withdrawn(uint256 totalAmount, address[] vaults, uint256[] amounts);
    event PerformanceUpdated(address indexed vault, uint256 apr, uint256 tvl, uint256 utilizationRate);
    event DailyLimitUpdated(address indexed user, uint256 newLimit);

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                     */
    /* -------------------------------------------------------------------------- */

    error Unauthorized();
    error InvalidAllocation();
    error VaultAlreadyAdded();
    error VaultNotFound();
    error AllocationTooHigh();
    error TotalAllocationExceeded();
    error DailyLimitExceeded();
    error SlippageExceeded();
    error NoRebalanceNeeded();

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

    modifier checkDailyLimit(uint256 amount) {
        if (!_checkAndUpdateDailyLimit(amount)) revert DailyLimitExceeded();
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

    function addVault(address vault, uint256 allocation) external onlyOwner {
        if(vaultAllocations[vault].active) revert VaultAlreadyAdded();
        if(allocation > MAX_BPS) revert AllocationTooHigh();
        if(allocation == 0) revert InvalidAllocation();

        uint256 totalAllocation = getTotalAllocation() + allocation;
        if(totalAllocation > MAX_BPS) revert TotalAllocationExceeded();

        vaultAllocations[vault] = VaultAllocation({
            vault: vault,
            allocation: allocation,
            active: true,
            lastUpdateTime: block.timestamp,
            lastBalance: 0,
            lastPrice: 0
        });
        activeVaults.push(vault);

        emit VaultAdded(vault, allocation);
    }

    function removeVault(address vault) external onlyOwner {
        if(!vaultAllocations[vault].active) revert VaultNotFound();

        vaultAllocations[vault].active = false;
        vaultAllocations[vault].allocation = 0;

        for(uint i = 0; i < activeVaults.length; i++) {
            if(activeVaults[i] == vault) {
                activeVaults[i] = activeVaults[activeVaults.length - 1];
                activeVaults.pop();
                break;
            }
        }

        emit VaultRemoved(vault);
    }

    /* -------------------------------------------------------------------------- */
    /*                            DEPOSIT/WITHDRAW LOGIC                            */
    /* -------------------------------------------------------------------------- */

    function deposit(
        address asset, 
        uint256 amount
    ) external nonReentrant onlyOwner checkDailyLimit(amount) {
        if(amount == 0) revert InvalidAllocation();

        (address[] memory vaults, uint256[] memory amounts) = _calculateOptimalDistribution(amount);
        uint256 totalDeposited;

        for(uint i = 0; i < vaults.length; i++) {
            if(amounts[i] > 0) {
                totalDeposited += _executeDeposit(vaults[i], asset, amounts[i]);
                _updateVaultPerformance(vaults[i]);
            }
        }

        emit Deposited(amount, vaults, amounts);
    }

    function withdraw(
        uint256 percentage
    ) external nonReentrant onlyOwner returns (uint256 totalWithdrawn) {
        if(percentage == 0 || percentage > MAX_BPS) revert InvalidAllocation();

        for(uint i = 0; i < activeVaults.length; i++) {
            address vault = activeVaults[i];
            uint256 vaultShares = IERC20(vault).balanceOf(owner);
            uint256 withdrawAmount = (vaultShares * percentage) / MAX_BPS;

            if(withdrawAmount > 0) {
                uint256 withdrawn = _executeWithdraw(vault, withdrawAmount);
                totalWithdrawn += withdrawn;
                _updateVaultPerformance(vault);
            }
        }

        emit Withdrawn(percentage, activeVaults, _getAllocations());
        return totalWithdrawn;
    }

    function rebalance() external nonReentrant onlyOwner {
        if (!shouldRebalance()) revert NoRebalanceNeeded();

        uint256 totalValue;
        uint256[] memory currentValues = new uint256[](activeVaults.length);

        for(uint i = 0; i < activeVaults.length; i++) {
            currentValues[i] = _getVaultValue(activeVaults[i]);
            totalValue += currentValues[i];
        }

        for(uint i = 0; i < activeVaults.length; i++) {
            address vault = activeVaults[i];
            uint256 targetValue = (totalValue * vaultAllocations[vault].allocation) / MAX_BPS;

            if(currentValues[i] != targetValue) {
                _rebalanceVault(vault, currentValues[i], targetValue);
            }
        }

        emit Rebalanced(activeVaults, _getAllocations());
    }

    /* -------------------------------------------------------------------------- */
    /*                                   VIEWS                                      */
    /* -------------------------------------------------------------------------- */

    function getTotalAllocation() public view returns (uint256) {
        uint256 total;
        for(uint i = 0; i < activeVaults.length; i++) {
            total += vaultAllocations[activeVaults[i]].allocation;
        }
        return total;
    }

    function getActiveVaults() external view returns (address[] memory) {
        return activeVaults;
    }

    function shouldRebalance() public view returns (bool) {
        for(uint i = 0; i < activeVaults.length; i++) {
            address vault = activeVaults[i];
            uint256 currentAllocation = _getCurrentAllocation(vault);
            uint256 targetAllocation = vaultAllocations[vault].allocation;
            
            uint256 deviation = currentAllocation > targetAllocation ? 
                currentAllocation - targetAllocation :
                targetAllocation - currentAllocation;
                
            if(deviation > REBALANCE_THRESHOLD) {
                return true;
            }
        }
        return false;
    }

    /* -------------------------------------------------------------------------- */
    /*                             INTERNAL FUNCTIONS                               */
    /* -------------------------------------------------------------------------- */

    function _executeDeposit(
        address vault,
        address asset,
        uint256 amount
    ) internal returns (uint256) {
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(asset).approve(vault, amount);
        return Vault(vault).deposit(amount, owner);
    }

    function _executeWithdraw(
        address vault,
        uint256 amount
    ) internal returns (uint256) {
        return Vault(vault).withdraw(amount, owner, owner);
    }

    function _getVaultValue(address vault) internal view returns (uint256) {
        uint256 balance = IERC20(vault).balanceOf(address(this));
        return Vault(vault).convertToAssets(balance);
    }

    function _getCurrentAllocation(address vault) internal view returns (uint256) {
        uint256 vaultValue = _getVaultValue(vault);
        uint256 totalValue = _getTotalValue();
        if (totalValue == 0) return 0;
        return (vaultValue * MAX_BPS) / totalValue;
    }

    function _getTotalValue() internal view returns (uint256 total) {
        for(uint i = 0; i < activeVaults.length; i++) {
            total += _getVaultValue(activeVaults[i]);
        }
    }

    function _getAllocations() internal view returns (uint256[] memory) {
        uint256[] memory allocations = new uint256[](activeVaults.length);
        for(uint i = 0; i < activeVaults.length; i++) {
            allocations[i] = vaultAllocations[activeVaults[i]].allocation;
        }
        return allocations;
    }

    function _checkAndUpdateDailyLimit(uint256 amount) internal returns (bool) {
        if(block.timestamp >= lastActivityTime[msg.sender] + 1 days) {
            dailyVolume[msg.sender] = 0;
        }
        lastActivityTime[msg.sender] = block.timestamp;
        
        uint256 newVolume = dailyVolume[msg.sender] + amount;
        if(newVolume > dailyLimits[msg.sender]) {
            return false;
        }
        
        dailyVolume[msg.sender] = newVolume;
        return true;
    }

    function _calculateOptimalDistribution(
        uint256 amount
    ) internal view returns (
        address[] memory vaults,
        uint256[] memory amounts
    ) {
        vaults = activeVaults;
        amounts = new uint256[](vaults.length);
        uint256 remaining = amount;
        
        for(uint i = 0; i < vaults.length; i++) {
            if(i == vaults.length - 1) {
                amounts[i] = remaining;
            } else {
                amounts[i] = (amount * vaultAllocations[vaults[i]].allocation) / MAX_BPS;
                remaining -= amounts[i];
            }
        }
    }

    function _rebalanceVault(
        address vault,
        uint256 currentValue,
        uint256 targetValue
    ) internal {
        address asset = address(Vault(vault).asset());
        require(asset != address(0), "Invalid asset address");
        
        if(currentValue < targetValue) {
            uint256 depositAmount = targetValue - currentValue;
            _executeDeposit(vault, asset, depositAmount);
        } else {
            uint256 withdrawAmount = currentValue - targetValue;
            _executeWithdraw(vault, withdrawAmount);
        }
    }

    function _updateVaultPerformance(address vault) internal {
        VaultAllocation storage allocation = vaultAllocations[vault];
        VaultPerformance storage performance = vaultPerformance[vault];
        
        uint256 currentValue = _getVaultValue(vault);
        uint256 timeDelta = block.timestamp - allocation.lastUpdateTime;
        
        if (timeDelta > 0 && allocation.lastBalance > 0) {
            uint256 valueChange = currentValue > allocation.lastBalance ? 
                currentValue - allocation.lastBalance : 0;
            
            performance.apr = (valueChange * 365 days * 100) / (allocation.lastBalance * timeDelta);
            performance.tvl = currentValue;
            performance.utilizationRate = (currentValue * MAX_BPS) / _getTotalValue();
            
            emit PerformanceUpdated(
                vault,
                performance.apr,
                performance.tvl,
                performance.utilizationRate
            );
        }
        
        allocation.lastBalance = currentValue;
        allocation.lastUpdateTime = block.timestamp;
    }
}

contract PersonalMetaVaultFactory is AccessControlDefaultAdminRulesUpgradeable {
    event MetaVaultCreated(address indexed owner, address metaVault);

    mapping(address => address) public userMetaVaults;

    function initialize(address initialAdmin, uint48 initialDelay) external initializer {
        __AccessControlDefaultAdminRules_init(initialDelay, initialAdmin);
    }

    function createMetaVault() external returns (address) {
        require(userMetaVaults[msg.sender] == address(0), "Already has meta vault");

        PersonalMetaVault metaVault = new PersonalMetaVault();
        metaVault.initialize(msg.sender);

        userMetaVaults[msg.sender] = address(metaVault);

        emit MetaVaultCreated(msg.sender, address(metaVault));
        return address(metaVault);
    }

    function getMetaVault(address user) external view returns (address) {
        return userMetaVaults[user];
    }
}