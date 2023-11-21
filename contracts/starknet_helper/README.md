## MiniBridge Starknet Helper contract

[https://starkscan.co/contract/0x01d255d23dd2018cc977d9724f1858fb4ea5cb0ec2d3cfd0ffb6e0ba1c1bc3f4](https://starkscan.co/contract/0x01d255d23dd2018cc977d9724f1858fb4ea5cb0ec2d3cfd0ffb6e0ba1c1bc3f4)

This contract is called by user tx to emit a `BridgeTo` event, so bridge can know which EVM address users want to bridge to

Thus users do not need to approve ETH token to any contract, and the bridge can get his destination to user.
