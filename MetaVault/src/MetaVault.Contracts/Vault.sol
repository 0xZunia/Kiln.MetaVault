// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: 2024 Kiln <contact@kiln.fi>
//
// ██╗  ██╗██╗██╗     ███╗   ██╗
// ██║ ██╔╝██║██║     ████╗  ██║
// █████╔╝ ██║██║     ██╔██╗ ██║
// ██╔═██╗ ██║██║     ██║╚██╗██║
// ██║  ██╗██║███████╗██║ ╚████║
// ╚═╝  ╚═╝╚═╝╚══════╝╚═╝  ╚═══╝
//
pragma solidity 0.8.22;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {ERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {AccessControlDefaultAdminRulesUpgradeable} from
    "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlDefaultAdminRulesUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {
    AmountZero,
    AddressNotContract,
    AddressBlocked,
    DepositPaused,
    InvalidConnectorName,
    MinimumTotalSupplyNotReached,
    NoAdditionalRewardsClaimed,
    NoAdditionalRewardsStrategy,
    NothingToCollect,
    NotTransferable,
    OffsetTooHigh,
    PreviewZero,
    RemainderNotZero,
    TotalAssetsDecreased,
    UnauthorizedSpender,
    WrongDepositFee,
    WrongRewardFee,
    AddressNotInternallySanctionedOnly,
    InsufficientLiquidity,
    NotConfiguredFactory
} from "./libraries/Errors.sol";
import {IConnector} from "./interfaces/IConnector.sol";
import {BlockList} from "./BlockList.sol";
import {IConnectorRegistry} from "./interfaces/IConnectorRegistry.sol";
import {IFeeDispatcher} from "./interfaces/IFeeDispatcher.sol";
import {_MAX_PERCENT} from "./libraries/Constants.sol";
import {ISelf} from "./interfaces/ISelf.sol";

