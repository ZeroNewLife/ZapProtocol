// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/IntentExecutor.sol";

contract IntentExecutorTest is Test {
    IntentExecutor executor;

    function setUp() public {
        executor = new IntentExecutor();
    }

    function testDeploy() public view {
        assert(address(executor) != address(0));
    }
}
