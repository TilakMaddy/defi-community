// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

string constant TOKEN_NAME = "Iltmuelc";
string constant SYMBOL = "ILTMUELC";
uint256 constant TOTAL_SUPPLY = 1e9 * (10 ** 18);

contract MyToken is ERC20 {
    constructor() ERC20(TOKEN_NAME, SYMBOL) {
        _mint(msg.sender, TOTAL_SUPPLY);
    }
}

/* Unit Tests */

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract MyTokenTests is Test {
    MyToken token;
    address deployer;

    function setUp() public {
        deployer = makeAddr("TOKEN_DEPLOYER");

        vm.prank(deployer);
        token = new MyToken();
    }

    function test_deployerGetsMintedInitialSupply() public view {
        assertEq(token.balanceOf(deployer), TOTAL_SUPPLY);
    }

    function test_tokenDecimals() public view {
        assertEq(token.decimals(), 18);
    }
}
