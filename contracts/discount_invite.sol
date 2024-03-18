// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "interfaces.sol";
import "@openzeppelin/contracts@v4.9.3/utils/structs/EnumerableSet.sol";

contract Discount_InviteRecord is AccessBase, IDiscountImpl{
    IInviteRecord IR = IInviteRecord(0x7d119De0B8f139eEFa397c1a921761E9F17b4C3b);
    function setIR(IInviteRecord _newContract) external onlyOwner{
        IR = _newContract;
    }

    uint public invitedDiscount = 5; 
    function setInvitedDiscount(uint _discount) external onlyOwner{
        invitedDiscount = _discount;
    }

    uint[] invitesTierRequirement = [1, 5, 10, 20, 50];
    string[] invitesTierName = [
        "None", //0 tier0 0%
        "Bronze", // [1,4] tier1 10%
        "Sliver", // [5,9] tier2 15%
        "Gold",  // [10,19] tier3 20%
        "Platinum", // [20,49] tier4 25%
        "Diamond" // [50, infinite) tier5 30%
    ];
    uint[] inviterDiscount = [0, 10, 15, 20, 25, 30];
    function getDiscount() external view returns(uint, uint[] memory, string[] memory names, uint[] memory){
        return (invitedDiscount, invitesTierRequirement, invitesTierName, inviterDiscount);
    }
    function setInviterDiscount(uint[] calldata _requirement, string[] calldata _tierNames, uint[] calldata _discounts) external onlyOwner{
        require(_requirement.length == _tierNames.length-1, "requirement length mismatch");
        require(inviterDiscount.length == _tierNames.length, "discounts length mismatch");
        invitesTierRequirement = _requirement;
        delete invitesTierName;
        for(uint i; i<_tierNames.length; i++){
            invitesTierName.push(_tierNames[i]);
        }
        inviterDiscount = _discounts;
    }

    function getInviterTier(address _user) public view returns(uint256 tier){
        uint256 count = IR.getActiveInvitesCount(_user);
        uint i;
        for(; i<invitesTierRequirement.length; i++){
            if(count<invitesTierRequirement[i]){
                return i;
            }
        }
        return invitesTierRequirement.length;
    }
    function query(address _user) external view returns (uint ratio, string memory reason){
        if(IR.invitedBy(_user) != address(0)){
            ratio = invitedDiscount;
            reason = "Being Invited";
        }
        uint tier = getInviterTier(_user);
        if(tier>0){
            ratio = inviterDiscount[tier];
            reason = string(abi.encodePacked(invitesTierName[tier], " Inviter"));
        }
    }
}
