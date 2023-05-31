// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IVest.sol";

contract Migrator is Ownable {
    IERC20 public toBurn;
    IERC20 public asset;
    address public tokenVestImplementation;

    uint public rate;
    uint public constant basis = 10000;
    uint public totalSupply;
    uint public duration;

    mapping(address => address) vestPerUser; // Vesting address for a user

    event Burned(address indexed user, address indexed vesting, uint amount);

    constructor(
        address _implementation,
        address _toBurn,
        address _asset,
        uint _rate,
        uint _duration
    ) {
        tokenVestImplementation = _implementation;
        toBurn = IERC20(_toBurn);
        asset = IERC20(_asset);
        rate = _rate;
        duration = _duration;
    }

    /// @notice ie 1000 for 10%. For every 100 tokens burned, 10 is received.
    function setRate(uint _rate) public onlyOwner {
        rate = _rate;
    }

    function setDuration(uint _duration) public onlyOwner {
        duration = _duration;
    }

    function depositTokens(uint amount) public onlyOwner {
        asset.transferFrom(msg.sender, address(this), amount);
        totalSupply += amount;
    }

    function rugSupply(uint amount) public onlyOwner {
        asset.transfer(msg.sender, amount);
        totalSupply -= amount;
    }

    function burn(uint amount) public {
        uint toVest = Math.mulDiv(amount, rate, basis, Math.Rounding.Up);
        require(toVest <= totalSupply, "Insufficient Supply");
        IERC20(toBurn).transferFrom(msg.sender, address(this), amount);
        address vesting = vestPerUser[msg.sender];
        if (vesting == address(0)) {
            vesting = Clones.clone(tokenVestImplementation);
            asset.approve(vesting, type(uint).max);
            IMultiVests(vesting).initialize(
                address(this),
                address(asset),
                msg.sender
            );
            vestPerUser[msg.sender] = vesting;
        }
        IMultiVests(vesting).newVest(toVest, duration);
        totalSupply -= toVest;
        emit Burned(msg.sender, vesting, amount);
    }

    function createVestFor(
        address account,
        uint amount,
        uint _duration
    ) public onlyOwner {
        address vesting = vestPerUser[account];
        if (vesting == address(0)) {
            vesting = Clones.clone(tokenVestImplementation);
            asset.approve(vesting, type(uint).max);
            IMultiVests(vesting).initialize(
                address(this),
                address(asset),
                account
            );
            vestPerUser[account] = vesting;
        }
        IMultiVests(vesting).newVest(amount, _duration);
        totalSupply -= amount;
    }
}
