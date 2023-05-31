// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
contract MultiVests is Initializable {

    struct vestData {
        uint amount;
        uint startTimestamp;
        uint endTimestamp;
        uint duration;
        uint claimed;
    }
    vestData[] public vests;
    address public receiver;
    address admin;
    IERC20 public token;

    event VestCreated(address indexed receiver, uint amount, uint duration);
    event Claimed(address receiver, uint amount);
    event VestTransferred(address indexed oldReceiver, address indexed newReceiver);

    constructor() {
        _disableInitializers();
    }

    function initialize(address _admin, address _token, address _receiver) initializer public {
        admin = _admin;
        receiver = _receiver;
        token = IERC20(_token);
    }

    function newVest(uint _amount, uint _duration) public {
        require(msg.sender == admin);
        uint end = block.timestamp + _duration;
        vestData memory vest = vestData(_amount, block.timestamp, end, _duration, 0);
        vests.push(vest);
        emit VestCreated(receiver, _amount, _duration);
    }

    function totalVested(uint index) public view returns (uint amount) {
        vestData storage data = vests[index];
        if(block.timestamp >= data.endTimestamp) {
            return data.amount;
        }
        uint secondsSince = block.timestamp - data.startTimestamp;
        amount = Math.mulDiv(data.amount, secondsSince, data.duration, Math.Rounding.Up);
    }

    function claimable(uint index) public view returns (uint amount) {
        uint _claimed = vests[index].claimed;
        amount = totalVested(index) - _claimed;
    }

    function claim(uint index) public {
        uint _claimable = claimable(index);
        vests[index].claimed += _claimable;
        IERC20(token).transfer(receiver, _claimable);
        emit Claimed(receiver, _claimable);
    }

    function claimAll() public {
        uint len = vests.length;
        for(uint i; i < len; ++i) {
            claim(i);
        }
    }

    function transferVest(address newReceiver) public {
        require(msg.sender == receiver);
        receiver = newReceiver;
        emit VestTransferred(msg.sender, newReceiver);
    }
}
