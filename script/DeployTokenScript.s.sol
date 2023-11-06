// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../contracts/Helper.sol";
import {mATV2} from "../contracts/mATV2.sol";

contract DeployTokenScript is HelperScript {
    
        function run() public {
            vm.startBroadcast();

            deployToken();

            token.configureMinter(msg.sender, 1 ether);
            token.mint(msg.sender, 1 ether);

            //UPGRADE

            // Upgrades.upgradeProxy(
            // proxy,
            // "mATV2.sol",
            // ""
            // );

            // token.configureMinter(msg.sender, 1 ether);
            //this reverts as expected
            // token.mint(msg.sender, 1 ether);

            vm.stopBroadcast();
        }
}