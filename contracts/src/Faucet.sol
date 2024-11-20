// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {MyToken} from "./Token.sol";
import {Pausable} from "../lib/openzeppelin-contracts/contracts/utils/Pausable.sol";
import {Ownable, Ownable2Step} from "../lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";

import "./Errors.sol";

type LastMintedTime is uint256;

contract Faucet is Ownable2Step, Pausable {
    MyToken immutable i_token;

    uint256 public s_mintInterval;
    uint256 public s_mintAmount;
    mapping(address => LastMintedTime) public s_lastMintedTime;

    constructor(
        MyToken token,
        uint256 mintInterval,
        uint256 mintAmount
    ) Ownable(msg.sender) {
        i_token = token;
        s_mintInterval = mintInterval;
        s_mintAmount = mintAmount;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setMintInterval(uint256 mintInterval) public whenPaused {
        s_mintInterval = mintInterval;
    }

    function setMintAmount(uint256 mintAmount) public whenPaused {
        s_mintAmount = mintAmount;
    }

    function mint() external whenNotPaused {
        LastMintedTime lastMintedTime = s_lastMintedTime[msg.sender];

        // Checks
        if (
            block.timestamp <
            LastMintedTime.unwrap(lastMintedTime) + s_mintInterval
        ) {
            revert Errors.IltmuelcMintIntervalNotMet();
        }

        // Effects
        s_lastMintedTime[msg.sender] = LastMintedTime.wrap(block.timestamp);

        // Interaction
        i_token.transfer(msg.sender, s_mintAmount);
    }

    function withdrawRemainingFunds() external whenPaused onlyOwner {
        i_token.transfer(owner(), i_token.balanceOf(address(this)));
    }
}

/* Unit tests */
import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

/// @dev Each day a user can freely mint 1000 tokens
uint256 constant MINT_INTERVAL = 1 days;
uint256 constant MINT_AMOUNT = 1000 * 1e18;

contract FaucetTest is Test {
    MyToken token;
    Faucet faucet;
    address deployer;

    address minter1;
    address minter2;

    function setUp() public {
        deployer = makeAddr("TOKEN_DEPLOYER");
        minter1 = makeAddr("MINTER_1");
        minter2 = makeAddr("MINTER_2");

        vm.startPrank(deployer);
        token = new MyToken();
        faucet = new Faucet(token, MINT_INTERVAL, MINT_AMOUNT);
        token.transfer(address(faucet), MINT_AMOUNT * 10);
        vm.stopPrank();

        vm.roll(100);
        vm.warp(1000 days);
        vm.roll(100);
    }

    function test_faucetMeetsInitialConditions() public view {
        assert(!faucet.paused());
        assertEq(token.balanceOf(address(faucet)), MINT_AMOUNT * 10);
        assertEq(faucet.owner(), deployer);
    }

    function test_canTransferOwnershipSuccessfully() public {
        assertEq(faucet.owner(), deployer);
        address newOwner = makeAddr("NEW_OWNER");

        vm.prank(deployer);
        faucet.transferOwnership(newOwner);

        assertEq(faucet.owner(), deployer);
        assertEq(faucet.pendingOwner(), newOwner);

        vm.prank(newOwner);
        faucet.acceptOwnership();

        assertEq(faucet.owner(), newOwner);
    }

    function test_minterCanMintIfMintIntervalIsRespected() public {
        assertEq(token.balanceOf(minter1), 0);

        vm.prank(minter1);
        faucet.mint();

        assertEq(token.balanceOf(minter1), MINT_AMOUNT);

        vm.warp(block.timestamp + MINT_INTERVAL);

        vm.prank(minter1);
        faucet.mint();

        assertEq(token.balanceOf(minter1), 2 * MINT_AMOUNT);
    }

    function test_minterCannotMintIfFaucetIsPaused() public {
        assertEq(token.balanceOf(minter1), 0);
        assertEq(faucet.owner(), address(deployer));

        vm.prank(deployer);
        faucet.pause();

        assert(faucet.paused());

        vm.expectRevert();
        vm.prank(minter1);
        faucet.mint();

        vm.prank(deployer);
        faucet.unpause();

        vm.prank(minter1);
        faucet.mint();

        assertEq(token.balanceOf(minter1), MINT_AMOUNT);
    }

    function test_minterCannotMintTooEarly() public {
        assertEq(token.balanceOf(minter1), 0);

        vm.prank(minter1);
        faucet.mint();

        assertEq(token.balanceOf(minter1), MINT_AMOUNT);

        // Only wait half the interval
        vm.warp(block.timestamp + (MINT_INTERVAL / 2));
        vm.roll(1);

        vm.expectRevert();
        vm.prank(minter1);
        faucet.mint();

        // Not changed
        assertEq(token.balanceOf(minter1), MINT_AMOUNT);
    }

    function test_deployerCanWithdrawRemainingFunds() public {
        vm.prank(deployer);
        faucet.pause();

        address randomPerson = makeAddr("RANDOM_PERSON");
        vm.expectRevert();
        vm.prank(randomPerson);
        faucet.withdrawRemainingFunds();

        vm.prank(deployer);
        faucet.withdrawRemainingFunds();

        vm.prank(deployer);
        faucet.unpause();
    }
}
