## Starknet in MiniBridge

`base.py` is a simple wrapper for `starknet_py`, provides these functionalities:

- `sn_callfunction`: call a contract function
- `sn_balanceOf`: get ETH balance
- `sn_blockNumber`: get current block number
- `sn_getBlockByNumber`: get a block
- `sn_getNonce`: get account nonce
- `sn_braavos_compute_address` and `sn_braavos_deploy_account`, deploy a braavos account contract
- `sn_maketx_ethtransfer`: ETH transfer to user
- `sn_getLogs`: get events
- `sn_getLogs_ETHtransfer`: get ETH transfer events
- `sn_getTransactionANDReceipt`: get a transaction and its receipt
- `sn_sendRawTransaction`: send a signed tx to RPC

Most of the functions do RPC call itself, without relying on starknet_py to ensure the performance.

Note that braavos account contract overrides the signature process of deploy contract, and `starknet_py` do not support it. We have fixed it by hooking the signature function, see `sn_braavos_deploy_account`.

## Examples

### generate vanity account address:

[generate_vanity_starknet.py](generate_vanity_starknet.py)

You can export your public key and private key from braavos wallet, then run:

```
python3 -m pip install mpms
python3 generate_vanity_starknet.py <your public key>
```

Found salt and address will be written to `found.log`, after you find an address with satisfactory prefix zero length, you can finish the deploy by:

- Send ETH to the new generated address
- call sn_braavos_deploy_account(sn_RPC_mainnet, privatekey, salt)

### bridge received ETH from which txs?

```
p = CHAIN_Provider(chain["id"])
blocknumber = p.eth_blockNumber()
it = list(range(lastnumber, blocknumber+1))
for bn in it:
    print("L"+str(bn), flush=True, end="")
    logs_all = p.sn_getLogs_ETHtransfer(bn)
    logs = [i for i in logs_all if toi(i["data"][1])==int_snEOA]
    for log in logs:
        tx = p.sn_getTransactionANDReceipt(log["transaction_hash"])
        process_tx(tx)
```

### use bridgeTo event to get user destination chain address

See also the [helper contract](../contracts/starknet_helper)

```
LOG_BRIDGETO = sn_functionhash("BridgeTo") #int

def process_tx(tx):
    ...
    thelog = [i for i in tx["events"] if toi(i["keys"][0])==LOG_BRIDGETO and toi(i["from_address"])==int_helper]
    if not thelog:
        print("process fromlog failed:",tx)
        return
    from_, touser = thelog[0]["data"]
    from_ = to256x(from_)
    touser = "0x"+to256x(touser)[26:]
    ...
```

### bridge send ETH to user

```
if chain["type"]=="starknet":
    stx = sn_maketx_ethtransfer(p.E, sn_pk, sn_EOA, touser, tovalue, n, max_fee=10**15, wait=False, needstx=True)
    totx = p.sn_sendRawTransaction(stx)
```
