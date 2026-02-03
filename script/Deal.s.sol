// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "forge-std/Test.sol";

contract Deal is Script, Test {
    function run() external {
        address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address recipient = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        
        // Deal tokens напрямую
        deal(usdc, recipient, 10000 * 1e6); // 10,000 USDC
        
        console.log("USDC balance:", IERC20(usdc).balanceOf(recipient) / 1e6, "USDC");
    }
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}
