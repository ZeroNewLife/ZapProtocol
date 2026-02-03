// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/IntentExecutor.sol";

contract IntentExecutorTest is Test {
    IntentExecutor executor;

    address constant UNISWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // USDC whale (mainnet)
    address constant USDC_WHALE = 0x55FE002aefF02F77364de339a1292923A15844B8;

    address user;

    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_RPC"));

        executor = new IntentExecutor(UNISWAP_ROUTER, WETH);

        user = address(0xABCD);

        // даём юзеру ETH для взаимодействия
        vm.deal(user, 10 ether);

        // забираем USDC у whale и начинаем взаимодействовать свободно
        vm.startPrank(USDC_WHALE);
        IERC20(USDC).approve(address(this), type(uint256).max);
        IERC20(USDC).approve(address(executor), type(uint256).max);
        vm.stopPrank();

        // переводим USDC юзеру
        vm.prank(USDC_WHALE);
        IERC20(USDC).transfer(user, 1_000_000_000); // 1000 USDC
    }

    function test_USDC_to_ETH_swap() public {
        uint256 amountIn = 1_000_000; // 1 USDC (6 decimals)

        vm.startPrank(user);

        // approve executor
        IERC20(USDC).approve(address(executor), amountIn);

        uint256 ethBefore = user.balance;

        IntentExecutor.Intent memory intent = IntentExecutor.Intent({
            tokenIn: USDC,
            tokenOut: address(0), // ETH
            amountIn: amountIn,
            minAmountOut: 0, // для теста оставим так  чтобы не завалить своп
            recipient: user
        });
        vm.expectEmit(true, true, true, false);

        emit IntentExecutor.IntentExecuted(
            user,
            USDC,
            address(0),
            amountIn,
            0, // amountOut проверим отдельно
            user
        );

        uint256 amountOut = executor.executeIntent(intent);

        uint256 ethAfter = user.balance;

        vm.stopPrank();

        // 🔎 АССЕРТЫ
        assertGt(amountOut, 0, "amountOut = 0");
        assertGt(ethAfter, ethBefore, "ETH not received");
    }

    function test_revert_if_minAmountOut_not_met() external {
        // подсовываешь заведомо высокий minAmountOut
        uint256 amountIn = 1_000_000; // 1 USDC (6 decimals)
        vm.startPrank(user);
        // approve executor
        IERC20(USDC).approve(address(executor), amountIn);
        IntentExecutor.Intent memory intent = IntentExecutor.Intent({
            tokenIn: USDC,
            tokenOut: address(0), // ETH
            amountIn: amountIn,
            minAmountOut: 10 ether, // нереально высокий минимум
            recipient: user
        });
        // ожидаешь revert
        vm.expectRevert();
        executor.executeIntent(intent);
    }
}
