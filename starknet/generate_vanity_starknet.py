from base import *
from mpms import MPMS
target = 4
bar = b'\x00'*target
pub=publickey=sys.argv[1]

import ctypes
from starknet_py.hash.utils import compute_hash_on_elements
from starknet_py.constants import CONTRACT_ADDRESS_PREFIX, L2_ADDRESS_UPPER_BOUND
from crypto_cpp_py.cpp_bindings import cpp_hash
CLASS_HASH = 0x3131fa018d520a037686ce3efddeab8f28895662f019ca3ca18a626650f7d1e #proxy
constructor_calldata_hash = sn_getcalldatahash(publickey)
#print(constructor_calldata_hash.to_bytes(32, "little", signed=False))
#cpp_hash(cpp_hash(0, CONTRACT_ADDRESS_PREFIX), 0).to_bytes(32, "little", signed=False)
from crypto_cpp_py.cpp_bindings import CPP_LIB_BINDING

def worker(start, N):
    res = ctypes.create_string_buffer(1024)
    #print("start:", start)
    try:
        for salt in range(start, 2**256-1, N):
            CPP_LIB_BINDING.Hash(b'\x84\xdb\xbb\xbd\xfe\xc6\x81\xf7sw\xe8\x95\x82\x0f\xa2BM\xc6\xc5&\xd5\xacb\xf2R=A\x9d\x80\xed\xfd\x02', salt.to_bytes(32, "little", signed=False), res)
            CPP_LIB_BINDING.Hash(res, b'\x1e}\x0fe&\xa6\x18\xca\xa3\x9c\x01/f\x95\x88\xf2\xb8\xea\xdd\xef\xe3lh7\xa0 \xd5\x18\xa0\x1f\x13\x03', res)#CLASS_HASH.to_bytes(32, "little", signed=False)
            CPP_LIB_BINDING.Hash(res, b'\\\xf9aE\xf6\x7f#\xc2\x8eE\x86\xc1\x15N\xca\x9c\xbc\xad\xf9\xda\xe8<5b\x1dY\xea\xffcE\xdc\x01', res) #constructor_calldata_hash
            CPP_LIB_BINDING.Hash(res, b'\x05\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00', res)
            if res.raw[:32].endswith(bar):
                a = int.from_bytes(res.raw[:32], "little", signed=False) % L2_ADDRESS_UPPER_BOUND
                print("\nfound:", salt, to256x(a))
                open("found.log", "a").write(f"{salt} {to256x(a)}\n")
            if salt%10000==0:
                print(".", flush=True, end="")
    except:
        traceback.print_exc()
        print("salt:", salt)

def handler(*args):
    pass

if __name__ == "__main__":
    if len(sys.argv)==2:
        start = int(sys.argv[1])
    else:
        start = 0
    N = int(os.getenv("N", 5))
    m = MPMS(worker, handler, N, 1)
    m.start()
    for start in range(start, start+N):
        m.put(start, N)
    m.join()
