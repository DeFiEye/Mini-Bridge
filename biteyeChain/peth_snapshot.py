import sys, os
sys.path.append("..")
import config
config.privatekey = config.BITEYECHAIN_privatekey
from config import BITEYECHAIN_RPC_LOCAL
os.environ["TIMEOUT"] = "60"
os.environ["NOADDR"] = "1"
os.environ["RPC"] = BITEYECHAIN_RPC_LOCAL
from simplebase import *
from runsql import runsql


snapshot_parent = {}
for HEIGHT_PARENT in HEIGHT_PARENTS:
    for addr, v in json.load(open(f"peth_balance_{HEIGHT_PARENT}.json")).items():
        if addr not in snapshot_parent:
            snapshot_parent[addr] = 0
        snapshot_parent[addr] += v


logs = eth_getLogs(RPC, 0, HEIGHT+1, address=pETH)
print(f"{len(logs)=}")
users = set()
for log in logs:
    users.add("0x"+log["topics"][2][-40:])
users=sorted(users)

tomint = {}
snapshot = {}
for idx in range(0, len(users), 1000):
    part = users[idx:idx+1000]
    pethbals = batch_callfunction_decode(RPC, [[pETH, "balanceOf(address)", toarg(i)] for i in part], ["uint256"], height=HEIGHT)
    burnedbals = batch_callfunction_decode(RPC, [[Burner, "burnedBalance(address)", toarg(i)] for i in part], ["uint256"], height=HEIGHT)
    for idx2, bal in enumerate(pethbals):
        u = part[idx2]
        v = bal+burnedbals[idx2]-snapshot_parent.get(u, 0)
        if v==0:
            continue
        if v<0:
            print(u, v/1e18, bal/1e18, burnedbals[idx2]/1e18, snapshot_parent.get(u, 0)/1e18)
            if u not in tomint:
                tomint[u] = 0
            tomint[u] += -v
            continue
        snapshot[u] = v

print("to mint should be zero:", sum(tomint.values())/1e18)
print(f"{len(snapshot)=} {sum(snapshot.values())/1e18=}")
open(f"peth_balance_{HEIGHT}.json", "w").write(json.dumps(snapshot))
print("top10:")
pprint([[i[0],i[1]/1e18] for i in sorted(snapshot.items(), key=lambda i:i[1], reverse=True)[:10]])