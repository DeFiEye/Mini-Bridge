// SPDX-License-Identifier: MIT
// bsc 0xdCD1AeB176ECd6f8d4A3258413705651eb226e5E
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
