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

/* --------------------------------- Common --------------------------------- */

/// @dev Error emitted when the address is zero.
error AddressZero();

/// @dev Error emitted when the address is not a contract.
/// @param addr The address that was attempted to be used as a contract.
error AddressNotContract(address addr);

/// @dev Error emitted when a given amount is zero.
error AmountZero();

/// @dev Error emitted when two array lengths do not match.
error ArrayMismatch();

/// @dev Error emitted when the array is empty.
error EmptyArray();

/// @dev Error emitted when the duration to pause for is invalid
///      (before the current pauseTimestamp).
/// @param timestamp The timestamp to pause for.
error InvalidDuration(uint256 timestamp, uint256 currentTimestamp);

/// @dev Error emitted when the claim function is not available on the connector or
///      no additional rewards to claim at the moment.
error NothingToClaim();

/// @dev Error emitted when the reinvest function is not available on the connector or
///      no additional rewards to compound at the moment.
error NothingToReinvest();

/* ----------------------- VaultUpgradeableBeacon.sol ----------------------- */

/// @dev The `implementation` of the beacon is invalid.
/// @param implementation The address of the implementation that was attempted to be set.
error BeaconInvalidImplementation(address implementation);

/// @dev Error emitted when an operation is attempted on a paused contract.
error isPaused();

/// @dev Error emitted when an operation is attempted on a not paused contract.
error isNotPaused();

/// @dev Error emitted when an operation is attempted on a frozen contract.
error isFrozen();

/* -------------------------------- Vault.sol ------------------------------- */

/// @dev Error emitted when the ERC4626 is not transferable.
error NotTransferable();

/// @dev Error emitted when the deposit fee over 100%.
error WrongDepositFee(uint256 depositFee);

/// @dev Error emitted when the reward fee over 100%.
error WrongRewardFee(uint256 rewardFee);

/// @dev Error emitted when the connector name is invalid (not existing on the registry).
error InvalidConnectorName(bytes32 name);

/// @dev Error emitted when no rewards could be collected.
error NothingToCollect();

/// @dev Error emitted when a call is not a delegate call.
error NotDelegateCall();

/// @dev Error emitted when the preview result is zero (shares or assets).
error PreviewZero();

/// @dev Error emitted when the given address is on the blocklist.
error AddressBlocked(address addr);

/// @dev Error emitted when the total assets decreased.
error TotalAssetsDecreased(uint256 totalAssets, uint256 newTotalAssets);

/// @dev Error emitted when no additional rewards claimed (using the claim function).
error NoAdditionalRewardsClaimed();

/// @dev Error emitted when the deposit is paused.
error DepositPaused();

/// @dev Error emitted when the offset set is too high.
error OffsetTooHigh(uint8 offset);

/// @dev Error emitted when the remainder of transferred shares is not zero.
error RemainderNotZero(uint256 shares);

/// @dev Error emitted when the minimum totalSupply is not met after a deposit.
error MinimumTotalSupplyNotReached();

/// @dev Error emitted when the caller does not have the spender role.
error UnauthorizedSpender();

/// @dev Error emitted when no additional rewards strategy is set.
error NoAdditionalRewardsStrategy();

/// @dev Error emitted when the given address is not only in the internal sanction list.
/// @param addr The address was checked.
error AddressNotInternallySanctionedOnly(address addr);

/// @dev Error emitted when trying to forceWithdraw a user, but there is not enough liquidity.
error InsufficientLiquidity();

/// @dev Error emitted when the vault is not configured for the factory.
error VaultMisconfigured();

/// @dev Error emitted when a confirured factory reserved interaction is attempted by another.
/// @param addr The address attempting to interact.
error NotConfiguredFactory(address addr);

/* --------------------------- ConnectorRegistry.sol ------------------------- */

/// @dev Error emitted when the connector already exists.
/// @param name The name of the connector.
/// @param connector The address of the connector.
error ConnectorAlreadyExists(bytes32 name, address connector);

/// @dev Error emitted when the connector does not exist.
/// @param name The name of the connector.
error ConnectorDoesNotExist(bytes32 name);

/// @dev Error emitted when the connector is frozen.
/// @param name The name of the connector.
error ConnectorFrozen(bytes32 name);

/// @dev Error emitted when the connector is paused.
/// @param name The name of the connector.
error ConnectorPaused(bytes32 name);

/// @dev Error emitted when the connector is not paused.
/// @param name The name of the connector.
error ConnectorNotPaused(bytes32 name);

/* ---------------------------- FeeDispatcher.sol --------------------------- */

/// @dev Error emitted when a given fee recipient does not exist.
/// @param recipient The address of the given fee recipient.
error FeeRecipientDoesNotExist(address recipient);

/// @dev Error emitted when the total deposit fee split between the fee recipients is not 100%.
/// @param totalSplit The total deposit fee split.
error WrongDepositFeeSplit(uint256 totalSplit);

/// @dev Error emitted when the total reward fee split between the fee recipients is not 100%.
/// @param totalSplit The total reward fee split.
error WrongRewardFeeSplit(uint256 totalSplit);

/// @dev Error emitted when a fee recipient address is not unique (in the given array of fee recipients).
/// @param recipient The address of the fee recipient.
error FeeRecipientNotUnique(address recipient);

/* ---------------------------- VaultFactory.sol ---------------------------- */

/// @dev Error emitted when the deployer already exists.
/// @param deployer The address of the deployer.
error DeployerAlreadyExists(address deployer);

/// @dev Error emitted when the caller is not a deployer.
/// @param caller The address of the caller.
error NotDeployer(address caller);

/// @dev Error emitted when the deployer does not exist.
/// @param deployer The address of the deployer.
error InvalidDeployer(address deployer);

/// @dev Error emitted when the index is not matching the Vault address.
/// @param index The index of the Vault.
/// @param vault The address of the Vault.
error InvalidVaultIndex(uint256 index, address vault);

/* ------------------------------ Connector.sol ----------------------------- */

/// @dev Error emitted when the given rewards asset is invalid.
/// @param asset The address of the invalid rewards asset.
error InvalidRewardsAsset(address asset);

/// @dev Error emitted when the given address is an invalid 4626.
/// @param addr The address of the invalid 4626.
error Invalid4626(address addr);

/* --------------------------- VenusConnector.sol --------------------------- */

/// @dev Error emitted when the mint function fails.
error MintFailed();

/// @dev Error emitted when the redeem function fails.
error RedeemFailed();

/* --------------------------- MarketRegistry.sol --------------------------- */

/// @dev Error emitted when the market for a specific asset does not exist.
error InvalidAsset(address asset);

/// @dev Error emitted when an asset is already registered.
/// @param asset The address of the asset.
error AlreadyRegistered(address asset);

/* ----------------------- blockList.sol ----------------------- */

/// @dev Error emitted when the address removed is not blocked.
/// @param addr The address that was attempted to be removed.
error AddressNotBlocked(address addr);

/* ------------------------------ Multisend.sol ----------------------------- */

/// @dev Error emitted when the total split between the recipients is not 100%.
error WrongSplit(uint256 totalSplit);

/* ----------------------------- PauserProxy.sol ---------------------------- */

/// @dev Error emitted when an uint256 value overflows a uint88.
error Uint88Overflow(uint256 value);

/// @dev Error emitted when the caller is not the pauser.
error PauserUnauthorizedAccount(address account);