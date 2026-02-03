//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import {Script} from "forge-std/Script.sol";
import {IntentExecutor} from "../src/IntentExecutor.sol";
import {console} from "forge-std/console.sol";

contract DeployScript is Script {
    address swapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function run() external {
        vm.startBroadcast();

        IntentExecutor executor = new IntentExecutor(swapRouter, weth);

        console.log("IntentExecutor deployed at:", address(executor));

        vm.stopBroadcast();
    }
}
