// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./MetaVaultBeacon.sol";

contract MetaVaultFactory is Ownable {
    address public immutable beacon;
    mapping(address => address) public userVaults;

    event MetaVaultCreated(address indexed user, address vaultAddress);
    event VaultInitialized(address indexed vault, address[] initialVaults);

    constructor(address _beacon) Ownable(msg.sender) {
        require(_beacon != address(0), "Invalid beacon address");
        beacon = _beacon;
    }

    function createMetaVault(address[] calldata _initialVaults) external returns (address) {
        require(userVaults[msg.sender] == address(0), "User already has a vault");
        require(_initialVaults.length > 0, "No initial vaults provided");

        // Créer le proxy avec le beacon
        bytes memory data = ""; // Pas de données d'initialisation nécessaires
        BeaconProxy newVaultProxy = new BeaconProxy(
            beacon,
            data
        );

        address vaultAddress = address(newVaultProxy);
        userVaults[msg.sender] = vaultAddress;

        // Ajouter les vaults initiaux
        for(uint256 i = 0; i < _initialVaults.length; i++) {
            require(_initialVaults[i] != address(0), "Invalid vault address");
            // Appeler la fonction addVault du MetaVault
            (bool success,) = vaultAddress.call(
                abi.encodeWithSignature("addVault(uint256,address)", i, _initialVaults[i])
            );
            require(success, "Failed to add initial vault");
        }

        // Transférer la propriété du vault à l'utilisateur
        (bool success,) = vaultAddress.call(
            abi.encodeWithSignature("transferOwnership(address)", msg.sender)
        );
        require(success, "Failed to transfer ownership");

        emit MetaVaultCreated(msg.sender, vaultAddress);
        emit VaultInitialized(vaultAddress, _initialVaults);

        return vaultAddress;
    }

    function hasMetaVault(address user) external view returns (bool) {
        return userVaults[user] != address(0);
    }

    function getUserMetaVault(address user) external view returns (address) {
        return userVaults[user];
    }
}