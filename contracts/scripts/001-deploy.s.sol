// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {MyToken} from "../src/Token.sol";
import {WenGame} from "../src/Wen.sol";
import {Faucet} from "../src/Faucet.sol";

contract Deploy is Script {
    function run() public {
        vm.startBroadcast();

        // Deployer
        console.log("Deployer:", msg.sender);

        // Mints 1 billion tokens to me
        MyToken token = new MyToken();
        console.log("Token deployment:", address(token));

        uint256 totalTokens = token.balanceOf(msg.sender);
        console.log("Deployer rewarded:", totalTokens);

        // Faucet allows users to mint MINT_AMOUNT every MINT_INTERVAL
        uint256 MINT_INTERVAL = 1 days;
        uint256 MINT_AMOUNT = 200 * 1e18;
        Faucet faucet = new Faucet(token, MINT_INTERVAL, MINT_AMOUNT);
        console.log("Faucet deployment:", address(faucet));

        // Transfer 20_000 tokens to the faucet
        token.transfer(address(faucet), MINT_AMOUNT * 100);
        console.log("Facuet rewarded: 20000 $ILTMUELC tokens");

        // Every day you will have 200 tokens to play games with.
        uint256 PARTICIPATION_FEE = 100 * 1e18;
        WenGame wen = new WenGame("Dria Swan", token, PARTICIPATION_FEE);
        console.log("Wen deployment:", address(wen));

        // Donate some tokens for the first game to be added to the pot!
        token.transfer(address(wen), 150 * 1e18);
        console.log("Donating 150 $ILTMUELC to first game on Wen");

        vm.stopBroadcast();
    }
}
