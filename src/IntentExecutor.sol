//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract IntentExecutor {
    using SafeERC20 for IERC20;

    event Executed(
        address indexed user, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut
    );

    /**
     * @notice Executes swap / bridge calldata built offchain (LI.FI)
     */
    function execute(
        address user,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address target,
        bytes calldata data
    ) external payable {
        // pull tokens
        IERC20(tokenIn).safeTransferFrom(user, address(this), amountIn);

        // approve execution target
        IERC20(tokenIn).approve(target, 0);
        IERC20(tokenIn).approve(target, amountIn);

        uint256 beforeBal = IERC20(tokenOut).balanceOf(address(this));

        // execute calldata (LI.FI / Uniswap)
        (bool ok,) = target.call{value: msg.value}(data);
        require(ok, "execution failed");

        uint256 afterBal = IERC20(tokenOut).balanceOf(address(this));
        uint256 amountOut = afterBal - beforeBal;

        require(amountOut >= minAmountOut, "slippage");

        IERC20(tokenOut).safeTransfer(user, amountOut);

        emit Executed(user, tokenIn, tokenOut, amountIn, amountOut);
    }
}

