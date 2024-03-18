// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "interfaces.sol";
import "@openzeppelin/contracts@v4.9.3/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@v4.9.3/token/ERC20/extensions/ERC20Burnable.sol";
import "token.sol";
contract TxStorage is AccessBase, ITxStorage{
    address public pMNB = address(new TOKEN("pMNB"));
    address public pETH = address(new TOKEN("pETH"));

    Tx_From[] public txs_from;
    Tx_To[] public txs_to;
    Tx_Invite[] public txs_invite;

    uint public totalFromValue;
    uint public totalToValue;
    function txs_length() external view returns (uint){
        return txs_from.length;
    }
    mapping(bytes32=>uint256) public tx2id;
    function getTx(bytes32 txhash) external view returns(Tx_From memory, Tx_To memory, Tx_Invite memory){
        uint idx = tx2id[txhash];
        return (txs_from[idx], txs_to[idx], txs_invite[idx]);
    }
    mapping(address=>uint256[]) public inviterTxIdxs;
    function inviterTxIdxs_length(address user) external view returns(uint){
        return inviterTxIdxs[user].length;
    }
    function getTxInviter(address user, uint N) external view returns(Tx_From[] memory tx_froms, Tx_To[] memory tx_tos, Tx_Invite[] memory tx_invites){
        //return the latest N txs invited by this user
        uint length = inviterTxIdxs[user].length;
        if(N>length){
            N = length;
        }
        tx_froms = new Tx_From[](N);
        tx_tos = new Tx_To[](N);
        tx_invites = new Tx_Invite[](N);
        uint idx;
        for(uint i=length-N; i<length; i++){
            uint txidx = inviterTxIdxs[user][i];
            tx_froms[idx] = txs_from[txidx];
            tx_tos[idx] = txs_to[txidx];
            tx_invites[idx] = txs_invite[txidx];
            idx++;
        }
    }
    mapping(address=>uint256[]) public userTxIdxs;
    function userTxIdxs_length(address user) external view returns(uint){
        return userTxIdxs[user].length;
    }
    function getTxUser(address user, uint N) external view returns(Tx_From[] memory tx_froms, Tx_To[] memory tx_tos, Tx_Invite[] memory tx_invites){
        //return the latest N txs by this user
        uint length = userTxIdxs[user].length;
        if(N>length){
            N = length;
        }
        tx_froms = new Tx_From[](N);
        tx_tos = new Tx_To[](N);
        tx_invites = new Tx_Invite[](N);
        uint idx;
        for(uint i=length-N; i<length; i++){
            uint txidx = userTxIdxs[user][i];
            tx_froms[idx] = txs_from[txidx];
            tx_tos[idx] = txs_to[txidx];
            tx_invites[idx] = txs_invite[txidx];
            idx++;
        }
    }
    function writeTx(Tx_From memory item_from, Tx_To memory item_to, Tx_Invite memory item_invite) external onlyOp returns(uint idx){
        require(tx2id[item_from.fromtx] == 0, "already processed");
        idx = txs_from.length;
        txs_from.push(item_from);
        txs_to.push(item_to);
        txs_invite.push(item_invite);

        tx2id[item_from.fromtx] = idx;
        tx2id[item_to.totx] = idx;
        totalFromValue += item_from.fromamount;
        totalToValue += item_to.toamount;
        if(item_invite.inviter!=address(0)){
            inviterTxIdxs[item_invite.inviter].push(idx);
        }
        userTxIdxs[item_from.useraddr].push(idx);
    }
    constructor(){
        txs_from.push({}); //avoid using 0 index
        txs_to.push({});
        txs_invite.push({});
    }
}

contract StarknetAddress_Translator is AccessBase  {
    uint256 public nextAddress = 91343852333181432387730302044767688728495783936;
    mapping (uint256 => address) public stark2address;
    mapping (address => uint256) public address2stark;
    function getAddressForStark(uint256 starkAddr) external onlyOp returns(address) {
        if (starkAddr < 1461501637330902918203684832716283019655932542976){
            return address(uint160(starkAddr));
        }
        if (stark2address[starkAddr] != address(0)){
            return stark2address[starkAddr];
        }
        address a = address(uint160(nextAddress));
        stark2address[starkAddr] = a;
        address2stark[a] = starkAddr;
        nextAddress++;
        return a;
    }
}

