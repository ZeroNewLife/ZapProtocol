// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

contract IntentExecutor {
    using SafeERC20 for IERC20;

    struct Intent {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 minAmountOut;
        address recipient;
    }

    address public immutable router;
    address public immutable WETH;

    event IntentExecuted(
        address indexed caller,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address recipient
    );

    constructor(address _router, address _weth) {
        router = _router;
        WETH = _weth;
    }

    receive() external payable {}

    function executeIntent(Intent calldata intent) external payable returns (uint256 amountOut) {
        require(intent.amountIn > 0, "amountIn = 0");
        require(intent.recipient != address(0), "bad recipient");

        bool isETHIn = intent.tokenIn == address(0);
        bool isETHOut = intent.tokenOut == address(0);

        address tokenIn = isETHIn ? WETH : intent.tokenIn;
        address tokenOut = isETHOut ? WETH : intent.tokenOut;

        // 1️⃣ можем обратно забрать свои монетки
        if (isETHIn) {
            require(msg.value == intent.amountIn, "bad msg.value");
            IWETH(WETH).deposit{value: msg.value}();
        } else {
            IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), intent.amountIn);
        }

        // 2️⃣ тут происходит одобрение
        IERC20(tokenIn).approve(router, 0);
        IERC20(tokenIn).approve(router, intent.amountIn);

        // 3️⃣ swap
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: 3000, // Uniswap V3  0.3%
            recipient: isETHOut ? address(this) : intent.recipient,
            deadline: block.timestamp,
            amountIn: intent.amountIn,
            amountOutMinimum: intent.minAmountOut,
            sqrtPriceLimitX96: 0
        });

        amountOut = ISwapRouter(router).exactInputSingle(params);

        // 4️⃣ unwrap ETH если нужно для будущих взаимдействий
        if (isETHOut) {
            IWETH(WETH).withdraw(amountOut);
            (bool ok,) = intent.recipient.call{value: amountOut}("");
            require(ok, "ETH transfer failed");
        }

        emit IntentExecuted(msg.sender, intent.tokenIn, intent.tokenOut, intent.amountIn, amountOut, intent.recipient);
    }

    function getSwapRouter() external view returns (address) {
        return router;
    }

    function getConfig() external view returns (address _router, address _weth) {
        return (router, WETH);
    }
}

