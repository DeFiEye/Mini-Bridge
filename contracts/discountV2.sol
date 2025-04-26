// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "interfaces.sol";
import "discount_chain.sol";
contract DiscountV2 is AccessBase {
    mapping(address => uint) public implsVersion;
    address[] public impls;

    constructor(){

        DiscountImpl_Chain trusta = new DiscountImpl_Chain();
        impls.push(address(trusta));
        implsVersion[address(trusta)] = 2;
    }
    function query(address _user, uint _fromChain, uint _toChain, bytes calldata _ext) external view returns (uint discount, string memory reason, address impl) {
        uint length = impls.length;
        for(uint i; i<length; i++){
            if (implsVersion[impls[i]] == 2) {
                (uint256 d, string memory r) = IDiscountImplV2(impls[i]).query(_user, _fromChain, _toChain, _ext);
                if(d>discount){
                    discount = d;
                    reason = r;
                    impl = impls[i];
                }
            }
            else if (implsVersion[impls[i]] == 1) {
                (uint256 d, string memory r) = IDiscountImpl(impls[i]).query(_user);
                if(d>discount){
                    discount = d;
                    reason = r;
                    impl = impls[i];
                }
            }
        }
    }
    function getImpls() external view returns (address[] memory addrs, uint[] memory vers){
        uint length = impls.length;
        addrs = new address[](length);
        vers = new uint[](length);
        for(uint i; i<length; i++){
            addrs[i] = impls[i];
            vers[i] = implsVersion[impls[i]];
        }
    }
    event AddImpl(address, uint);
    function addImpl(address _impl, uint _version) external onlyOwner{
        require(implsVersion[_impl] == 0, "already added");
        impls.push(_impl);
        implsVersion[_impl] = _version;
        emit AddImpl(_impl, _version);
    }
    event RemoveImpl(address);
    function removeImpl(address _impl) external onlyOwner{
        require(implsVersion[_impl] > 0, "impl not added");
        uint length = impls.length;
        for(uint i; i<length; i++){
            if (impls[i] == _impl) {
                impls[i] = impls[length - 1];
                impls.pop();
                break;
            }
        }
        implsVersion[_impl] = 0;
        emit RemoveImpl(_impl);
    }
}