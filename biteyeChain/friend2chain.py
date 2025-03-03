import os, csv, sys
FOLDER = os.path.abspath(os.path.dirname(__file__))
os.chdir(FOLDER+"/..")
sys.path.append(".")
import config
config.privatekey = config.BITEYECHAIN_privatekey
from config import BITEYECHAIN_RPC
os.environ["RPC"] = BITEYECHAIN_RPC
from simplebase import *

CONTRACT=""
holders = json.load(open("friend_holders.json"))
print("holders:", len(holders))

existing = batch_callfunction_decode(RPC, [[CONTRACT, "getUsers()", ""]], ["address[]"])[0]
print("existing:", len(existing))

toadd = [i for i in holders if i not in existing]
todel = [i for i in existing if i not in holders]

if toadd or todel:
    GP = 11*10**8
    nonce = eth_getNonce(RPC, MYADDR)
    cd = "0x"+function_hash("set(address[],address[])")+ec(["address[]","address[]"], [toadd, todel])
    print("add", toadd)
    print("del", todel)
    waittx(maketx(CONTRACT, cd, nonce, GP, False, showgas=True, writetx=False))
    nonce += 1