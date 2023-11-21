import os,sys,requests,json
from Crypto.Hash import keccak

def toi(text):
    if text is None:
        return None
    if isinstance(text, int):
        return text
    if text.startswith("0x"):
        return int(text, 16)
    print("warning: toi", text)
    return int(text, 16)
toint = toi
def toh(i):
    if isinstance(i, str):
        return i
    return hex(i)

def sha3(s):
    if isinstance(s, str):
        assert all([i.lower() in "0123456789abcdef" for i in s])
        s = bd(s)
    return keccak.new(digest_bits=256).update(s).hexdigest()

def event_hash(s):
    return sha3(s.encode("utf-8"))
  
MASK_250 = 2**250 - 1

def sn_functionhash(funcname):
    return int(event_hash(funcname), 16) & MASK_250

import threading
thread_data = threading.local()

def getsess():
    return requests.session()

def rpccall(endpoint, data, timeout=None):
    if timeout is None:
        timeout = int(os.getenv("TIMEOUT", 10))
    sess = thread_data.__dict__.get("sess")
    if not sess:
        sess = getsess()
        thread_data.__dict__["sess"] = sess
   auth = None
   headers = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Safari/605.1.15"}
    if isinstance(data, dict):
        data["jsonrpc"]="2.0"
        if "id" not in data:
            data["id"] = 1
        if "params" not in data:
            data["params"] = []
    x = sess.post(endpoint, json=data, auth=auth, headers=headers, timeout=timeout)
    sys.x = x
    return x

def sn_rpccall(endpoint, method, params, returnint=False, returnx=False):
    data={"method":method, "params":params}
    x = rpccall(endpoint, data)
    assert x.status_code == 200, x.text
    if os.environ.get("DEBUG_VERBOSE"):
        print(x.text)
    if returnx:
        return x
    res = x.json()["result"]
    if returnint:
        if isinstance(res, str):
            res = int(res,16)
    return res

def sn_callfunction(endpoint, contract, funcname, args, height="pending"):
    assert isinstance(args, list)
    return sn_rpccall(endpoint, "starknet_call", [{
        "contract_address": toh(contract),
        "entry_point_selector": toh(sn_functionhash(funcname)),
        "calldata": [toh(i) for i in args]
    }, height if height in ["pending","latest"] else {"block_number": height}])

def sn_balanceOf(endpoint, addr, height="pending"):
    return toi(sn_callfunction(endpoint, sn_ETH, "balanceOf", [addr], height=height)[0])
sn_getBalance = sn_balanceOf
def sn_blockNumber(endpoint):
    return sn_rpccall(endpoint, "starknet_blockNumber", [])

def sn_getBlockByNumber(endpoint, number="latest", needtx=None, verify=None):
    return sn_rpccall(endpoint, "starknet_getBlockWithTxs", [number if number=="latest" else {"block_number":number}])
sn_getBlock = sn_getBlockByNumber
def sn_chainId(endpoint):
    return sn_rpccall(endpoint, "starknet_chainId", [], returnint=True)

def sn_getNonce(endpoint, address, height="pending"):
    return sn_rpccall(endpoint, "starknet_getNonce", [height, address], returnint=True)

def sn_getTransaction(endpoint, txhash):
    return sn_rpccall(endpoint, "starknet_getTransactionByHash", [txhash])

def sn_getTransactionReceipt(endpoint, txhash):
    return sn_rpccall(endpoint, "starknet_getTransactionReceipt", [txhash])

def to256x(i):
    if isinstance(i, str):
        i = int(i, 16)
    return "0x%064x"%(i)

BRAAVOS_IMPL_ADDRESS = 0x5aa23d5bb71ddaa783da7ea79d405315bafa7cf0387a74f4593578c3e9e6570
BRAAVOS_INIT_FUNC = 0x2dd76e7ad84dbed81c314ffe5e7a7cacfb8f4836f01af4e913f275f89a3de1a #sn_functionhash("initializer")

@lru_cache()
def sn_getcalldatahash(publickey):
    print("start")
    from starknet_py.hash.utils import compute_hash_on_elements
    return compute_hash_on_elements(data=[BRAAVOS_IMPL_ADDRESS, BRAAVOS_INIT_FUNC, 1, publickey])