contract TxProcessorV3 is AccessBase { //supporting Starknet address
    TxStorage public txStorage = TxStorage(ADDRESS_PROVIDER.getContract("TxStorage"));//new TxStorage();
    IInviteRecord public IR = IInviteRecord(ADDRESS_PROVIDER.getContract("Invite_Record"));
    ITOKEN public pMNB = ITOKEN(txStorage.pMNB());
    ITOKEN public pETH = ITOKEN(txStorage.pETH());
    IDiscount_InviteRecord public DIR = IDiscount_InviteRecord(ADDRESS_PROVIDER.getContract("Discount_Invite"));
    IHookRatioOverride public hook;
    uint256 public USER_AMOUNT = 100*10**18; // each tx pMNB mint amount to user
    uint256 public INVITE_NEWUSER_AMOUNT = 1000*10**18; //each new user mint amount to inviter
    StarknetAddress_Translator public Translator = StarknetAddress_Translator(ADDRESS_PROVIDER.getContract("StarknetAddress_Translator"));//new StarknetAddress_Translator();

    function setStorage(TxStorage _newContract) external onlyOwner{
        txStorage = _newContract;
    }
    function setIR(IInviteRecord _newContract) external onlyOwner{
        IR = _newContract;
    }
    function setDIR(IDiscount_InviteRecord _newContract) external onlyOwner{
        DIR = _newContract;
    }
    function setAmount(uint _user_amount, uint _newuser_amount) external onlyOwner{
        USER_AMOUNT = _user_amount;
        INVITE_NEWUSER_AMOUNT = _newuser_amount;
    }

    function processTx(Tx_FromV2 memory tx_from, Tx_ToV2 memory tx_to) public onlyOp{
        address useraddr = Translator.getAddressForStark(tx_from.useraddr_int);
        address inviter = IR.invitedBy(useraddr);
        uint256 fee = tx_from.fromamount-tx_to.toamount;

        pMNB.mint(useraddr, USER_AMOUNT);
        uint inviterMNB = 0;
        uint inviterETH = 0;
        if(inviter != address(0)){
            if(txStorage.userTxIdxs_length(useraddr) == 0){
                inviterMNB+= INVITE_NEWUSER_AMOUNT;
                IR.addActiveInvite(inviter, useraddr);
            }
            (,,,uint[] memory inviterDiscount) = DIR.getDiscount();
            uint256 tier = DIR.getInviterTier(inviter);
            uint256 ratio = inviterDiscount[tier];
            if(address(hook) != address(0)){
                ratio = hook.getRatioOverride(tx_from.fromchain, tx_to.tochain, useraddr, tier, ratio);
            }
            if(ratio>0){
                inviterMNB += USER_AMOUNT*ratio/100;
                inviterETH = fee*ratio/100;
                pETH.mint(inviter, fee*ratio/100);
            }
            pMNB.mint(inviter, inviterMNB);
        }
        Tx_Invite memory tx_invite = Tx_Invite({inviter:inviter, inviterMNB:inviterMNB, inviterETH:inviterETH, userMNB:USER_AMOUNT});
        Tx_From memory tx_from_new = Tx_From({
            fromchain: tx_from.fromchain,
            fromtx: tx_from.fromtx,
            fromblock: tx_from.fromblock,
            fromtime: tx_from.fromtime,
            useraddr: useraddr,
            fromamount: tx_from.fromamount
        });
        Tx_To memory tx_to_new = Tx_To({
            tochain: tx_to.tochain,
            locknonce: tx_to.locknonce,
            totx: tx_to.totx,
            toblock: tx_to.toblock,
            totime: tx_to.totime,
            toamount: tx_to.toamount,
            touser: Translator.getAddressForStark(tx_to.touser_int)
        });
        txStorage.writeTx(tx_from_new, tx_to_new, tx_invite);
    }
}

contract Proxy_TxProcessorV3 is AccessBase {
    TxStorage public txStorage = TxStorage(ADDRESS_PROVIDER.getContract("TxStorage"));//new TxStorage();
    IInviteRecord public IR = IInviteRecord(ADDRESS_PROVIDER.getContract("Invite_Record"));
    ITOKEN public pMNB = ITOKEN(txStorage.pMNB());
    ITOKEN public pETH = ITOKEN(txStorage.pETH());
    IDiscount_InviteRecord public DIR = IDiscount_InviteRecord(ADDRESS_PROVIDER.getContract("Discount_Invite"));
    IHookRatioOverride public hook;
    uint256 public USER_AMOUNT = 100*10**18; // each tx pMNB mint amount to user
    uint256 public INVITE_NEWUSER_AMOUNT = 1000*10**18; //each new user mint amount to inviter
    StarknetAddress_Translator public Translator = StarknetAddress_Translator(ADDRESS_PROVIDER.getContract("StarknetAddress_Translator"));//new StarknetAddress_Translator();

    function setLogicContract(address _c) external onlyOwner {
        getAddressSlot(_IMPLEMENTATION_SLOT).value = _c;
    }

    fallback () payable external {
        address target = getAddressSlot(_IMPLEMENTATION_SLOT).value;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), target, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    constructor(){
        getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x191Ceb67224F37f1A9CfDF3116801527DA52265A;
    }
}
