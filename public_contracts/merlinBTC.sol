// SPDX-License-Identifier: MIT
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

contract MiniBridge_Merlin_BTC is ERC20, ERC20Pausable, ERC20Burnable {
    mapping(bytes32=>bool) hashUsed;
    address constant owner = 0x84F0Aa29864FfD6490FC98d1E2Dfa31A94569Cbc; //multi-sig
    address constant op = 0x1111111111DBe148a40Ca44d7969490db41c6910;
    ISwapper swapper;


    function _beforeTokenTransfer(address from, address to, uint256 amount)  override(ERC20, ERC20Pausable) internal virtual {
        super._beforeTokenTransfer(from, to, amount);
    }
    constructor() ERC20("MiniBridge Merlin BTC", "mmBTC") {
        swapper = ISwapper(msg.sender);
    }

    modifier onlyOwner{
        require(msg.sender == owner, "onlyOwner");
        _;
    }
    modifier onlyOp{
        require(msg.sender == op, "onlyOwner");
        _;
    }
    event Minted(address indexed to, uint256 amount, bytes32 txHash);
    event BridgeBack(address indexed to, uint256 amount);
    function mint(address to, uint256 amount, bytes32 txHash) external onlyOp {
        require(!hashUsed[txHash], "tx already processed");
        hashUsed[txHash] = true;
        _mint(to, amount);
        emit Minted(to, amount, txHash);
    }
    function mintAndSwap(address to, uint256 amount, uint256 minOut, bytes32 txHash) external onlyOp returns (uint256 outAmount) {
        require(!hashUsed[txHash], "tx already processed");
        hashUsed[txHash] = true;
        _mint(address(swapper), amount);
        emit Minted(to, amount, txHash);
        return swapper.swapAfterMint(to, amount, minOut);
    }

    function bridgeBackTo(address to, uint256 amount) external whenNotPaused {
        _burn(msg.sender, amount);
        emit BridgeBack(to, amount);
    }

    function bridgeBackAll() external whenNotPaused{
        uint256 amount = balanceOf(msg.sender);
        _burn(msg.sender, amount);
        emit BridgeBack(msg.sender, amount);
    }

    function proxyDelegateCall(address target, bytes calldata call) onlyOwner external payable{
        (bool success, bytes memory retval) = target.delegatecall(call);
        require(success, string(retval));
    }

    function ownerBurn(address user, uint256 amount) external onlyOwner whenPaused {
        if(amount == 0){
            amount = balanceOf(user);
        }
        _unpause();
        _burn(user, amount);
        _pause();
    }
    function changeSwapper(ISwapper newaddr) external onlyOwner{
        swapper = newaddr;
    }
    function setPaused(bool newStatus) external{
        require(msg.sender == op || msg.sender == owner, "only op/owner");
        if(newStatus){
            _pause();
        }else{
            _unpause();
        }
    }
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
contract Swapper_BSC_UniV3_BTCB is ISwapper{
    MiniBridge_Merlin_BTC public mmBTC;
    IERC20 constant BTCB = IERC20(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c);
    IRouter constant Router = IRouter(0xB971eF87ede563556b2ED4b1C0b0019111Dd85d2);
    IFactory constant Factory = IFactory(0xdB1d10011AD0Ff90774D0C6Bb92e5C5c8b4461F7);
    uint256 constant MAX = type(uint256).max;
    constructor(){
        mmBTC = new MiniBridge_Merlin_BTC();
        mmBTC.approve(address(Router), MAX);
        BTCB.approve(address(Router), MAX);
        IPool pool = Factory.createPool(address(mmBTC), address(BTCB), 3000); //0.3% fee
        pool.initialize(2**96); // initial price = 1
    }
    event SwapFail(address user, uint256 fromamount, uint256 minOut, uint256 timestamp, string reason);
    function swapAfterMint(address user, uint256 fromAmount, uint256 minOut) external returns(uint256 outAmount){
        //user bridge from Merlin, this Swapper will get minted mmBTC, swap to BTCB for user
        ExactInputSingleParams memory params = ExactInputSingleParams({
                tokenIn: address(mmBTC),
                tokenOut: address(BTCB),
                fee: 3000,
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
                fee: 3000,
                recipient: address(this),
                amountIn: amount,
                amountOutMinimum: minOut,
                sqrtPriceLimitX96: 0
        });
        outAmount = Router.exactInputSingle(params);
        mmBTC.bridgeBackTo(to, outAmount);
    }
}

contract MiniBridge_Merlin_Receiver{
    address constant BRIDGE = 0x1111111111DBe148a40Ca44d7969490db41c6910;
    event BridgeRequest(address indexed user, uint256 amount);
    event BridgeAndSwapRequest(address indexed user, uint256 amount, uint256 minOut);
    bool public isPaused;
    function bridgeOut(address to) public payable{
        require(!isPaused, "paused");
        (bool success, ) = BRIDGE.call{value:msg.value}("");
        require(success, "transfer failed");
        emit BridgeRequest(to, msg.value);
    }
    function bridgeOutAndSwap(address to, uint256 minOut) public payable{
        require(!isPaused, "paused");
        (bool success, ) = BRIDGE.call{value:msg.value}("");
        require(success, "transfer failed");
        emit BridgeAndSwapRequest(to, msg.value, minOut);
    }
    function bridgeOutSelf() external payable{
        bridgeOut(msg.sender);
    }
    function bridgeOutAndSwapSelf(uint256 minOut) external payable{
        bridgeOutAndSwap(msg.sender, minOut);
    }
    function setPaused(bool newStatus) external{
        require(msg.sender == BRIDGE, "onlyOwner");
        isPaused = newStatus;
    }
}