BRAAVOS_CLASS_HASH = 0x3131fa018d520a037686ce3efddeab8f28895662f019ca3ca18a626650f7d1e
BRAAVOS_REAL_IMPL = 0x05dec330eebf36c8672b60db4a718d44762d3ae6d1333e553197acb47ee5a062
def sn_braavos_compute_address(publickey, salt):
    from starknet_py.hash.utils import compute_hash_on_elements
    from starknet_py.constants import CONTRACT_ADDRESS_PREFIX, L2_ADDRESS_UPPER_BOUND
    from crypto_cpp_py.cpp_bindings import cpp_hash
    constructor_calldata_hash = sn_getcalldatahash(publickey)
    starthash = 1353277185873694555937002286240223853167086830429281009651258022948778007428 #cpp_hash(cpp_hash(0, CONTRACT_ADDRESS_PREFIX), 0)
    raw_address = cpp_hash(cpp_hash(cpp_hash(cpp_hash(starthash, salt), BRAAVOS_CLASS_HASH), constructor_calldata_hash), 5)
    return raw_address % L2_ADDRESS_UPPER_BOUND

sn_RPC_testnet = "https://starknet-testnet.blastapi.io/fca03e32-0b73-4781-8ff5-c545074eaada/rpc/v0.4"
sn_RPC_mainnet = "https://starknet-mainnet.blastapi.io/fca03e32-0b73-4781-8ff5-c545074eaada/rpc/v0.4"
def sn_braavos_deploy_account(endpoint, privatekey, salt):
    from starknet_py.net.account.account import Account
    from starknet_py.net.full_node_client import FullNodeClient
    from starknet_py.net.signer.stark_curve_signer import KeyPair
    from starknet_py.hash.address import compute_address
    from starknet_py.hash.transaction import compute_deploy_account_transaction_hash
    from starknet_py.hash.utils import compute_hash_on_elements
    from starknet_py.net.signer.stark_curve_signer import StarkCurveSigner
    from starknet_py.hash.utils import message_signature
    def _sign_deploy_account_transaction(self, transaction):
        contract_address = compute_address(
            salt=transaction.contract_address_salt,
            class_hash=transaction.class_hash,
            constructor_calldata=transaction.constructor_calldata,
            deployer_address=0,
        )
        tx_hash = compute_deploy_account_transaction_hash(
            contract_address=contract_address,
            class_hash=transaction.class_hash,
            constructor_calldata=transaction.constructor_calldata,
            salt=transaction.contract_address_salt,
            max_fee=transaction.max_fee,
            version=transaction.version,
            chain_id=self.chain_id,
            nonce=transaction.nonce,
        )
        tx_hash = compute_hash_on_elements([tx_hash, BRAAVOS_REAL_IMPL, 0, 0, 0, 0, 0, 0, 0])
        r, s = message_signature(msg_hash=tx_hash, priv_key=self.private_key)
        return [r, s, BRAAVOS_REAL_IMPL, 0, 0, 0, 0, 0, 0, 0]
    StarkCurveSigner._sign_deploy_account_transaction = _sign_deploy_account_transaction #patch
    client = FullNodeClient(node_url=endpoint)
    if endpoint in _chainidcache:
        chainid = _chainidcache[endpoint]
    else:
        chainid = sn_chainId(endpoint)
        _chainidcache[endpoint] = chainid
        json.dump(_chainidcache, open("/tmp/chainid.json", "w"))
    kp = KeyPair.from_private_key(privatekey)
    addr = sn_braavos_compute_address(kp.public_key, salt)
    print("to deploy:", to256x(addr))
    x = Account.deploy_account_sync(
        address=addr, 
        class_hash=BRAAVOS_CLASS_HASH, 
        salt=salt, 
        key_pair=kp, 
        client=client, 
        chain=chainid,
        constructor_calldata=[BRAAVOS_IMPL_ADDRESS, BRAAVOS_INIT_FUNC, 1, kp.public_key],
        auto_estimate=True,
    )
    return to256x(x.hash)

