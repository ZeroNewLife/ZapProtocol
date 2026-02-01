//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import {Script} from "forge-std/Script.sol";
import {IntentExecutor} from "../src/IntentExecutor.sol";
import {console} from "forge-std/console.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();

        IntentExecutor executor = new IntentExecutor();

        console.log("IntentExecutor deployed at:", address(executor));

        vm.stopBroadcast();
    }
}
