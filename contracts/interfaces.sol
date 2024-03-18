// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IDiscountImpl{
    function query(address user) external view returns (uint ratio, string memory reason);//return (85, "Gitcoin Donator") can return 0 means no discount
}

interface IAccess {
    function onlyOp(address) external view;
    function onlyOwner(address) external view;
    function owner() external view returns (address);
}

contract AccessBase {
    IAccess constant ACCESS = IAccess(0x89F3172338f2F639B3f7DCB12F086D9E7d03779D);
    modifier onlyOp(){
        ACCESS.onlyOp(msg.sender);
        _;
    }
    modifier onlyOwner(){
        ACCESS.onlyOwner(msg.sender);
        _;
    }
    function proxyDelegateCall(address target, bytes calldata call) onlyOwner public payable{
        (bool success, bytes memory retval) = target.delegatecall(call);
        require(success, string(retval));
    }
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    struct AddressSlot {
        address value;
    }

    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

interface IInviteRecord{
    function getActiveInvitesCount(address _a) external  view returns(uint);
    function addActiveInvite(address _a, address _b) external;
    function invitedBy(address _b) external view returns (address a);
}

import "@openzeppelin/contracts@v4.9.3/token/ERC20/IERC20.sol";
interface ITOKEN is IERC20{
    function mint(address to, uint256 amount) external;
    function burn(address user, uint256 amount) external;
}

interface IDiscount_InviteRecord{
    function getDiscount() external view returns(uint, uint[] memory, string[] memory names, uint[] memory);
    function getInviterTier(address _user) external view returns(uint256 tier);
}

interface IHookRatioOverride {
    function getRatioOverride(uint fromChain, uint toChain, address fromuser, uint tier, uint ratio) external returns (uint newRatio);
}

interface IAddressProvider{
    function getContract(string memory name) external view returns(address);
}

IAddressProvider constant ADDRESS_PROVIDER = IAddressProvider(0x3487bd11Fc91feaa62266bAf4A230517320919CD);

struct Tx_From{
    uint256 fromchain;
    bytes32 fromtx;
    uint256 fromblock;
    uint256 fromtime;
    address useraddr;
    uint256 fromamount;
}
struct Tx_To{
    uint256 tochain;
    uint256 locknonce;
    bytes32 totx;
    uint256 toblock;
    uint256 totime;
    uint256 toamount;
    address touser;
}
struct Tx_Invite{
    address inviter;
    uint256 inviterMNB;
    uint256 inviterETH;
    uint256 userMNB;
}
interface ITxStorage{
    function getTx(bytes32 txhash) external view returns(Tx_From memory, Tx_To memory, Tx_Invite memory);
    function userTxIdxs_length(address user) external view returns(uint);
}

struct Tx_FromV2{
    uint256 fromchain;
    bytes32 fromtx;
    uint256 fromblock;
    uint256 fromtime;
    uint256 useraddr_int;
    uint256 fromamount;
}
struct Tx_ToV2{
    uint256 tochain;
    uint256 locknonce;
    bytes32 totx;
    uint256 toblock;
    uint256 totime;
    uint256 toamount;
    uint256 touser_int;
}
interface IStarknetAddress_Translator{
    function getAddressForStark(uint256 starkAddr) external returns(address);
}
