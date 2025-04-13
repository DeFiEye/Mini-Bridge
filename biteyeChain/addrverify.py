import os, csv, sys
FOLDER = os.path.abspath(os.path.dirname(__file__))
os.chdir(FOLDER+"/..")
sys.path.append(".")
from config import BITEYECHAIN_RPC
os.environ["RPC"] = BITEYECHAIN_RPC
from simplebase import *

AddressProvider = ""

names, addrs = batch_callfunction_decode(RPC, [[AddressProvider,"getAllContracts()",""]], ["string[]","address[]"])[0]
C = dict(zip([i.strip("\x00") for i in names], addrs))
pprint(C)

print("TxProcessor: TxStorage, Invite_Record, Discount_Invite, pMNB, pETH")
storage = batch_callfunction_decode(RPC, [
    [C["TxProcessor"], "txStorage()", ""],
],["address"])[0]
assert storage == C["TxStorage"]
assert eth_getStorageAt(RPC, C["TxProcessor"], 1, format="addr") == C["Invite_Record"]
assert eth_getStorageAt(RPC, C["TxProcessor"], 2, format="addr") == C["pMNB"]
assert eth_getStorageAt(RPC, C["TxProcessor"], 3, format="addr") == C["pETH"]
assert eth_getStorageAt(RPC, C["TxProcessor"], 4, format="addr") == C["Discount_Invite"]

print("OpAccess: TxProcessor have right")
assert callfunction(RPC, C["Operator_Access"], "isOperator(address)", toarg(C["TxProcessor"]))

print("Discount Main: impls")
impls = batch_callfunction_decode(RPC, [
    [C["Discount_Main"], "getImpls()", ""],
],["address[]"])[0]
assert sorted(impls)==sorted([C["Discount_Dynamic"], C["Discount_Fixed"], C["Discount_Invite"]])

print("Discount_Invite")
assert eth_getStorageAt(RPC, C["Discount_Invite"], 0, format="addr") == C["Invite_Record"]

print("Discount_Fixed")
users_len, name5 = batch_callfunction_decode(RPC, [
    [C["Discount_Fixed"], "getUsersLength()", ""],
    [C["Discount_Fixed"], "tierName(uint256)", toarg(5)],
], [["uint"], ["string"]])
print("  length:", users_len)
assert users_len>0
assert name5=="Biteye/Chaineye Gitcoin Gold Donor"

print("Discount_Dynamic")
users_len, myquery = batch_callfunction_decode(RPC, [
    [C["Discount_Dynamic"], "getUsersLength()", ""],
    [C["Discount_Dynamic"], "query(address)", toarg()],
],[["uint"],["uint", "string"]])
print("  length:", users_len)
assert users_len>0
