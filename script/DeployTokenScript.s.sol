// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../contracts/Helper.sol";
import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import {mATV2} from "../contracts/mATV2.sol";

contract DeployTokenScript is HelperScript {
    
        function run() public {
            vm.startBroadcast();

            beaconToken();

            token.configureMinter(msg.sender, 1 ether);
            token.mint(msg.sender, 1 ether);

            Upgrades.upgradeBeacon(proxy, "mATV2.sol", msg.sender);
            address implAddressV2 = IBeacon(proxy).implementation();

            mATV2 tokenV2 = mATV2(payable(implAddressV2));
            tokenV2.mint(msg.sender, 1 ether);

            vm.stopBroadcast();
        }
}