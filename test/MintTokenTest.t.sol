// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/Helper.sol";
import "../../contracts/mATV1.sol";

contract MintTokenTest is HelperTest {

    address minter = address(2);

    function setUp() public {
        uint256 amount = 1 * 10 **__decimals;
        deployToken();
        configureMinter(minter, amount);
    }

    function testMint() public {
        uint256 amount = 1 * 10 **__decimals;

        vm.prank(minter);
        token.mint(minter, amount);

        //assertTrue
        assertTrue(token.balanceOf(minter) == amount);
        assertTrue(token.totalSupply() == amount);
    }

    function testBurn() public {
        uint256 amount = 1 * 10 **__decimals;

        vm.startPrank(minter);
        token.mint(minter, amount);
        token.burn(amount);
        vm.stopPrank();

        //assertTrue
        assertTrue(token.balanceOf(minter) == 0);
        assertTrue(token.totalSupply() == 0);
    }
}