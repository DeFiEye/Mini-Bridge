// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "interfaces.sol";
import "@openzeppelin/contracts@v4.9.3/utils/structs/EnumerableSet.sol";

contract Discount is AccessBase{
    EnumerableSet.AddressSet private impls;
    using EnumerableSet for EnumerableSet.AddressSet;

    constructor(){}

    function query(address _user) external view returns (uint discount, string memory reason){
        uint length = impls.length();
        for(uint i; i<length; i++){
            (uint256 d, string memory r) = IDiscountImpl(impls.at(i)).query(_user);
            if(d>discount){
                discount = d;
                reason = r;
            }
        }
    }
    function getImpls() external view returns (address[] memory res){
        uint length = impls.length();
        res = new address[](length);
        for(uint i; i<length; i++){
            res[i] = impls.at(i);
        }
    }
    function addImpl(address _impl) external onlyOwner{
        impls.add(_impl);
    }
    function removeImpl(address _impl) external onlyOwner{
        impls.remove(_impl);
    }
}