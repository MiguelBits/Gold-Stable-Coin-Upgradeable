// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/Script.sol";

import "../contracts/mATV1.sol";
import {Upgrades} from "@openzeppelin-foundry-upgrades/Upgrades.sol";

abstract contract Helper {
    mATV1 public token;
    string _name = "mAT";
    string _symbol = "mAT";
    string _currency = "GOLD";
    uint8 __decimals = 18;
    address _masterMinter = address(1);
    address _blacklister = address(1);
    address _owner = address(1);

    address proxy;

    // @returns proxy address
    function deployToken() public {
        //Upgrades proxy
        proxy = Upgrades.deployUUPSProxy(
            "mATV1.sol",
            abi.encodeCall(mATV1.initialize, (_name, _symbol, _currency, __decimals, _masterMinter, _blacklister, _owner))
        );

        token = mATV1(payable(proxy));

        console.log("token address: %s", address(token));

        _assertDeployment();
    }

    function upgradeContract() public {
        Upgrades.upgradeProxy(
            proxy,
            "mATV2.sol",
            ""
        );
    }

    function _assertDeployment() internal virtual {
        //OTDO
    }
}


contract HelperScript is Helper, Script {

    function _assertDeployment() internal override {
        //assert name symbol currency owner and totalSupply
        require(keccak256(bytes(token.name())) == keccak256(bytes(_name)), "name is not equal");
        require(keccak256(bytes(token.symbol())) == keccak256(bytes(_symbol)), "symbol is not equal");
        require(keccak256(bytes(token.currency())) == keccak256(bytes(_currency)), "currency is not equal");
        require(token.owner() == _owner, "owner is not equal");
        require(token.totalSupply() == 0, "totalSupply is not equal");
    }

}


contract HelperTest is Helper, Test {

    function _assertDeployment() internal override {
        //assert name symbol currency owner and totalSupply
        assertTrue(keccak256(bytes(token.name())) == keccak256(bytes(_name)), "name is not equal");
        assertTrue(keccak256(bytes(token.symbol())) == keccak256(bytes(_symbol)), "symbol is not equal");
        assertTrue(keccak256(bytes(token.currency())) == keccak256(bytes(_currency)), "currency is not equal");
        assertTrue(token.owner() == _owner, "owner is not equal");
        assertTrue(token.totalSupply() == 0, "totalSupply is not equal");
    }

    function configureMinter(address minter, uint256 minterAllowedAmount) public {
        vm.prank(_masterMinter);
        token.configureMinter(minter, minterAllowedAmount);

        assertTrue(token.minterAllowance(minter) == minterAllowedAmount, "minterAllowance is not equal");
        assertTrue(token.isMinter(minter), "isMinter is not equal");
    }

    function removeMinter(address minter) public {
        vm.prank(_masterMinter);
        token.removeMinter(minter);

        assertTrue(token.minterAllowance(minter) == 0, "minterAllowance is not equal");
        assertTrue(!token.isMinter(minter), "isMinter is not equal");
    }
}