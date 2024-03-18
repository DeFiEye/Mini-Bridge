// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


import "interfaces.sol";
import "@openzeppelin/contracts@v4.9.3/utils/structs/EnumerableSet.sol";

contract InviteRecordV2_TEMP is AccessBase, IInviteRecord{
    using EnumerableSet for EnumerableSet.AddressSet;
    string MESSAGE_PREFIX = "Welcome to ChainEye MiniBridge\n\nPlease sign this message to verify you're invited by 0x";
    string MESSAGE_SUFFIX = "";
    string MESSAGE_PREFIX2 = "Welcome to ChainEye MiniBridge\n\nPlease sign this message to use invite code ";
    string MESSAGE_SUFFIX2 = "";
    mapping(address=>address[]) private invitesAll; //a=>[b] includes all pending invited users
    mapping(address=>EnumerableSet.AddressSet) private invitesActive; //a=>[b] only includes bridged invited users
    mapping(address=>address) public invitedBy; //b=>a
    mapping(string=>address) public s2a; //short invite code=>address

    function setMessage(string calldata _prefix, string calldata _suffix) external  onlyOwner{
        MESSAGE_PREFIX = _prefix;
        MESSAGE_SUFFIX = _suffix;
    }

    function setMessage2(string calldata _prefix, string calldata _suffix) external  onlyOwner{
        MESSAGE_PREFIX2 = _prefix;
        MESSAGE_SUFFIX2 = _suffix;
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function recoverSignature(address _inviter, bytes memory _sig) public view returns(address signer){
        bytes memory message = abi.encodePacked(MESSAGE_PREFIX, toAsciiString(_inviter), MESSAGE_SUFFIX);
        message = abi.encodePacked("\x19Ethereum Signed Message:\n", uint2str(message.length), message);
        //return message;
        bytes32 messageHash = keccak256(message);
        bytes32 r; bytes32 s; uint8 v;
        require(_sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }
        return ecrecover(messageHash, v, r, s);
    }

    function recoverSignature2(string memory code, bytes memory _sig) public view returns(address signer){
        bytes memory message = abi.encodePacked(MESSAGE_PREFIX2, code, MESSAGE_SUFFIX2);
        message = abi.encodePacked("\x19Ethereum Signed Message:\n", uint2str(message.length), message);
        //return message;
        bytes32 messageHash = keccak256(message);
        bytes32 r; bytes32 s; uint8 v;
        require(_sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }
        return ecrecover(messageHash, v, r, s);
    }

    event Invite(address a, address b);
    event ActiveInvite(address a, address b);

    function set(address _a, address _b, bytes memory _sig) external{
        require(_a != _b, "cannot invite self");
        require(invitedBy[_b] == address(0), "already be invited");
        require(recoverSignature(_a, _sig) == _b, "invalid signature");
        require(invitesAll[_b].length == 0, "already invited other users"); 
        address txStorage = ADDRESS_PROVIDER.getContract("TxStorage");
        //require(ITxStorage(txStorage).userTxIdxs_length(_b)==0, "already bridged");
        invitesAll[_a].push(_b);
        invitedBy[_b] = _a;
        emit Invite(_a, _b);
    }

    function set2(address _a, string memory _code, address _b, bytes memory _sig) external onlyOp {
        require(_a != _b, "cannot invite self");
        require(invitedBy[_b] == address(0), "already be invited");
        require(recoverSignature2(_code, _sig) == _b, "invalid signature");
        if(s2a[_code] == address(0)){
            s2a[_code] = _a;
        }
        require(s2a[_code] == _a, "wrong invite code");
        require(invitesAll[_b].length == 0, "already invited other users"); 
        address txStorage = ADDRESS_PROVIDER.getContract("TxStorage");
        require(ITxStorage(txStorage).userTxIdxs_length(_b)==0, "already bridged");
        invitesAll[_a].push(_b);
        invitedBy[_b] = _a;
        emit Invite(_a, _b);
    }

    function getInvites(address _a) external view returns(address[] memory all, address[] memory active){
        uint length = invitesActive[_a].length();
        active = new address[](length);
        for(uint i; i<length; i++){
            active[i] = invitesActive[_a].at(i);
        }
        return (invitesAll[_a], active);
    }
    function getInvitesCount(address _a) external  view returns(uint){
        return invitesAll[_a].length;
    }
    function getActiveInvitesCount(address _a) external  view returns(uint){
        return invitesActive[_a].length();
    }
    function getMessage() external view returns (string memory, string memory){
        return (MESSAGE_PREFIX, MESSAGE_SUFFIX);
    }
    function getMessage2() external view returns (string memory, string memory, string memory, string memory){
        return (MESSAGE_PREFIX, MESSAGE_SUFFIX, MESSAGE_PREFIX2, MESSAGE_SUFFIX2);
    }

    function addActiveInvite(address _a, address _b) external onlyOp{
        require(invitedBy[_b] == _a, "!invitedBy");
        invitesActive[_a].add(_b);
        emit ActiveInvite(_a, _b);
    }
}
