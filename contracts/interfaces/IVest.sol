// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMultiVests {
    function initialize(address _admin, address _token, address _receiver) external;
    function newVest(uint _amount, uint _duration) external;
}