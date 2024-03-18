// SPDX-License-Identifier: MIT
// merlin 0x257312be423cEB2D43683f44b101dC10dfEe3e22
pragma solidity 0.8.19;

contract MiniBridge_Merlin_Receiver{
    address constant BRIDGE = 0x1111111111DBe148a40Ca44d7969490db41c6910;
    event BridgeRequest(address indexed user, uint256 amount);
    event BridgeAndSwapRequest(address indexed user, uint256 amount, uint256 minOut);
    bool public isPaused;
    function bridgeOut(address to) public payable{
        require(!isPaused, "paused");
        (bool success, ) = BRIDGE.call{value:msg.value}("");
        require(success, "transfer failed");
        emit BridgeRequest(to, msg.value);
    }
    function bridgeOutAndSwap(address to, uint256 minOut) public payable{
        require(!isPaused, "paused");
        (bool success, ) = BRIDGE.call{value:msg.value}("");
        require(success, "transfer failed");
        emit BridgeAndSwapRequest(to, msg.value, minOut);
    }
    function bridgeOutSelf() external payable{
        bridgeOut(msg.sender);
    }
    function bridgeOutAndSwapSelf(uint256 minOut) external payable{
        bridgeOutAndSwap(msg.sender, minOut);
    }
    function setPaused(bool newStatus) external{
        require(msg.sender == BRIDGE, "onlyOwner");
        isPaused = newStatus;
    }
}
