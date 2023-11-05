// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "interfaces.sol";
contract OpAccess is IAccess{
    address public owner;
    mapping(address=>bool) public isOperator;
    modifier onlyOwner1 {
        require(msg.sender == owner, "!owner");
        _;
    }
    function onlyOp(address sender) external view {
        require(isOperator[sender], "!op");
    }
    function onlyOwner(address sender) external view{
        require(sender == owner, "!owner");
    }
    constructor(){
        owner = msg.sender;
        isOperator[msg.sender]=true;
        isOperator[owner] = true;
    }
    function setOperator(address _op, bool _value) external onlyOwner1{
        isOperator[_op] = _value;
    }
}