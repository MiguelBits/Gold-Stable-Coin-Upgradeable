// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/Helper.sol";
import "../../contracts/mATV1.sol";

contract PauseTokenTest is HelperTest {

    address minter = address(2);

    function setUp() public {
        uint256 amount = 1 * 10 **__decimals;
        deployToken();
        configureMinter(minter, amount);
    }

    function testPause() public {
        uint256 amount = 1 * 10 **__decimals;

        vm.prank(_pauser);
        token.pause();

        vm.startPrank(minter);

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        token.mint(minter, amount);

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        token.transfer(minter, amount);

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        token.transferFrom(minter, minter, amount);

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        token.approve(minter, amount);

        vm.stopPrank();

        //assertTrue
        assertTrue(token.balanceOf(minter) == 0, "minter balance is not 0");
    }

    function testUnPause() public {
        uint256 amount = 1 * 10 **__decimals;

        vm.prank(_pauser);
        token.pause();

        vm.startPrank(minter);
        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        token.mint(minter, amount);
        vm.stopPrank();

        vm.prank(_pauser);
        token.unpause();

        vm.startPrank(minter);
        token.mint(minter, amount);
        vm.stopPrank();

        //assertTrue
        assertTrue(token.balanceOf(minter) == amount, "minter balance is not 0");
    }
}