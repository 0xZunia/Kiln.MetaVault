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

import {AccessControlDefaultAdminRulesUpgradeable} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlDefaultAdminRulesUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {ISanctionsList} from "./interfaces/ISanctionsList.sol";
import {NotDelegateCall, AddressNotContract, AddressNotBlocked} from "./libraries/Errors.sol";

/// @title Kiln DeFi Integration blocklist.
/// @notice Blocklist to prevent a set of users to interact with the vaults.
/// @author isma @ Kiln.
contract BlockList is AccessControlDefaultAdminRulesUpgradeable {
    /* -------------------------------------------------------------------------- */
    /*                                  CONSTANTS                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice The role code for the operator.
    bytes32 public constant OPERATOR_ROLE = bytes32("OPERATOR");

    /* -------------------------------------------------------------------------- */
    /*                                  IMMUTABLE                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev The address of the implementation (regardless of the context).
    address internal immutable _self = address(this);

    /* -------------------------------------------------------------------------- */
    /*                               STORAGE (proxy)                              */
    /* -------------------------------------------------------------------------- */

    /// @notice The storage layout of the contract.
    /// @param _underlyingSanctionsList The sanctions list contract from Chainalysis.
    /// @param _blockList The blocklist.
    /// @param _name The name of the blocklist.
    struct BlockListStorage {
        ISanctionsList _underlyingSanctionsList;
        mapping(address => bool) _blockList;
        string _name;
    }

    function _getBlockListStorage() private pure returns (BlockListStorage storage $) {
        assembly {
            $.slot := BlockListStorageLocation
        }
    }

    /// @dev The storage slot of the BlockListStorage struct in the proxy contract.
    ///      keccak256(abi.encode(uint256(keccak256("kiln.storage.blockList")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant BlockListStorageLocation =
        0x95688183686c3ec8efadb488883ac1d27f5a2b91d991ab031b02fd896646bd00;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    /// @dev Emitted when the sanctions list is initialized.
    /// @param underlyingSanctionsList The underlying sanctions list.
    event UnderlyingSanctionListInitialized(ISanctionsList underlyingSanctionsList);

    /// @dev Emitted when the underlying sanctions list is updated.
    /// @param newUnderlyingSanctionsList The new underlying sanctions list.
    event UnderlyingSanctionsListUpdated(ISanctionsList newUnderlyingSanctionsList);

    /// @dev Emitted when the name is initialized.
    /// @param name The name of the blocklist.
    event NameInitialized(string name);

    /// @dev Emitted when addresses are added to the blocklist.
    /// @param addrs The addresses added.
    event AddedToBlockList(address addrs);

    /// @dev Emitted when addresses are removed from the blocklist.
    /// @param addrs The addresses removed.
    event RemovedFromBlockList(address addrs);

    /* -------------------------------------------------------------------------- */
    /*                                  MODIFIERS                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Throws if the call is not a delegate call.
    ///      Allow to check if the contract is called from a proxy.
    modifier onlyDelegateCall() {
        if (address(this) == _self) revert NotDelegateCall();
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 PROXY LOGIC                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Parameters for the `initialize()` function.
    struct InitializationParams {
        string name_;
        ISanctionsList underlyingSanctionsList_;
        address initialDefaultAdmin_;
        address initialOperator_;
        uint48 initialDelay_;
    }

    /// @notice Initializes the contract in the proxy context.
    /// @param params The initialization parameters.
    function initialize(InitializationParams calldata params) public onlyDelegateCall initializer {
        __AccessControlDefaultAdminRules_init(params.initialDelay_, params.initialDefaultAdmin_);
        __BlockList_init(params);
    }

    function __BlockList_init(InitializationParams memory params) internal {
        _setUnderlyingSanctionsList(params.underlyingSanctionsList_);
        _setName(params.name_);
        _grantRole(OPERATOR_ROLE, params.initialOperator_);
    }

    /* -------------------------------------------------------------------------- */
    /*                  (PUBLIC) MANAGEMENT OF INTERNAL BLOCKLIST                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Add addresses to the blocklist.
    /// @param addrs The addresses to add.
    function addToBlockList(address[] calldata addrs) public onlyRole(OPERATOR_ROLE) {
        BlockListStorage storage $ = _getBlockListStorage();
        for (uint256 i = 0; i < addrs.length; i++) {
            $._blockList[addrs[i]] = true;
            emit AddedToBlockList(addrs[i]);
        }
    }

    /// @notice Remove addresses from the blocklist.
    /// @param addrs The addresses to remove.
    function removeFromBlockList(address[] calldata addrs) public onlyRole(OPERATOR_ROLE) {
        BlockListStorage storage $ = _getBlockListStorage();
        uint256 length = addrs.length;
        for (uint256 i = 0; i < length; i++) {
            address addr = addrs[i];
            if ($._blockList[addr] != true) {
                revert AddressNotBlocked(addr);
            }
            $._blockList[addr] = false;
            emit RemovedFromBlockList(addr);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                    (PUBLIC) SANCTIONS LIST LOGIC                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Check if an address is blocked (internal + underlying lists).
    /// @param addr The address to check.
    /// @return True if the address is blocked, false otherwise.
    function isBlocked(address addr) public view returns (bool) {
        BlockListStorage storage $ = _getBlockListStorage();
        if (ISanctionsList($._underlyingSanctionsList).isSanctioned(addr)) {
            return true;
        }
        return $._blockList[addr];
    }

    /// @notice Check if an address is blocked by the internal list (sanctions list excluded).
    /// @param addr The address to check.
    /// @return True if the address is blocked by the internal list, false otherwise.
    function isBlockedByInternalList(address addr) public view returns (bool) {
        return _getBlockListStorage()._blockList[addr];
    }

    /// @notice Check if an address is sanctioned by the underlying list (internal blocklist excluded).
    /// @param addr The address to check.
    /// @return True if the address is sanctioned by underlying list, false otherwise.
    function isSanctionedByUnderlyingList(address addr) public view returns (bool) {
        return ISanctionsList(_getBlockListStorage()._underlyingSanctionsList).isSanctioned(addr);
    }

    /* -------------------------------------------------------------------------- */
    /*                              (PUBLIC) SETTERS                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Set the underlying sanctions list.
    /// @param newUnderlyingSanctionsList The new underlying sanctions list.
    function setUnderlyingSanctionsList(ISanctionsList newUnderlyingSanctionsList) external onlyRole(OPERATOR_ROLE) {
        _setUnderlyingSanctionsList(newUnderlyingSanctionsList);
    }

    /* -------------------------------------------------------------------------- */
    /*                             (INTERNAL) SETTERS                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Internal logic to set the name.
    /// @param newName The new blocklist name.
    function _setName(string memory newName) internal {
        BlockListStorage storage $ = _getBlockListStorage();
        $._name = newName;
        emit NameInitialized(newName);
    }

    /// @notice Internal logic to set the underlying sanctions list.
    /// @param newUnderlyingSanctionsList The new underlying sanctions list.
    function _setUnderlyingSanctionsList(ISanctionsList newUnderlyingSanctionsList) internal {
        BlockListStorage storage $ = _getBlockListStorage();
        if (address(newUnderlyingSanctionsList).code.length == 0) {
            revert AddressNotContract(address(newUnderlyingSanctionsList));
        }
        $._underlyingSanctionsList = newUnderlyingSanctionsList;
        emit UnderlyingSanctionsListUpdated(newUnderlyingSanctionsList);
    }

    /* -------------------------------------------------------------------------- */
    /*                                    GETTERS                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Returns the name of the blocklist.
    /// @return The name of the blocklist.
    function name() public view returns (string memory) {
        return _getBlockListStorage()._name;
    }

    /// @notice Returns the underlying sanctions list.
    /// @return The underlying sanctions list.
    function underlyingSanctionsList() public view returns (ISanctionsList) {
        return _getBlockListStorage()._underlyingSanctionsList;
    }
}