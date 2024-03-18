// SPDX-License-Identifier: MIT
// https://minibridge.chaineye.tools
pragma solidity 0.8.19;
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
    function approve(address spender, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
}
interface IMiniBridge_Helper{
    function transferETH(uint256 to) external payable;
    function transferERC20(IERC20 token, uint256 to, uint256 amount) external;
    function logTransferERC20(address token, uint256 to, uint256 amount) external;
}
contract MiniBridge_Helper is IMiniBridge_Helper{
    address payable constant BRIDGE = payable(0x00000000000007736e2F9aA5630B8c812E1F3fc9);
    event MiniBridge_Request(address token, bool trusted, address from, uint256 to, uint256 amount);
    // This event is not trusted for ERC20 tokens, Bridge should check ERC20.Transfer event frist

    function transferETH(uint256 to) external payable{
        // This is used to transfer from a contract to Bridge
        (bool success, )=BRIDGE.call{value:msg.value}('');
        require(success, "transfer failed");
        emit MiniBridge_Request(address(0), true, msg.sender, to, msg.value);
    }
    function transferERC20(IERC20 token, uint256 to, uint256 amount) external {
        // This is used by a contract to transfer ERC20 token to Bridge
        // Caller need to approve token first
        uint256 balance_before = token.balanceOf(BRIDGE);
        token.transferFrom(msg.sender, BRIDGE, amount);
        amount = token.balanceOf(BRIDGE) - balance_before;
        emit MiniBridge_Request(address(token), true, msg.sender, to, amount);
    }
    function logTransferERC20(address token, uint256 to, uint256 amount) external {
        // This is used by a contract to emit the bridge request
        // Caller need to transfer the token normally and call this function in the same tx
        // Bridge will search for this event and then validate via searching the ERC20 Transfer event
        // This do not require approve, but requires the caller supporting multiple calls in one tx
        emit MiniBridge_Request(token, false, msg.sender, to, amount);
    }
}
