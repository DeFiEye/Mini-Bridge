## MiniBridge Internal Contracts

Thanks for your interest to our contracts, contrary to what you may expect, these contracts are NOT the core part of the bridging logic.

Our backend use them to record and track bridging events, like invites, pMNB and pETH, and these contracts are not deployed to any public chains.

You can treat these contracts as a kind of database scripts, bugs/vulnerabilities involved in these contracts do not affect bridging fund.

If you want to use our bridge programmatically, please refer to our API doc: https://docs.chaineye.tools/minibridge-api-docs 

[Helper.sol](https://arbiscan.io/address/0x000000000000Bd696655814b68C2f67e399ab4e5#code) is what you need to start a bridging request from a contract, see also the last section of the API docs.
