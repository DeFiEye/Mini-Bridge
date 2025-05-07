// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "interfaces.sol";

contract Forwarder is AccessBase{
    function forward(address user, address to, bytes memory call) payable external onlyOp returns (bytes memory){
        bytes memory data = abi.encodePacked(call, user);
        (bool success, bytes memory ret) = to.call{value:msg.value}(data);
        require(success, string(ret));
        return ret;
    }
}