def sn_maketx_ethtransfer(endpoint, privatekey, myaddress, to, value, nonce=None, max_fee=10**15, wait=False, needstx=False):
    from starknet_py.contract import Contract
    from starknet_py.net.account.account import Account
    from starknet_py.net.full_node_client import FullNodeClient
    from starknet_py.net.signer.stark_curve_signer import KeyPair
    from starknet_py.net.full_node_client import _create_broadcasted_txn
    import starknet_py
    if endpoint in _chainidcache:
        chainid = _chainidcache[endpoint]
    else:
        chainid = sn_chainId(endpoint)
        _chainidcache[endpoint] = chainid
        json.dump(_chainidcache, open("/tmp/chainid.json", "w"))
    client = FullNodeClient(node_url=endpoint)
    account = Account(client=client, address=myaddress, key_pair=KeyPair.from_private_key(key=privatekey), chain=chainid)
    contract=Contract(address=sn_ETH,abi=[{"name":"Uint256","size":2,"type":"struct","members":[{"name":"low","type":"felt","offset":0},{"name":"high","type":"felt","offset":1}]},{"name":"transfer","type":"function","inputs":[{"name":"recipient","type":"felt"},{"name":"amount","type":"Uint256"}],"outputs":[{"name":"success","type":"felt"}]}],provider=account)
    if nonce is None:
        nonce = sn_getNonce(endpoint, myaddress)
        print("sn_nonce:", nonce)
    prepared = contract.functions["transfer"].prepare(toi(to), value, max_fee=int(max_fee))
    try:
        fee = int(prepared.estimate_fee_sync(nonce=nonce).overall_fee * 1.6)
        assert (not max_fee) or max_fee>=fee, f"provided max_fee {max_fee} < estimated fee {fee}"
        if needstx:
            print("sn sign:", prepared)
            stx = account.sign_invoke_transaction_sync(prepared, nonce=nonce, max_fee=fee)
            return _create_broadcasted_txn(stx)
        invocation = prepared.invoke_sync(max_fee=fee, nonce=nonce)
        txhash = "0x%064x"%(invocation.hash)
        print("sn tx:", txhash)
        if wait:
            return invocation.wait_for_acceptance_sync()
        else:
            return txhash
    except starknet_py.net.client_errors.ClientError as e:
        if "Invalid transaction nonce of contract " in str(e):
            raise NonceError(e)
        raise

sn_ETH = "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7"
def sn_getLogs(endpoint, address, keys, fromBlock, toBlock="latest", pagetoken=None, pagesize=1000):
    filter = {
        "chunk_size": pagesize,
        "from_block": "latest" if fromBlock=="latest" else {"block_number": int(fromBlock)},
        "to_block": "latest" if toBlock=="latest" else {"block_number": int(toBlock)},
        "keys": keys,
        "address": address,
    }
    if pagetoken:
        filter["continuation_token"] = pagetoken
    x = sn_rpccall(endpoint, "starknet_getEvents", {"filter":filter})
    return x

def sn_getLogs_ETHtransfer(endpoint, height="latest"):
    res = []
    x = sn_getLogs(endpoint, sn_ETH, [["0x99cd8bde557814842a3121e8ddfd433a539b8c9f14bf31ebf108d12e6196e9"]], height, height, pagesize=1000)
    res.extend(x["events"])
    while "continuation_token" in x and x["continuation_token"]:
        x = sn_getLogs(endpoint, sn_ETH, [["0x99cd8bde557814842a3121e8ddfd433a539b8c9f14bf31ebf108d12e6196e9"]], height, height, pagesize=1000, pagetoken=x["continuation_token"])
        res.extend(x["events"])
    return res

def sn_getTransactionANDReceipt(endpoint, txid, allow_incorrect=None):
    data = [{
        "id":1, "jsonrpc":"2.0",
        "method":"starknet_getTransactionByHash",
        "params":[txid]
    }, {
        "id":2, "jsonrpc":"2.0",
        "method":"starknet_getTransactionReceipt",
        "params":[txid]
    }, ]
    x = rpccall(endpoint, data)
    assert x.status_code == 200, x.text
    if os.environ.get("DEBUG_VERBOSE"):
        print(x.text)
    tx, receipt = x.json()
    tx = tx.get("result", None)
    if not tx:
        return None
    if receipt.get("result", None):
        tx.update(receipt["result"])
    else:
        return None
    return tx

def sn_gasPrice1559(*args, **kwargs):
    return [0,0]

def sn_gasPrice(*args, **kwargs):
    return 0

def sn_sendRawTransaction(endpoint, signed_tx):
    return sn_rpccall(endpoint, "starknet_addInvokeTransaction", {"invoke_transaction": signed_tx})["transaction_hash"]
