// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
// Gitcoin Donators

import "interfaces.sol";

contract DiscountImpl_Fixed is AccessBase, IDiscountImpl{
    mapping(address=>uint) public discountTier;
    mapping(uint=>uint) public tierDiscount;
    mapping(uint=>string) public tierName;
    address[] private users;
    constructor(){
        tierDiscount[1] = 10; tierName[1] = "Biteye/Chaineye Gitcoin Bronze Donor";
        tierDiscount[2] = 10; tierName[2] = "Biteye/Chaineye Gitcoin Bronze Donor";
        tierDiscount[3] = 15; tierName[3] = "Biteye/Chaineye Gitcoin Sliver Donor";
        tierDiscount[4] = 15; tierName[4] = "Biteye/Chaineye Gitcoin Sliver Donor";
        tierDiscount[5] = 20; tierName[5] = "Biteye/Chaineye Gitcoin Gold Donor";
    }
    function setTier(uint _tier, uint _discount, string calldata _name) external onlyOwner{
        tierDiscount[_tier] = _discount;
        tierName[_tier] = _name;
    }
    function query(address _user) external view returns (uint, string memory){
        uint tier = discountTier[_user];
        if(tier==0){
            return (0, "");
        }
        return (tierDiscount[tier], tierName[tier]);
    }
    function set(uint tier, address[] calldata _users) external onlyOp{
        for(uint i; i<_users.length; i++){
            address u = _users[i];
            discountTier[u] = tier;
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
