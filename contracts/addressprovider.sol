// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "interfaces.sol";
import "@openzeppelin/contracts@v4.9.3/utils/structs/EnumerableSet.sol";

contract AddressProvider is AccessBase, IAddressProvider{
    mapping(bytes32=>address) private Contracts;
    EnumerableSet.Bytes32Set private names;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
    function getContract(string memory name) external view returns(address){
        return Contracts[stringToBytes32(name)];
    }
    function _set(string memory name, address c) internal {
        bytes32 n = stringToBytes32(name);
        Contracts[n] = c;
        if(c!=address(0)){
            names.add(n);
        }else{
            names.remove(n);
        }
    }

    function set(string memory name, address c) external onlyOwner{
        _set(name, c);
    }
    function getAllContracts() external view returns (string[] memory _names, address[] memory _contracts){
        uint256 length = names.length();
        _names = new string[](length);
        _contracts = new address[](length);
        for(uint i; i<length; i++){
            _names[i] = string(abi.encodePacked(names.at(i)));
            _contracts[i] = Contracts[names.at(i)];
        }
    }

}
