// SPDX-License-Identifier: MIT
// https://minibridge.chaineye.tools

// this contract is used by bridge EOA to support sending both ETH (ERC20) and native token to user

pragma solidity 0.8.19;
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
    function approve(address spender, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
}
contract MiniBridge_GasRefill_opBNB{
    address payable constant BRIDGE = payable(0x00000000000007736e2F9aA5630B8c812E1F3fc9);
    IERC20 constant WETH = IERC20(0xE7798f023fC62146e8Aa1b36Da45fb70855a77Ea);
    function transfer(address payable to, uint256 amount) external payable {
        require(msg.sender == BRIDGE, "!bridge");
        WETH.transferFrom(BRIDGE, to, amount);
        (bool success, bytes memory err) = to.call{value:msg.value}("");
        require(success, string(err));
    }
    function proxyCall(address target, bytes calldata call) external {
        require(msg.sender == BRIDGE, "!bridge");
        (bool success, bytes memory retval) = target.call(call);
        require(success, string(retval));
    }
}