/// @title Kiln DeFi Integration Vault.
/// @notice ERC-4626 Vault depositing assets into a protocol.
/// @author maximebrugel @ Kiln.
/// @dev Using ERC-7201 standard.
contract Vault is ERC4626Upgradeable, AccessControlDefaultAdminRulesUpgradeable, ReentrancyGuardUpgradeable {
    using Address for address;
    using Math for uint256;

    /* -------------------------------------------------------------------------- */
    /*                                    ENUMS                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice The strategy to apply when additional rewards are collected.
    /// @param None No additional rewards are collected.
    /// @param Claim Additional rewards are claimed and transferred to the CLAIM_MANAGER.
    /// @param Reinvest Additional rewards are reinvested in the underlying protocol.
    enum AdditionalRewardsStrategy {
        None,
        Claim,
        Reinvest
    }

    /* -------------------------------------------------------------------------- */
    /*                                  CONSTANTS                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Represents the maximum fee that can be charged for reward and deposit fees.
    uint256 internal constant _MAX_FEE = 35;

    /// @dev Represents the maximum offset.
    uint8 internal constant _MAX_OFFSET = 23;

    /// @notice The role code for the fee manager.
    bytes32 public constant FEE_MANAGER_ROLE = bytes32("FEE_MANAGER");

    /// @notice The role code for fee collector.
    bytes32 public constant FEE_COLLECTOR_ROLE = bytes32("FEE_COLLECTOR");

    /// @notice The role code for the sanctions manager.
    bytes32 public constant SANCTIONS_MANAGER_ROLE = bytes32("SANCTIONS_MANAGER");

    /// @notice The role code for the claim manager.
    bytes32 public constant CLAIM_MANAGER_ROLE = bytes32("CLAIM_MANAGER");

    /// @notice The role code for the pauser role.
    bytes32 public constant PAUSER_ROLE = bytes32("PAUSER");

    /// @notice The role code for the unpauser role.
    bytes32 public constant UNPAUSER_ROLE = bytes32("UNPAUSER");

    /// @notice The role code for the spender role.
    /// @dev Only used in conjunction with ExternalAccessControl to verify if a user has this role.
    bytes32 public constant SPENDER_ROLE = bytes32("SPENDER");

    /* -------------------------------------------------------------------------- */
    /*                                  IMMUTABLE                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev The address of the implementation (regardless of the context).
    address internal immutable _self = address(this);

    /// @dev The external access control proxy contract.
    IAccessControl internal immutable _externalAccessControl;

    /// @dev The factory address.
    address public immutable vaultFactory;

    /* -------------------------------------------------------------------------- */
    /*                               STORAGE (proxy)                              */
    /* -------------------------------------------------------------------------- */

    /// @notice The storage layout of the contract.
    /// @param _connectorRegistry The connector registry address.
    /// @param _connectorName The name of the connector used by the vault to interact with the proper protocol.
    /// @param _depositFee The deposit fee (between 0 and 100, scaled to the underlying asset decimals).
    /// @param _rewardFee The reward fee (between 0 and 100, scaled to the underlying asset decimals).
    /// @param _lastTotalAssets The last amount of the underlying asset that is “managed” by the vault.
    /// @param _minTotalSupply The minimum total supply of the vault shares.
    /// @param _transferable True if the vault shares are transferable, False if not.
    /// @param _offset The offset (inflation attack mitigation).
    /// @param _collectableRewardFeesShares The amount of reward fees shares that can be collected by the FeeManager.
    /// @param _blockList The blocklist contract.
    /// @param _depositPaused True if the deposits are paused, False if not.
    /// @param _additionalRewardsStrategy The strategy to apply when additional rewards are collected
    /// @param _feeDispatcher The fee dispatcher contract.
    struct VaultStorage {
        IConnectorRegistry _connectorRegistry;
        bytes32 _connectorName;
        uint256 _depositFee;
        uint256 _rewardFee;
        uint256 _lastTotalAssets;
        uint256 _minTotalSupply;
        bool _transferable;
        uint8 _offset;
        uint256 _collectableRewardFeesShares;
        BlockList _blockList;
        bool _depositPaused;
        AdditionalRewardsStrategy _additionalRewardsStrategy;
        IFeeDispatcher _feeDispatcher;
    }

    function _getVaultStorage() private pure returns (VaultStorage storage $) {
        assembly {
            $.slot := VaultStorageLocation
        }
    }

    /// @dev The storage slot of the VaultStorage struct in the proxy contract.
    ///      keccak256(abi.encode(uint256(keccak256("kiln.storage.vault")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant VaultStorageLocation = 0x6bb5a2a0ae924c2ea94f037035a09f65614421e2a7d96c9bcbd59acdd32e6000;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    /// @dev Emitted when the additional rewards strategy is updated.
    /// @param newAdditionalRewardsStrategy The new additional rewards strategy.
    event AdditionalRewardsStrategyUpdated(AdditionalRewardsStrategy newAdditionalRewardsStrategy);

    /// @dev Emitted when the deposit fee is updated.
    /// @param newDepositFee The new deposit fee.
    event DepositFeeUpdated(uint256 newDepositFee);

    /// @dev Emitted when the reward fee is updated.
    /// @param newRewardFee The new reward fee.
    event RewardFeeUpdated(uint256 newRewardFee);

    /// @dev Emitted when the connector registry is updated.
    /// @param newConnectorRegistry The new connector registry.
    event ConnectorRegistryUpdated(IConnectorRegistry newConnectorRegistry);

    /// @dev Emitted when the connector name is updated.
    /// @param newConnectorName The new connector name.
    event ConnectorNameUpdated(bytes32 newConnectorName);

    /// @dev Emitted when the transferable flag is updated.
    /// @param newTransferableFlag The new transferable flag.
    event TransferableUpdated(bool newTransferableFlag);

    /// @dev Emitted when the ERC4626 name is initialized.
    /// @param name The name of the ERC4626.
    event NameInitialized(string name);

    /// @dev Emitted when the ERC4626 symbol is initialized.
    /// @param symbol The symbol of the ERC4626.
    event SymbolInitialized(string symbol);

    /// @dev Emitted when an asset is initialized.
    /// @param asset The (ERC20) asset that is initialized.
    event AssetInitialized(IERC20 asset);

    /// @dev Emitted when the offset is initialized.
    /// @param offset The offset.
    event OffsetInitialized(uint8 offset);

    /// @dev Emitted when the fee dispatcher is initialized.
    /// @param feeDispatcher The fee dispatcher.
    event FeeDispatcherInitialized(address feeDispatcher);

    /// @dev Emitted when minimum supply state is updated.
    /// @param newMinTotalSupply The new minimum supply state.
    event MinTotalSupplyInitialized(uint256 newMinTotalSupply);

    /// @dev Emitted when the blocklist is updated.
    /// @param newBlockList The new blocklist.
    event BlockListUpdated(BlockList newBlockList);

    /// @dev Emitted when additional rewards are claimed to the underlying protocol.
    /// @param rewardsAsset The rewards asset claimed.
    /// @param amount The amount distributed to the vault.
    event RewardsClaimed(address indexed rewardsAsset, uint256 amount);

    /* -------------------------------------------------------------------------- */
    /*                                  MODIFIERS                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Throws if the given address is sanctioned.
    ///      If the blocklist is not set, the check is skipped.
    /// @param addr The address to check.
    modifier notBlocked(address addr) {
        _notBlocked(addr);
        _;
    }

    /// @dev Throws if the deposit is paused.
    modifier whenDepositNotPaused() {
        _whenDepositNotPaused();
        _;
    }

    /// @dev Throws if the transferability involving a targeted address is not allowed.
    /// @param target The targeted address.
    modifier checkTransferability(address target) {
        _checkTransferability(target);
        _;
    }

    /// @dev Throws if the caller is not the fee manager.
    modifier onlyFactory() {
        _onlyFactory();
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                             INTERNAL MODIFIERS                             */
    /* -------------------------------------------------------------------------- */

    /// @dev Internal modifier logic to check if the given address is blocked.
    /// @param addr The address to check.
    function _notBlocked(address addr) internal view {
        BlockList _blockList = _getVaultStorage()._blockList;
        if (address(_blockList) != address(0) && _blockList.isBlocked(addr)) {
            revert AddressBlocked(addr);
        }
    }

    /// @dev Internal modifier logic to check if the deposit is paused.
    function _whenDepositNotPaused() internal view {
        if (_getVaultStorage()._depositPaused) revert DepositPaused();
    }

    /// @dev Internal logic to check if transferability involving a given address is allowed.
    ///      If the vault is not transferable, the sender or the targeted address must have the SPENDER_ROLE
    ///      (on the ExternalAccessControl).
    /// @param target The target address to check (spender, recipient,...).
    function _checkTransferability(address target) internal view {
        if (
            !_getVaultStorage()._transferable && target != _msgSender()
                && (
                    !_externalAccessControl.hasRole(SPENDER_ROLE, _msgSender())
                        && !_externalAccessControl.hasRole(SPENDER_ROLE, target)
                )
        ) {
            revert NotTransferable();
        }
    }

    /// @dev Internal modifier logic to check if the sender is the factory.
    function _onlyFactory() internal view {
        if (_msgSender() != vaultFactory) revert NotConfiguredFactory(_msgSender());
    }

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Initializes the Vault contract (implementation).
    /// @param externalAccessControl_ The external access control proxy contract.
    constructor(address externalAccessControl_, address vaultFactory_) {
        _externalAccessControl = IAccessControl(externalAccessControl_);
        vaultFactory = vaultFactory_;
    }

    /* -------------------------------------------------------------------------- */
    /*                              INITIALIZE LOGIC                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Parameters for the `initialize()` function.
    struct InitializationParams {
        IERC20 asset_;
        string name_;
        string symbol_;
        bool transferable_;
        IConnectorRegistry connectorRegistry_;
        bytes32 connectorName_;
        uint256 depositFee_;
        uint256 rewardFee_;
        address initialDefaultAdmin_;
        address initialFeeManager_;
        address initialSanctionsManager_;
        address initialClaimManager_;
        address initialPauser_;
        address initialUnpauser_;
        uint48 initialDelay_;
        uint8 offset_;
        uint256 minTotalSupply_;
    }

    /// @notice Initializes the contract in the proxy context.
    /// @dev The initialization is split into two steps:
    ///      1. Initialize the Vault (what's required for a new deployment).
    ///      2. Upgrade the Vault (what's required for an existing Vault upgrade).
    /// @param initializationParams The initialization parameters (first step)
    /// @param upgradeParams The upgrade parameters (second step).
    function initialize(InitializationParams calldata initializationParams, UpgradeParams calldata upgradeParams)
        public
        onlyFactory
    {
        _initialize(initializationParams);
        _upgrade(upgradeParams);
    }

    /// @dev Internal logic to initialize the contract in the proxy context.
    /// @param params The initialization parameters.
    function _initialize(InitializationParams calldata params) internal initializer {
        __ERC4626_init(params.asset_);
        emit AssetInitialized(params.asset_);

        __ERC20_init(params.name_, params.symbol_);
        emit NameInitialized(params.name_);
        emit SymbolInitialized(params.symbol_);

        __ReentrancyGuard_init();
        __AccessControlDefaultAdminRules_init(params.initialDelay_, params.initialDefaultAdmin_);

        __Vault_init(params);
    }

    function __Vault_init(InitializationParams calldata params) internal onlyInitializing {
        _setOffset(params.offset_);
        _setRewardFee(params.rewardFee_);
        _setDepositFee(params.depositFee_);
        _setConnectorRegistry(params.connectorRegistry_);
        _setConnectorName(params.connectorName_);
        _setTransferable(params.transferable_);
        _setMinTotalSupply(params.minTotalSupply_);
        _grantRole(FEE_MANAGER_ROLE, params.initialFeeManager_);
        _grantRole(SANCTIONS_MANAGER_ROLE, params.initialSanctionsManager_);
        _grantRole(CLAIM_MANAGER_ROLE, params.initialClaimManager_);
        _grantRole(PAUSER_ROLE, params.initialPauser_);
        _grantRole(UNPAUSER_ROLE, params.initialUnpauser_);
    }

    /* -------------------------------------------------------------------------- */
    /*                                UPGRADE LOGIC                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Parameters for the `upgrade()` function.
    struct UpgradeParams {
        IFeeDispatcher.FeeRecipient[] recipients_;
        address feeDispatcher_;
        AdditionalRewardsStrategy additionalRewardsStrategy_;
        BlockList blockList_;
        uint256 pendingDepositFee_;
        uint256 pendingRewardFee_;
        IConnectorRegistry connectorRegistry_;
        address initialFeeCollector_;
    }

    /// @notice Upgrades the contract in the proxy context.
    /// @param upgradeParams The upgrade parameters for the upgrade.
    function upgrade(UpgradeParams calldata upgradeParams) public onlyFactory {
        _upgrade(upgradeParams);
    }

    /// @dev Internal logic to upgrade the contract in the proxy context.
    /// @param params The upgrade parameters.
    function _upgrade(UpgradeParams calldata params) internal reinitializer(2) {
        __Vault_upgrade(params);
    }

    function __Vault_upgrade(UpgradeParams calldata params) internal onlyInitializing {
        _setBlockList(params.blockList_);
        _setAdditionalRewardsStrategy(params.additionalRewardsStrategy_);
        _setFeeDispatcher(params.feeDispatcher_);
        IFeeDispatcher(params.feeDispatcher_).incrementPendingDepositFee(params.pendingDepositFee_);
        IFeeDispatcher(params.feeDispatcher_).incrementPendingRewardFee(params.pendingRewardFee_);
        IFeeDispatcher(params.feeDispatcher_).setFeeRecipients(params.recipients_, _underlyingDecimals());
        _grantRole(FEE_COLLECTOR_ROLE, params.initialFeeCollector_);
        _setConnectorRegistry(params.connectorRegistry_);
        SafeERC20.forceApprove(IERC20(asset()), params.feeDispatcher_, type(uint256).max);
    }

    /// @notice Perform an arbitrary delegatecall to the factory.
    ///         Needed for migration purposes (e.g. to access an unused storage slot).
    /// @dev Only the factory can call this function, and will handle the callback.
    /// @param data The data to delegatecall.
    function delegateToFactory(bytes calldata data) external onlyFactory returns (bytes memory) {
        return ISelf(vaultFactory)._self().functionDelegateCall(data);
    }

    /* -------------------------------------------------------------------------- */
    /*                           ERC4626 (PUBLIC) LOGIC                           */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ERC4626Upgradeable
    function totalAssets() public view override returns (uint256) {
        return _getConnector().totalAssets(IERC20Metadata(asset()));
    }

    /// @inheritdoc ERC4626Upgradeable
    function maxDeposit(address) public view override returns (uint256) {
        VaultStorage storage $ = _getVaultStorage();
        if ($._connectorRegistry.paused($._connectorName) || $._depositPaused) {
            return 0;
        }
        return _maxDeposit();
    }

    /// @inheritdoc ERC4626Upgradeable
    function maxMint(address) public view override returns (uint256) {
        VaultStorage storage $ = _getVaultStorage();
        if ($._connectorRegistry.paused($._connectorName) || $._depositPaused) {
            return 0;
        }
        return _maxMint(totalAssets(), totalSupply());
    }

    /// @inheritdoc ERC4626Upgradeable
    function maxWithdraw(address owner) public view override returns (uint256) {
        VaultStorage storage $ = _getVaultStorage();
        if ($._connectorRegistry.paused($._connectorName)) {
            return 0;
        }
        return _maxWithdraw(owner);
    }

    // @inheritdoc ERC4626Upgradeable
    function maxRedeem(address owner) public view override returns (uint256) {
        VaultStorage storage $ = _getVaultStorage();
        if ($._connectorRegistry.paused($._connectorName)) {
            return 0;
        }
        return _maxRedeem(owner, totalAssets(), totalSupply());
    }

    /// @inheritdoc ERC4626Upgradeable
    function previewDeposit(uint256 assets) public view override returns (uint256) {
        (uint256 _rewardFeeShares, uint256 _newTotalAssets) = _accruedRewardFeeShares();
        (uint256 _shares,) = _previewDeposit(assets, _newTotalAssets, totalSupply() + _rewardFeeShares);
        return _shares;
    }

    /// @inheritdoc ERC4626Upgradeable
    function previewMint(uint256 shares) public view override returns (uint256) {
        (uint256 _rewardFeeShares, uint256 _newTotalAssets) = _accruedRewardFeeShares();
        (uint256 _assets,) = _previewMint(shares, _newTotalAssets, totalSupply() + _rewardFeeShares);
        return _assets;
    }

    /// @inheritdoc ERC4626Upgradeable
    function previewWithdraw(uint256 assets) public view override returns (uint256) {
        (uint256 _rewardFeeShares, uint256 _newTotalAssets) = _accruedRewardFeeShares();

        return _roundDownPartialShares(
            assets.mulDiv(
                totalSupply() + _rewardFeeShares + 10 ** _decimalsOffset(), _newTotalAssets + 1, Math.Rounding.Ceil
            )
        );
    }

    /// @inheritdoc ERC4626Upgradeable
    function previewRedeem(uint256 shares) public view override returns (uint256) {
        (uint256 _rewardFeeShares, uint256 _newTotalAssets) = _accruedRewardFeeShares();

        return shares.mulDiv(
            _newTotalAssets + 1, totalSupply() + _rewardFeeShares + 10 ** _decimalsOffset(), Math.Rounding.Floor
        );
    }

    /// @inheritdoc ERC4626Upgradeable
    function deposit(uint256 assets, address receiver)
        public
        override
        nonReentrant
        checkTransferability(receiver)
        notBlocked(_msgSender())
        whenDepositNotPaused
        returns (uint256)
    {
        if (assets == 0) revert AmountZero();

        uint256 _maxAssets = _maxDeposit();
        if (assets > _maxAssets) revert ERC4626ExceededMaxDeposit(receiver, assets, _maxAssets);

        uint256 _newTotalAssets = _accrueRewardFee();

        (uint256 _shares, uint256 _depositFeeAmount) = _previewDeposit(assets, _newTotalAssets, totalSupply());
        if (_shares == 0) revert PreviewZero();

        _deposit(_msgSender(), receiver, assets, _shares, _depositFeeAmount);

        return _shares;
    }

    /// @inheritdoc ERC4626Upgradeable
    function mint(uint256 shares, address receiver)
        public
        override
        nonReentrant
        checkTransferability(receiver)
        notBlocked(_msgSender())
        whenDepositNotPaused
        returns (uint256)
    {
        if (shares == 0) revert AmountZero();
        _checkPartialShares(shares);

        uint256 _newTotalAssets = _accrueRewardFee();
        uint256 _newTotalSupply = totalSupply();

        uint256 _maxShares = _maxMint(_newTotalAssets, _newTotalSupply);
        if (shares > _maxShares) revert ERC4626ExceededMaxMint(receiver, shares, _maxShares);

        (uint256 _assets, uint256 _depositFeeAmount) = _previewMint(shares, _newTotalAssets, _newTotalSupply);
        if (_assets == 0) revert PreviewZero();

        _deposit(_msgSender(), receiver, _assets, shares, _depositFeeAmount);

        return _assets;
    }

    /// @inheritdoc ERC4626Upgradeable
    function withdraw(uint256 assets, address receiver, address owner)
        public
        override
        nonReentrant
        checkTransferability(receiver)
        checkTransferability(owner)
        notBlocked(_msgSender())
        notBlocked(owner)
        returns (uint256)
    {
        if (assets == 0) revert AmountZero();

        uint256 _maxAssets = _maxWithdraw(owner);
        if (assets > _maxAssets) revert ERC4626ExceededMaxWithdraw(owner, assets, _maxAssets);

        uint256 _shares = _convertToShares(assets, Math.Rounding.Ceil, _accrueRewardFee(), totalSupply());
        if (_shares == 0) revert PreviewZero();
        _shares = _roundDownPartialShares(_shares);
        _withdraw(_msgSender(), receiver, owner, assets, _shares);

        return _shares;
    }

    /// @inheritdoc ERC4626Upgradeable
    function redeem(uint256 shares, address receiver, address owner)
        public
        override
        nonReentrant
        checkTransferability(receiver)
        checkTransferability(owner)
        notBlocked(_msgSender())
        notBlocked(owner)
        returns (uint256)
    {
        if (shares == 0) revert AmountZero();
        _checkPartialShares(shares);

        uint256 _newTotalAssets = _accrueRewardFee();
        uint256 _newTotalSupply = totalSupply();

        {
            uint256 _maxShares = _maxRedeem(owner, _newTotalAssets, _newTotalSupply);
            if (shares > _maxShares) {
                revert ERC4626ExceededMaxRedeem(owner, shares, _maxShares);
            }
        }

        uint256 _assets = _convertToAssets(shares, Math.Rounding.Floor, _newTotalAssets, _newTotalSupply);
        if (_assets == 0) revert PreviewZero();
        _withdraw(_msgSender(), receiver, owner, _assets, shares);

        return _assets;
    }

    /* -------------------------------------------------------------------------- */
    /*                          ERC4626 (INTERNAL) LOGIC                          */
    /* -------------------------------------------------------------------------- */

    /// @dev Variant of ERC4626Upgradeable's _deposit but taking the deposit fee amount.
    ///      See ERC4626Upgradeable.
    /// @param caller The caller of the function.
    /// @param receiver The receiver of the minted shares.
    /// @param assets The amount of assets to deposit.
    /// @param shares The number of shares to mint.
    /// @param depositFeeAmount The amount of deposit fee in asset terms, calculated based on the deposit amount.
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares, uint256 depositFeeAmount)
        internal
    {
        uint256 _balanceBefore = IERC20(asset()).balanceOf(address(this));
        SafeERC20.safeTransferFrom(IERC20(asset()), caller, address(this), assets);
        _mint(receiver, shares);

        VaultStorage storage $ = _getVaultStorage();

        if (totalSupply() < $._minTotalSupply) revert MinimumTotalSupplyNotReached();

        // Deposit to underlying protocol
        address _connector = $._connectorRegistry.getOrRevert($._connectorName);
        _connector.functionDelegateCall(
            abi.encodeCall(
                IConnector.deposit,
                (IERC20(asset()), IERC20(asset()).balanceOf(address(this)) - _balanceBefore - depositFeeAmount)
            )
        );

        $._lastTotalAssets = totalAssets();
        $._feeDispatcher.incrementPendingDepositFee(depositFeeAmount);

        emit Deposit(caller, receiver, assets, shares);
    }

    /// @dev Variant of ERC4626Upgradeable's _withdraw. See ERC4626Upgradeable.
    /// @param caller The caller of the function.
    /// @param receiver The receiver of the withdrawn assets.
    /// @param owner The owner of the shares to redeem.
    /// @param assets The amount of assets to withdraw from the underlying protocol.
    /// @param shares The number of shares to burn.
    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }
        _burn(owner, shares);

        // Withdraw from underlying protocol
        VaultStorage storage $ = _getVaultStorage();
        address _connector = $._connectorRegistry.getOrRevert($._connectorName);
        uint256 _balanceBefore = IERC20(asset()).balanceOf(address(this));
        _connector.functionDelegateCall(abi.encodeCall(IConnector.withdraw, (IERC20(asset()), assets)));

        SafeERC20.safeTransfer(IERC20(asset()), receiver, IERC20(asset()).balanceOf(address(this)) - _balanceBefore);

        $._lastTotalAssets = totalAssets();

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    /// @dev Internal function to retrieve the max depositable amount.
    ///      Calls the connector to get the max depositable amount for the asset (e.g. the supply cap).
    function _maxDeposit() internal view returns (uint256) {
        return _getConnector().maxDeposit(IERC20(asset()));
    }

    /// @dev Internal function to retrieve the max mintable amount.
    /// @param newTotalAssets The Vault's total assets.
    /// @param newTotalSupply The (shares) total supply.
    function _maxMint(uint256 newTotalAssets, uint256 newTotalSupply) internal view returns (uint256) {
        uint256 _maxDepositable = _maxDeposit();

        if (_maxDepositable == type(uint256).max) {
            return type(uint256).max;
        }

        return _convertToShares(_maxDepositable, Math.Rounding.Floor, newTotalAssets, newTotalSupply);
    }

    /// @dev Internal function to retrieve the max withdrawable amount for a given owner.
    /// @param owner The owner of the shares.
    function _maxWithdraw(address owner) internal view returns (uint256) {
        return Math.min(_getConnector().maxWithdraw(IERC20(asset())), previewRedeem(balanceOf(owner)));
    }

    /// @dev Internal function to retrieve the max redeemable amount for a given owner.
    /// @param owner The owner of the shares.
    /// @param newTotalAssets The Vault's total assets.
    /// @param newTotalSupply The (shares) total supply.
    function _maxRedeem(address owner, uint256 newTotalAssets, uint256 newTotalSupply)
        internal
        view
        returns (uint256)
    {
        uint256 _maxWithdrawable = _getConnector().maxWithdraw(IERC20(asset()));

        if (_maxWithdrawable == type(uint256).max) {
            return balanceOf(owner);
        }

        return Math.min(
            _convertToShares(_maxWithdrawable, Math.Rounding.Floor, newTotalAssets, newTotalSupply), balanceOf(owner)
        );
    }

    /// @dev Estimates the number of shares mintable from a given deposit and the associated deposit fee.
    /// @param assets The amount of assets to deposit.
    /// @param newTotalAssets The Vault's total assets
    /// @param supply The (shares) total supply.
    /// @return shares The number of shares that can be minted from the deposited assets, after deducting the deposit fee.
    /// @return depositFeeAmount The amount of deposit fee in asset terms, calculated based on the deposit amount.
    function _previewDeposit(uint256 assets, uint256 newTotalAssets, uint256 supply)
        internal
        view
        returns (uint256 shares, uint256 depositFeeAmount)
    {
        VaultStorage storage $ = _getVaultStorage();

        // Calculate the deposit fee amount.
        // This is a portion of the deposited assets, scaled by the deposit fee rate and adjusted for the asset's decimals.
        depositFeeAmount = assets.mulDiv($._depositFee, _MAX_PERCENT * 10 ** _underlyingDecimals());

        // Convert the net asset amount (after deducting the deposit fee) to shares.
        // The conversion uses floor rounding to determine the number of shares that can be minted.
        // If partial shares are emitted, they are rounded down to the nearest whole number.
        shares = _roundDownPartialShares(
            _convertToShares(assets - depositFeeAmount, Math.Rounding.Floor, newTotalAssets, supply)
        );
    }

    /// @dev Estimates the asset amount and deposit fee for minting a specified number of shares.
    /// @param shares The number of shares to be minted.
    /// @param newTotalAssets The Vault's total assets.
    /// @param supply The (shares) total supply.
    /// @return assets The total amount of assets required to mint the specified number of shares, including the deposit fee.
    /// @return depositFeeAmount The amount of deposit fee in asset terms deducted when minting the shares.
    function _previewMint(uint256 shares, uint256 newTotalAssets, uint256 supply)
        internal
        view
        returns (uint256 assets, uint256 depositFeeAmount)
    {
        VaultStorage storage $ = _getVaultStorage();
        uint256 _depositFee = $._depositFee;
        uint256 _decimals = _underlyingDecimals();

        // Convert the number of shares to assets with ceiling rounding.
        // This gives us a raw asset value equivalent to the shares before considering deposit fees.
        uint256 _rawAssetValue = _convertToAssets(shares, Math.Rounding.Ceil, newTotalAssets, supply);

        // To ensure accuracy in calculations, it's necessary to scale values up.
        uint256 _scaledRawAssetValue = _rawAssetValue * 10 ** _decimals;

        // The deposit fee is deducted from the maximum percent scale adjusted for decimals.
        uint256 _adjustedMaxPercent = (_MAX_PERCENT * 10 ** _decimals) - _depositFee;

        // Calculate the assets required to mint the shares, including the deposit fee.
        //
        //            _MAX_PERCENT * (_rawAssetValue * 10 ** decimals)
        // assets = -----------------------------------------------------
        //             (_MAX_PERCENT * 10 ** decimals) - _depositFee
        //
        // Note: _depositFee is already scaled to asset decimals.
        //
        assets = _scaledRawAssetValue.mulDiv(_MAX_PERCENT, _adjustedMaxPercent, Math.Rounding.Ceil);

        // Calculate the deposit fee amount from the assets required to mint the shares.
        depositFeeAmount = assets.mulDiv(_depositFee, _MAX_PERCENT * 10 ** _decimals, Math.Rounding.Floor);
    }

    /// @dev Variant of  _convertToShares from ERC4626Upgradeable but taking the totalAssets/totalSupply
    ///      parameters instead of calling `totalAssets()` and `totalSupply()`.
    function _convertToShares(uint256 assets, Math.Rounding rounding, uint256 total, uint256 supply)
        internal
        view
        returns (uint256)
    {
        return assets.mulDiv(supply + 10 ** _decimalsOffset(), total + 1, rounding);
    }

    /// @dev Variant of _convertToAssets from ERC4626Upgradeable but taking the totalAssets/totalSupply
    ///      parameters instead of calling `totalAssets()` and `totalSupply()`.
    function _convertToAssets(uint256 shares, Math.Rounding rounding, uint256 total, uint256 supply)
        internal
        view
        returns (uint256)
    {
        return shares.mulDiv(total + 1, supply + 10 ** _decimalsOffset(), rounding);
    }

    /// @inheritdoc ERC4626Upgradeable
    function _decimalsOffset() internal view override returns (uint8) {
        return _getVaultStorage()._offset;
    }

    /// @dev Internal function accrue the reward fee and mints the shares.
    /// @return newTotalAssets The vaults total assets after accruing the interest.
    function _accrueRewardFee() internal returns (uint256 newTotalAssets) {
        uint256 rewardFeeShares;
        (rewardFeeShares, newTotalAssets) = _accruedRewardFeeShares();

        if (rewardFeeShares != 0) {
            _mint(address(this), rewardFeeShares);
            _getVaultStorage()._collectableRewardFeesShares += rewardFeeShares;
        }
    }

    /// @dev Computes and returns the rewardFee shares to mint and the new vault's total assets.
    /// @return rewardFeeShares The number of shares to mint as reward fee.
    /// @return newTotalAssets The vaults total assets after accruing the interest.
    function _accruedRewardFeeShares() internal view returns (uint256 rewardFeeShares, uint256 newTotalAssets) {
        VaultStorage storage $ = _getVaultStorage();

        newTotalAssets = totalAssets();
        (, uint256 _reward) = newTotalAssets.trySub($._lastTotalAssets);

        if (_reward != 0 && $._rewardFee != 0) {
            uint256 _rewardFeeAmount =
                _reward.mulDiv($._rewardFee, _MAX_PERCENT * 10 ** _underlyingDecimals(), Math.Rounding.Floor);

            // Reward fee is subtracted from the total assets as it's already increased by total interest
            // (including reward fee).
            rewardFeeShares = _convertToShares(
                _rewardFeeAmount, Math.Rounding.Floor, newTotalAssets - _rewardFeeAmount, totalSupply()
            );
        }
    }

    /// @dev Internal function that throws an error if the remainder of the shares is not zero.
    /// @param shares The number of shares to mint/transfer.
    function _checkPartialShares(uint256 shares) internal view {
        uint8 _offset = _decimalsOffset();
        if (_offset > 0) {
            if (shares % 10 ** _offset > 0) revert RemainderNotZero(shares);
        }
    }

    /// @dev Internal function to round down the partial shares, in case of a non-zero offset.
    /// @param shares The number of shares to round down.
    /// @return The rounded down number of shares.
    function _roundDownPartialShares(uint256 shares) internal view returns (uint256) {
        uint8 _offset = _decimalsOffset();
        if (_offset > 0) {
            shares -= shares % 10 ** _offset;
        }
        return shares;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 ERC20 LOGIC                                */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IERC20
    function transfer(address to, uint256 value)
        public
        override(ERC20Upgradeable, IERC20)
        checkTransferability(to)
        notBlocked(_msgSender())
        notBlocked(to)
        returns (bool)
    {
        _checkPartialShares(value);
        return super.transfer(to, value);
    }

    /// @inheritdoc ERC20Upgradeable
    function transferFrom(address from, address to, uint256 value)
        public
        override(ERC20Upgradeable, IERC20)
        checkTransferability(from)
        checkTransferability(to)
        notBlocked(_msgSender())
        notBlocked(from)
        notBlocked(to)
        returns (bool)
    {
        _checkPartialShares(value);
        return super.transferFrom(from, to, value);
    }

    /// @inheritdoc IERC20
    function approve(address spender, uint256 value)
        public
        override(ERC20Upgradeable, IERC20)
        checkTransferability(spender)
        notBlocked(_msgSender())
        notBlocked(spender)
        returns (bool)
    {
        return super.approve(spender, value);
    }

    /* -------------------------------------------------------------------------- */
    /*                            FEE MANAGEMENT LOGIC                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Dispatches the collected fees to the fee recipients.
    function dispatchFees() external nonReentrant {
        VaultStorage storage $ = _getVaultStorage();
        $._feeDispatcher.dispatchFees(IERC20(asset()), _underlyingDecimals());
    }

    /// @notice Collects the reward fees.
    function collectRewardFees() external nonReentrant onlyRole(FEE_COLLECTOR_ROLE) {
        VaultStorage storage $ = _getVaultStorage();

        (uint256 _rewardFeeShares, uint256 _newTotalAssets) = _accruedRewardFeeShares();

        uint256 _collectable = _convertToAssets(
            $._collectableRewardFeesShares + _rewardFeeShares,
            Math.Rounding.Floor,
            _newTotalAssets,
            totalSupply() + _rewardFeeShares
        );
        if (_collectable == 0) revert NothingToCollect();

        uint256 _balanceBefore = IERC20(asset()).balanceOf(address(this));
        address _connector = $._connectorRegistry.getOrRevert($._connectorName);
        _connector.functionDelegateCall(abi.encodeCall(IConnector.withdraw, (IERC20(asset()), _collectable)));

        $._feeDispatcher.incrementPendingRewardFee(IERC20(asset()).balanceOf(address(this)) - _balanceBefore);

        _burn(address(this), $._collectableRewardFeesShares);
        $._collectableRewardFeesShares = 0;
        $._lastTotalAssets = totalAssets();
    }

    /* -------------------------------------------------------------------------- */
    /*                                 CLAIM LOGIC                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Claims additional rewards to the underlying protocol.
    /// @dev Additional rewards are considered as yield, where the reward fee can be applied.
    /// @param rewardsAsset The rewards asset to claim.
    /// @param payload The payload to pass to the connector.
    function claimAdditionalRewards(address rewardsAsset, bytes calldata payload)
        external
        nonReentrant
        onlyRole(CLAIM_MANAGER_ROLE)
    {
        VaultStorage storage $ = _getVaultStorage();
        uint256 _totalAssetsBefore = totalAssets();
        address _connector = $._connectorRegistry.getOrRevert($._connectorName);

        if ($._additionalRewardsStrategy == AdditionalRewardsStrategy.Claim) {
            IERC20 _rewardAsset = IERC20(rewardsAsset);

            bytes memory _returnData = _connector.functionDelegateCall(
                abi.encodeCall(IConnector.claim, (IERC20(asset()), _rewardAsset, payload))
            );

            uint256 _totalAssetsAfter = totalAssets();

            if (_totalAssetsBefore > _totalAssetsAfter) {
                revert TotalAssetsDecreased(_totalAssetsBefore, _totalAssetsAfter);
            }

            uint256 _collected = abi.decode(_returnData, (uint256));
            if (_collected == 0) {
                revert NoAdditionalRewardsClaimed();
            }
            emit RewardsClaimed(rewardsAsset, _collected);
        } else if ($._additionalRewardsStrategy == AdditionalRewardsStrategy.Reinvest) {
            _connector.functionDelegateCall(
                abi.encodeCall(IConnector.reinvest, (IERC20(asset()), IERC20(rewardsAsset), payload))
            );

            uint256 _totalAssetsAfter = totalAssets();
            if (_totalAssetsBefore > _totalAssetsAfter) {
                revert TotalAssetsDecreased(_totalAssetsBefore, _totalAssetsAfter);
            } else if (_totalAssetsBefore == _totalAssetsAfter) {
                revert NoAdditionalRewardsClaimed();
            }
            emit RewardsClaimed(rewardsAsset, _totalAssetsAfter - _totalAssetsBefore);
        } else {
            revert NoAdditionalRewardsStrategy();
        }
    }

    /// @notice Update the additional rewards strategy.
    /// @param strategy The new additional rewards strategy.
    function setAdditionalRewardsStrategy(AdditionalRewardsStrategy strategy) external onlyRole(CLAIM_MANAGER_ROLE) {
        _setAdditionalRewardsStrategy(strategy);
    }

    /* -------------------------------------------------------------------------- */
    /*                            SANCTIONS LIST LOGIC                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Sets the blocklist.
    /// @param newBlockList The new sanctions list.
    function setBlockList(BlockList newBlockList) external onlyRole(SANCTIONS_MANAGER_ROLE) {
        _setBlockList(newBlockList);
    }

    /// @notice Force withdraws a user from the vault.
    /// @dev The user must be blocked by the internal blocklist and not sanctioned (OFAC).
    /// @param blockedUser The user to force withdraw.
    function forceWithdraw(address blockedUser) public nonReentrant returns (uint256) {
        VaultStorage storage $ = _getVaultStorage();
        if (
            address(blockedUser) != address(0)
                && (
                    !$._blockList.isBlockedByInternalList(blockedUser)
                        || $._blockList.isSanctionedByUnderlyingList(blockedUser)
                )
        ) {
            revert AddressNotInternallySanctionedOnly(blockedUser);
        }
        uint256 _newTotalAssets = _accrueRewardFee();
        uint256 _newTotalSupply = totalSupply();

        uint256 _maxRedeemable = _maxRedeem(blockedUser, _newTotalAssets, _newTotalSupply);
        if (_maxRedeemable != balanceOf(blockedUser)) {
            revert InsufficientLiquidity();
        }

        uint256 _assets = _convertToAssets(_maxRedeemable, Math.Rounding.Floor, _newTotalAssets, _newTotalSupply);
        if (_assets == 0) revert PreviewZero();
        _withdraw(blockedUser, blockedUser, blockedUser, _assets, _maxRedeemable);

        return _assets;
    }

    /* -------------------------------------------------------------------------- */
    /*                             DEPOSIT PAUSE LOGIC                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Pauses the deposit.
    function pauseDeposit() external onlyRole(PAUSER_ROLE) {
        _getVaultStorage()._depositPaused = true;
    }

    /// @notice Unpauses the deposit.
    function unpauseDeposit() external onlyRole(UNPAUSER_ROLE) {
        _getVaultStorage()._depositPaused = false;
    }

    /* -------------------------------------------------------------------------- */
    /*                              (PUBLIC) SETTERS                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Sets the fee recipients.
    /// @param recipients The array of fee recipients.
    function setFeeRecipients(IFeeDispatcher.FeeRecipient[] calldata recipients) external onlyRole(FEE_MANAGER_ROLE) {
        _getVaultStorage()._feeDispatcher.setFeeRecipients(recipients, _underlyingDecimals());
    }

    /// @notice Sets the deposit fee.
    /// @param newDepositFee The new deposit fee.
    function setDepositFee(uint256 newDepositFee) external onlyRole(FEE_MANAGER_ROLE) {
        _setDepositFee(newDepositFee);
    }

    /// @notice Sets the reward fee.
    /// @dev This function also collects the last reward fees prior to updating the fee.
    /// @param newRewardFee The new reward fee.
    function setRewardFee(uint256 newRewardFee) external onlyRole(FEE_MANAGER_ROLE) {
        // Accrue the last reward fees prior to updating the fee amount.
        _getVaultStorage()._lastTotalAssets = _accrueRewardFee();
        _setRewardFee(newRewardFee);
    }

    /* -------------------------------------------------------------------------- */
    /*                             (INTERNAL) SETTERS                             */
    /* -------------------------------------------------------------------------- */

    /// @dev Internal logic to set the reward fee.
    /// @param newRewardFee The new reward fee.
    function _setRewardFee(uint256 newRewardFee) internal {
        if (newRewardFee > _MAX_FEE * 10 ** _underlyingDecimals()) {
            revert WrongRewardFee(newRewardFee);
        }
        _getVaultStorage()._rewardFee = newRewardFee;
        emit RewardFeeUpdated(newRewardFee);
    }

    /// @dev Internal logic to set the deposit fee.
    /// @param newDepositFee The new deposit fee.
    function _setDepositFee(uint256 newDepositFee) internal {
        if (newDepositFee > _MAX_FEE * 10 ** _underlyingDecimals()) {
            revert WrongDepositFee(newDepositFee);
        }
        _getVaultStorage()._depositFee = newDepositFee;
        emit DepositFeeUpdated(newDepositFee);
    }

    /// @notice Internal logic to set the connector registry.
    /// @param newConnectorRegistry The new connector registry.
    function _setConnectorRegistry(IConnectorRegistry newConnectorRegistry) internal {
        if (address(newConnectorRegistry).code.length == 0) revert AddressNotContract(address(newConnectorRegistry));
        _getVaultStorage()._connectorRegistry = newConnectorRegistry;
        emit ConnectorRegistryUpdated(newConnectorRegistry);
    }

    /// @notice Internal logic to set the connector name.
    /// @param newConnectorName The new connector name.
    function _setConnectorName(bytes32 newConnectorName) internal {
        VaultStorage storage $ = _getVaultStorage();
        if (!$._connectorRegistry.connectorExists(newConnectorName)) revert InvalidConnectorName(newConnectorName);
        $._connectorName = newConnectorName;
        emit ConnectorNameUpdated(newConnectorName);
    }

    /// @notice Internal logic to set the transferable flag.
    /// @param newTransferableFlag The new transferable flag.
    function _setTransferable(bool newTransferableFlag) internal {
        _getVaultStorage()._transferable = newTransferableFlag;
        emit TransferableUpdated(newTransferableFlag);
    }

    /// @notice Internal logic to set the offset.
    /// @param offset The new offset.
    function _setOffset(uint8 offset) internal {
        if (offset > _MAX_OFFSET) revert OffsetTooHigh(offset);
        _getVaultStorage()._offset = offset;
        emit OffsetInitialized(offset);
    }

    /// @notice Internal logic to set the blocklist.
    /// @dev Possible to set the blocklist to address(0) to disable it.
    /// @param newBlockList The new blocklist.
    function _setBlockList(BlockList newBlockList) internal {
        _getVaultStorage()._blockList = newBlockList;
        emit BlockListUpdated(newBlockList);
    }

    /// @notice Internal logic to set the minimum supply state.
    /// @dev This is used to prevent a griefing attack.
    /// @param newMinTotalSupply The new minimum total supply required after a deposit.
    function _setMinTotalSupply(uint256 newMinTotalSupply) internal {
        _getVaultStorage()._minTotalSupply = newMinTotalSupply;
        emit MinTotalSupplyInitialized(newMinTotalSupply);
    }

    /// @notice Internal logic to set the additional rewards strategy.
    /// @param newAdditionalRewardsStrategy The new additional rewards strategy.
    function _setAdditionalRewardsStrategy(AdditionalRewardsStrategy newAdditionalRewardsStrategy) internal {
        _getVaultStorage()._additionalRewardsStrategy = newAdditionalRewardsStrategy;
        emit AdditionalRewardsStrategyUpdated(newAdditionalRewardsStrategy);
    }

    /// @notice Internal logic to set the fee dispatcher.
    /// @param newFeeDispatcher The new fee dispatcher.
    function _setFeeDispatcher(address newFeeDispatcher) internal {
        if (address(newFeeDispatcher).code.length == 0) revert AddressNotContract(address(newFeeDispatcher));
        _getVaultStorage()._feeDispatcher = IFeeDispatcher(newFeeDispatcher);
        emit FeeDispatcherInitialized(newFeeDispatcher);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   GETTERS                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Returns if the ERC4626 share is transferable.
    /// @return transferable True if the ERC4626 share is transferable, False if not.
    function transferable() external view returns (bool) {
        return _getVaultStorage()._transferable;
    }

    /// @notice Returns the connector registry.
    /// @return connectorRegistry The connector registry.
    function connectorRegistry() external view returns (IConnectorRegistry) {
        return _getVaultStorage()._connectorRegistry;
    }

    /// @notice Returns the connector name.
    /// @return connectorName The connector name.
    function connectorName() external view returns (bytes32) {
        return _getVaultStorage()._connectorName;
    }

    /// @notice Returns the deposit fee.
    /// @return depositFee The deposit fee.
    function depositFee() external view returns (uint256) {
        return _getVaultStorage()._depositFee;
    }

    /// @notice Returns the reward fee.
    /// @return rewardFee The reward fee.
    function rewardFee() external view returns (uint256) {
        return _getVaultStorage()._rewardFee;
    }

    /// @notice Returns the additional rewards strategy.
    /// @return additionalRewardsStrategy The additional rewards strategy.
    function additionalRewardsStrategy() external view returns (AdditionalRewardsStrategy) {
        return _getVaultStorage()._additionalRewardsStrategy;
    }

    /// @notice Returns the collectable reward fees (when calling `collectRewardFees`).
    /// @return collectableRewardFees The amount of reward fees that can be collected by the FeeManager.
    function collectableRewardFees() external view returns (uint256) {
        (uint256 _accruedShares, uint256 _newTotalAssets) = _accruedRewardFeeShares();
        uint256 _totalShares = _accruedShares + _getVaultStorage()._collectableRewardFeesShares;

        return _convertToAssets(_totalShares, Math.Rounding.Floor, _newTotalAssets, totalSupply() + _accruedShares);
    }

    /// @notice Returns the blocklist.
    /// @return The blocklist.
    function blockList() external view returns (BlockList) {
        return _getVaultStorage()._blockList;
    }

    /// @notice Returns the pending deposit fee.
    /// @return The amount of pending deposit fee.
    function pendingDepositFee() public view returns (uint256) {
        return _getVaultStorage()._feeDispatcher.pendingDepositFee();
    }

    /// @notice Returns the pending reward fee.
    /// @return The amount of pending reward fee.
    function pendingRewardFee() public view returns (uint256) {
        return _getVaultStorage()._feeDispatcher.pendingRewardFee();
    }

    /// @notice Returns the list of fee recipients.
    /// @return An array of fee recipients.
    function feeRecipients() public view returns (IFeeDispatcher.FeeRecipient[] memory) {
        return _getVaultStorage()._feeDispatcher.feeRecipients();
    }

    /// @notice Returns the fee recipient details for a given address.
    /// @param recipient The address of the fee recipient.
    /// @return The fee recipient details.
    function feeRecipient(address recipient) public view returns (IFeeDispatcher.FeeRecipient memory) {
        return _getVaultStorage()._feeDispatcher.feeRecipient(recipient);
    }

    /// @notice Returns the fee recipient details at a given index.
    /// @param index The index of the fee recipient.
    /// @return The fee recipient details.
    function feeRecipientAt(uint256 index) public view returns (IFeeDispatcher.FeeRecipient memory) {
        return _getVaultStorage()._feeDispatcher.feeRecipientAt(index);
    }

    /// @dev Get the connector address.
    function _getConnector() internal view returns (IConnector) {
        VaultStorage storage $ = _getVaultStorage();
        return IConnector($._connectorRegistry.get($._connectorName));
    }

    /* -------------------------------------------------------------------------- */
    /*                               INTERNAL UTILS                               */
    /* -------------------------------------------------------------------------- */

    /// @dev Get the underlying asset decimals (without the offset).
    /// @return The underlying asset decimals.
    function _underlyingDecimals() internal view returns (uint8) {
        return IERC20Metadata(asset()).decimals();
    }
}