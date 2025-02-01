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

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

/// @title FeeDispatcher Interface.
/// @author maximebrugel @ Kiln.
interface IFeeDispatcher {
    /// @notice Entity eligible to receive a portion of fees.
    /// @param recipient The address of the fee recipient.
    /// @param depositFeeSplit The split percentage of the deposit fee allocated to this recipient.
    /// @param rewardFeeSplit The split percentage of the reward fee allocated to this recipient.
    struct FeeRecipient {
        address recipient;
        uint256 depositFeeSplit;
        uint256 rewardFeeSplit;
    }

    /// @notice Dispatch for every Vaults.
    /// @param _pendingDepositFee The pending deposit fee (to be dispatched).
    /// @param _pendingRewardFee The pending reward fee (to be dispatched).
    /// @param _feeRecipients Array of all the fee recipients.
    struct Dispatch {
        uint256 _pendingDepositFee;
        uint256 _pendingRewardFee;
        FeeRecipient[] _feeRecipients;
    }

    /// @notice Dispatch pending fees to the fee recipients.
    function dispatchFees(IERC20 asset, uint8 underlyingDecimals) external;

    /// @notice Get the pending deposit fee.
    /// @return The pending deposit fee.
    function pendingDepositFee() external view returns (uint256);

    /// @notice Get the pending reward fee.
    /// @return The pending reward fee.
    function pendingRewardFee() external view returns (uint256);

    /// @notice Get the fee recipients.
    /// @return The fee recipients.
    function feeRecipients() external view returns (FeeRecipient[] memory);

    /// @notice Get the fee recipient of a given address.
    /// @param recipient The address of the fee recipient.
    /// @return The fee recipient.
    function feeRecipient(address recipient) external view returns (FeeRecipient memory);

    /// @notice Get the fee recipient at a given index.
    /// @param index The index of the fee recipient.
    /// @return The fee recipient.
    function feeRecipientAt(uint256 index) external view returns (FeeRecipient memory);

    /// @notice Set the fee recipients.
    ///      The fee recipients must be unique and the total fee splits must be 100e18 (representing 100%).
    /// @param recipients The new fee recipients.
    /// @param underlyingDecimal The number of decimals of the underlying asset.
    function setFeeRecipients(IFeeDispatcher.FeeRecipient[] memory recipients, uint8 underlyingDecimal) external;

    /// @notice Increment the pending reward fee.
    /// @param amount The amount to increment the pending reward fee by.
    function incrementPendingRewardFee(uint256 amount) external;

    /// @notice Increment the pending deposit fee.
    /// @param amount The amount to increment the pending deposit fee by.
    function incrementPendingDepositFee(uint256 amount) external;
}