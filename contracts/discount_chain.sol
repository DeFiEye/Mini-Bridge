// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "interfaces.sol";


contract DiscountImpl_Chain is AccessBase, IDiscountImplV2 {
    address[] private users;
    mapping(address => bool) public userDiscount;
    string public name;
    uint public discount;
    uint public chain_from;
    uint public chain_to;

    constructor(string memory _campaign) {
        name = _campaign;
        discount = 50;
        chain_from = 0;
        chain_to = 10;
    }

    function setConfig(string memory _name, uint _discount, uint _chain_from, uint _chain_to) external onlyOwner{
        name = _name;
        discount = _discount;
        chain_from = _chain_from;
        chain_to = _chain_to;
    }

    function query(address _user, uint _fromChain, uint _toChain, bytes calldata) external view returns (uint _discount, string memory reason) {
        if (_fromChain == chain_from || _toChain == chain_to) {
            if (userDiscount[_user]) {
                return (discount, name);
            }
        }
        return (0, "");
    }

    function set(address[] calldata _users) external onlyOp {
        for(uint i; i<_users.length; i++){
            address u = _users[i];
            userDiscount[u] = true;
            users.push(u);
        }
    }

    function getUsersLength() external view returns(uint){
        return users.length;
    }

    function getUsers(uint start, uint length) external view returns (address[] memory addrs){
        addrs = new address[](length);
        for(uint i; i<length; i++){
            addrs[i] = users[start+i];
        }
    }

    function getUsers() external view returns (address[] memory addrs){
        uint length = users.length;
        addrs = new address[](length);
        for(uint i; i<length; i++){
            addrs[i] = users[i];
        }
    }
}