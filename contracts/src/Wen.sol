// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Ownable, Ownable2Step} from "../lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {Pausable} from "../lib/openzeppelin-contracts/contracts/utils/Pausable.sol";
import "./Errors.sol";

import {MyToken} from "./Token.sol";

type Date is uint256;

struct WenGameGuess {
    uint256 date;
    uint256 month;
    uint256 year;
}

event Played(address indexed who);
event Claimed(address indexed who);
event Won();
event Draw();

contract WenGame is Ownable2Step, Pausable {
    Date public immutable i_startDate;
    Date public s_endDate;

    MyToken public s_token;
    string public s_gameName;
    bool public s_gameEnded;
    uint256 public s_participationFee;
    mapping(address => WenGameGuess) public s_guess;
    mapping(address => bool) public s_participated;
    mapping(address => bool) public s_paid;

    WenGameGuess public s_correctAns;
    address[] public s_participants;
    uint256 public s_individualReward;
    bool public s_thereIsAWinner;

    constructor(
        string memory gameName,
        MyToken token,
        uint256 participationFee
    ) Ownable(msg.sender) {
        s_gameName = gameName;
        s_token = token;
        s_participationFee = participationFee;
        i_startDate = Date.wrap(block.timestamp);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function play(WenGameGuess memory guess) external whenNotPaused {
        // Checks
        if (s_gameEnded) {
            revert Errors.IltmuelcGameEnded();
        }
        if (s_token.balanceOf(msg.sender) < s_participationFee) {
            revert Errors.IltmuelcInsufficientFunds();
        }
        if (s_participated[msg.sender]) {
            revert Errors.IltmuelcAlreadyParticipated();
        }

        // Effects
        s_participated[msg.sender] = true;
        s_participants.push(msg.sender);
        s_guess[msg.sender] = guess;

        emit Played(msg.sender);

        // Interactions
        s_token.transferFrom(msg.sender, address(this), s_participationFee);
    }

    function claim() external whenNotPaused {
        // Checks
        if (!s_gameEnded) {
            revert Errors.IltmuelcGameHasNotEnded();
        }
        if (!s_participated[msg.sender]) {
            revert Errors.IltmuelcNotParticipated();
        }
        if (s_paid[msg.sender]) {
            revert Errors.IltmuelcAlreadyPaid();
        }
        if (s_thereIsAWinner) {
            WenGameGuess memory result = s_correctAns;
            WenGameGuess memory g = s_guess[msg.sender];
            if (
                !(g.date == result.date &&
                    g.month == result.month &&
                    g.year == result.year)
            ) {
                revert Errors.IltmuelcNonWinnerClaim();
            }
        }
        // Effects
        s_paid[msg.sender] = true;
        emit Claimed(msg.sender);

        // Interaction
        s_token.transfer(msg.sender, s_individualReward);
    }

    function declareResultAndEndGame(
        WenGameGuess memory result
    ) public  whenPaused onlyOwner {
        // Checks
        if (s_gameEnded) {
            revert Errors.IltmuelcGameEnded();
        }

        // Effects
        s_correctAns = result;
        s_gameEnded = true;
        s_endDate = Date.wrap(block.timestamp);

        uint256 numCorrectAns = 0;
        uint256 numParticipants = s_participants.length;
        for (uint256 i = 0; i < numParticipants; ++i) {
            WenGameGuess memory g = s_guess[s_participants[i]];
            if (
                g.date == result.date &&
                g.month == result.month &&
                g.year == result.year
            ) {
                numCorrectAns += 1;
            }
        }
        uint256 totalAvailableRewards = s_token.balanceOf(address(this));
        uint256 totalMoneyToDistribute = 0;

        // If no one answered correctly then refund everyone's ILTMUELC, otherwise split the prize pool
        // amongst winners
        if (numCorrectAns > 0) {
            s_thereIsAWinner = true;
            s_individualReward = totalAvailableRewards / numCorrectAns;
            totalMoneyToDistribute = s_individualReward * numCorrectAns;
            emit Won();
        } else {
            s_individualReward = totalAvailableRewards / numParticipants;
            totalMoneyToDistribute = s_individualReward * numParticipants;
            emit Draw();
        }

        assert(s_individualReward >= s_participationFee);

        // Interactions
        uint256 remaining = totalAvailableRewards - totalMoneyToDistribute;
        s_token.transfer(owner(), remaining);
    }
}

/* Unit Tests */
import {Test} from "forge-std/Test.sol";

contract WenGameTest is Test {
    MyToken token;
    WenGame wen;
    address deployer;

    address player1;
    address player2;
    address player3;

    uint256 constant FEE = 100 * 1e18; // participation fee
    WenGameGuess public CORRECT_ANS = WenGameGuess(20, 8, 2024);

    function setUp() public {
        deployer = makeAddr("DEPLOYER");
        player1 = makeAddr("PLAYER_1");
        player2 = makeAddr("PLAYER_2");
        player3 = makeAddr("PLAYER_3");

        vm.startPrank(deployer);
        token = new MyToken();
        wen = new WenGame("Dria Swan", token, FEE);

        token.transfer(player1, FEE * 2);
        token.transfer(player2, FEE * 2);
        token.transfer(player3, FEE * 2);
        vm.stopPrank();
    }

    function test_InitialConditionsAreMet() public view {
        // Check players have enough balance to play twice althuogh they should only be allowed to play once
        assertEq(token.balanceOf(player1), FEE * 2);
        assertEq(token.balanceOf(player2), FEE * 2);
        assertEq(token.balanceOf(player3), FEE * 2);
        assertEq(token.balanceOf(address(wen)), 0);

        // Check contract's variables
        assert(!wen.s_gameEnded());
    }

    function test_player_can_participate_and_win() public {
        // Player 1 participates and their balance decreases
        vm.prank(player1);
        token.approve(address(wen), FEE);

        vm.prank(player1);
        wen.play(CORRECT_ANS);

        assertEq(token.balanceOf(player1), FEE);

        // Player 2 participates and their balance decreases
        vm.prank(player2);
        token.approve(address(wen), FEE);

        vm.prank(player2);
        wen.play(CORRECT_ANS);

        assertEq(token.balanceOf(player2), FEE);

        // Player 3 participates and their balance decreases
        WenGameGuess memory wrongAns = WenGameGuess(2025, 8, 2);
        vm.prank(player3);
        token.approve(address(wen), FEE);

        vm.prank(player3);
        wen.play(wrongAns);

        assertEq(token.balanceOf(player3), FEE);

        // Corrected answer is declared and game ends
        assertEq(token.balanceOf(address(wen)), 3 * FEE);

        vm.startPrank(deployer);
        wen.pause();
        wen.declareResultAndEndGame(CORRECT_ANS);
        wen.unpause();
        vm.stopPrank();

        assert(wen.s_thereIsAWinner());
        assertEq(token.balanceOf(address(wen)), 3 * FEE);
        assertEq(wen.s_individualReward(), ((3 * FEE) / 2));

        // Player 1 and Player 2 gave the right answer so they claim their rewards
        vm.prank(player1);
        wen.claim();

        assertEq(token.balanceOf(player1), FEE + wen.s_individualReward());

        // Player 3 cannot claim
        vm.expectRevert();
        vm.prank(player3);
        wen.claim();
    }

    function test_player_can_participate_and_noone_wins() public {
        WenGameGuess memory wrongAns = WenGameGuess(2025, 8, 2);

        // Player 1 participates and their balance decreases
        vm.prank(player1);
        token.approve(address(wen), FEE);

        vm.prank(player1);
        wen.play(wrongAns);

        assertEq(token.balanceOf(player1), FEE);

        // Player 2 participates and their balance decreases
        vm.prank(player2);
        token.approve(address(wen), FEE);

        vm.prank(player2);
        wen.play(wrongAns);

        assertEq(token.balanceOf(player2), FEE);

        // Player 3 participates and their balance decreases
        vm.prank(player3);
        token.approve(address(wen), FEE);

        vm.prank(player3);
        wen.play(wrongAns);

        assertEq(token.balanceOf(player3), FEE);

        // Corrected answer is declared and game ends
        assertEq(token.balanceOf(address(wen)), 3 * FEE);

      
        vm.startPrank(deployer);
        wen.pause();
        wen.declareResultAndEndGame(CORRECT_ANS);
        wen.unpause();
        vm.stopPrank();

        assert(!wen.s_thereIsAWinner());
        assertEq(token.balanceOf(address(wen)), 3 * FEE);
        assertEq(wen.s_individualReward(), FEE);

        // All players can claim refund
        vm.prank(player1);
        wen.claim();

        vm.prank(player2);
        wen.claim();

        vm.prank(player3);
        wen.claim();

        assertEq(token.balanceOf(player1), FEE + wen.s_individualReward());
        assertEq(token.balanceOf(player2), FEE + wen.s_individualReward());
        assertEq(token.balanceOf(player3), FEE + wen.s_individualReward());
    }

    function test_player_can_participate_and_noone_wins_with_donation() public {
        WenGameGuess memory wrongAns = WenGameGuess(2025, 8, 2);

        // Player 1 participates and their balance decreases
        vm.prank(player1);
        token.approve(address(wen), FEE);

        vm.prank(player1);
        wen.play(wrongAns);

        assertEq(token.balanceOf(player1), FEE);

        // I dontate twice the fee amount to Wen contract
        vm.prank(deployer);
        token.transfer(address(wen), 2 * FEE);

        // Corrected answer is declared and game ends
        assertEq(token.balanceOf(address(wen)), 3 * FEE);

        vm.startPrank(deployer);
        wen.pause();
        wen.declareResultAndEndGame(CORRECT_ANS);
        wen.unpause();
        vm.stopPrank();

        assert(!wen.s_thereIsAWinner());
        assertEq(token.balanceOf(address(wen)), 3 * FEE);
        assertEq(wen.s_individualReward(), 3 * FEE);

        // All players can claim refund
        vm.prank(player1);
        wen.claim();

        // Finally player sees an increase of 3 * FEE after round ends
        assertEq(token.balanceOf(player1), FEE + 3 * FEE);
    }

    function test_player_cannot_participate_twice() public {
        WenGameGuess memory wrongAns = WenGameGuess(2025, 8, 2);

        // Player 1 participates and their balance decreases
        vm.prank(player1);
        token.approve(address(wen), 2 * FEE);

        vm.prank(player1);
        wen.play(wrongAns);

        assertEq(token.balanceOf(player1), FEE);

        vm.expectRevert();
        vm.prank(player1);
        wen.play(wrongAns);
    }
}
