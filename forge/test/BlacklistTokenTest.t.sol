// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../Helper.sol";
import "../../contracts/mATV1.sol";

contract BlacklistTokenTest is HelperTest {

    address minter = address(2);

    function setUp() public {
        uint256 amount = 1 * 10 **__decimals;
        deployToken();
        configureMinter(minter, amount);
    }

    function testBlacklist() public {
        uint256 amount = 1 * 10 **__decimals;

        vm.prank(_blacklister);
        token.blacklist(minter);

        //assertTrue
        assertTrue(token.isBlacklisted(minter), "minter is not blacklisted");

        vm.startPrank(minter);

        vm.expectRevert("Blacklisted");
        token.mint(minter, amount);

        vm.expectRevert("Blacklisted");
        token.transfer(minter, amount);

        vm.expectRevert("Blacklisted");
        token.transferFrom(minter, minter, amount);

        vm.expectRevert("Blacklisted");
        token.approve(minter, amount);

        vm.stopPrank();

        //assertTrue
        assertTrue(token.balanceOf(minter) == 0, "minter balance is not 0");
    }

    function testUnBlackList() public {
        uint256 amount = 1 * 10 **__decimals;

        vm.prank(_blacklister);
        token.blacklist(minter);

        //assertTrue
        assertTrue(token.isBlacklisted(minter), "minter is not blacklisted");

        vm.prank(_blacklister);
        token.unBlacklist(minter);

        //assertFalse
        assertFalse(token.isBlacklisted(minter), "minter is blacklisted");

        vm.startPrank(minter);

        token.mint(minter, amount);

        vm.stopPrank();

        //assertTrue
        assertTrue(token.balanceOf(minter) == amount, "minter balance is not 0");
    }
}