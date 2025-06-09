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

HEIGHT = 212248

_,expireTime,userCount,totalETH,claimedETH = batch_callfunction_decode(RPC, [[
    Burner, "snapshots(uint256)", toarg(HEIGHT),
]], ["uint256","uint256","uint256","uint256","uint256",])[0]
data = json.load(open(f"peth_balance_{HEIGHT}.json"))
users = sorted(data.keys())
#print(users)
x = batch_callfunction_decode(RPC,[[Burner, "snapshotValue(uint256,address)", toarg(HEIGHT)+toarg(u)] for u in users], ["uint"])
if not time.time()>expireTime:
    print(f"need wait {(expireTime-time.time())/86400:.1f}day")
    exit(1)
#assert sum(x) == totalETH-claimedETH
print("to burn:", sum(x)/1e18)
toburn_users = [u for idx,u in enumerate(users) if x[idx]>0]
print("len:", len(toburn_users))

if toburn_users:
    cd = "0x"+function_hash("burnExpired(uint256,address[])")+ec(["uint256","address[]"], [HEIGHT, toburn_users])
    waittx(maketx(Burner, cd, showgas=True))