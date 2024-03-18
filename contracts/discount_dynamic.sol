// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "interfaces.sol";
import "@openzeppelin/contracts@v4.9.3/utils/structs/EnumerableSet.sol";

contract DiscountImpl_Dynamic is AccessBase, IDiscountImpl{
    EnumerableSet.AddressSet private users;
    using EnumerableSet for EnumerableSet.AddressSet;
    string name = "Teddy FT Key Holder";
    uint256 discount = 20;

    function setConfig(uint256 _discount, string calldata _name) external onlyOwner{
        discount = _discount;
        name = _name;
    }
    function query(address _user) external view returns (uint, string memory){
        if(users.contains(_user)){
            return (discount, name);
        }else{
            return (0, "");
        }
    }
    function set(address[] calldata _addUsers, address[] calldata _removeUsers) external onlyOp{
        for(uint i; i<_addUsers.length; i++){
            users.add(_addUsers[i]);
        }
        for(uint i; i<_removeUsers.length; i++){
            users.remove(_removeUsers[i]);
        }
    }

    function getUsersLength() external view returns(uint){
        return users.length();
    }
    function getUsers(uint start, uint length) external view returns (address[] memory addrs){
        addrs = new address[](length);
        for(uint i; i<length; i++){
            addrs[i] = users.at(start+i);
        }
    }
    function getUsers() external view returns (address[] memory addrs){
        uint length = users.length();
        addrs = new address[](length);
        for(uint i; i<length; i++){
            addrs[i] = users.at(i);
        }
    }
}
