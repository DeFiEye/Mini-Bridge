// SPDX-License-Identifier: MIT
// 0x5fd79a19De6c46Be1dcea8B5410e7F9e7CeaC192
pragma solidity 0.8.19;

// https://minibridge.chaineye.tools/btc
// Merlin BTC Bridge To BSC, users will receive mmBTC (MiniBridge Merlin BTC) token
// And users can use UniSwap V3 to swap to BTCB (BTC token on BSC, issued by Binance)

import "@openzeppelin/contracts@v4.9.3/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@v4.9.3/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts@v4.9.3/token/ERC20/extensions/ERC20Pausable.sol";

interface ISwapper{
    function swapAfterMint(address user, uint256 fromAmount, uint256 minOut) external returns(uint256 outAmount);
    function swapAndBridgeBack(uint256 amount, uint256 minOut, address to) external returns(uint256 outAmount);
}
interface IMiniBridge_Merlin_BTC is IERC20{
    function bridgeBackTo(address to, uint256 amount) external;
}
struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 sqrtPriceLimitX96;
}
interface IRouter{
    function exactInputSingle(ExactInputSingleParams memory params)
        external
        payable
        returns (uint256 amountOut);
}
interface IPool {
    function initialize(uint160 sqrtPriceX96) external;
}
interface IFactory{
    function createPool(address tokenA, address tokenB, uint24 fee) external returns (IPool);
}

contract Swapper_BSC_UniV3_BTCB_V3 is ISwapper{
    IMiniBridge_Merlin_BTC public constant mmBTC = IMiniBridge_Merlin_BTC(0xdCD1AeB176ECd6f8d4A3258413705651eb226e5E);
    IERC20 constant BTCB = IERC20(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c);
    IRouter constant Router = IRouter(0xB971eF87ede563556b2ED4b1C0b0019111Dd85d2);
    IFactory constant Factory = IFactory(0xdB1d10011AD0Ff90774D0C6Bb92e5C5c8b4461F7);
    uint256 constant MAX = type(uint256).max;
    address constant owner = 0x84F0Aa29864FfD6490FC98d1E2Dfa31A94569Cbc; //multi-sig
    constructor(){
        mmBTC.approve(address(Router), MAX);
        BTCB.approve(address(Router), MAX);
    }
    event SwapFail(address user, uint256 fromamount, uint256 minOut, uint256 timestamp, string reason);
    function swapAfterMint(address user, uint256 fromAmount, uint256 minOut) external returns(uint256 outAmount){
        require(msg.sender == address(mmBTC));
        //user bridge from Merlin, this Swapper will get minted mmBTC, swap to BTCB for user
        ExactInputSingleParams memory params = ExactInputSingleParams({
                tokenIn: address(mmBTC),
                tokenOut: address(BTCB),
                fee: 500,
                recipient: address(user),
                amountIn: fromAmount,
                amountOutMinimum: minOut,
                sqrtPriceLimitX96: 0
        });
        try Router.exactInputSingle(params) returns (uint swapOutAmount){
            return swapOutAmount;
        } catch Error(string memory reason) {
            emit SwapFail(user, fromAmount, minOut, block.timestamp, string(reason));
            mmBTC.transfer(user, fromAmount);
        } 
    }
    function swapAndBridgeBack(uint256 amount, uint256 minOut, address to) external returns(uint256 outAmount){
        //user approve BTCB to this contract, do the swap and then bridge to user
        BTCB.transferFrom(msg.sender, address(this), amount);
        ExactInputSingleParams memory params = ExactInputSingleParams({
                tokenIn: address(BTCB),
                tokenOut: address(mmBTC),
                fee: 500,
                recipient: address(this),
                amountIn: amount,
                amountOutMinimum: minOut,
                sqrtPriceLimitX96: 0
        });
        outAmount = Router.exactInputSingle(params);
        mmBTC.bridgeBackTo(to, outAmount);
    }
    function recoverFund(IERC20 token) external {
        uint256 bal = token.balanceOf(address(this));
        require(bal>0, "zero balance");
        token.transfer(owner, bal);
    }
}
