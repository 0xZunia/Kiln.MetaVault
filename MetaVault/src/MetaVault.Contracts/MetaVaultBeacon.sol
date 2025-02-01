// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MetaVaultBeacon is UpgradeableBeacon, Ownable {
    constructor(address implementation)
    UpgradeableBeacon(implementation)
    Ownable(msg.sender)
    {}

    function upgradeTo(address newImplementation) public override onlyOwner {
        super.upgradeTo(newImplementation);
    }
}