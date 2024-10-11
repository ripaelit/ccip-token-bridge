// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/utils/SafeERC20.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */
contract EarningContract is OwnerIsCreator, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event Deposit(address indexed dst, uint wad);

    mapping (address => uint) public balanceOf;
    uint256 public treasury;
    uint256 public totalClaimed;
    uint256 public totalUnclaimed;
    uint256 public previousDepositTime;
    uint256 public previousDepositAmount;
    uint256 public lastDepositTime;
    uint256 public lastDepositAmount;
    uint256 public totalDeposited;

    constructor() {
    }

    receive() external payable {}

    function deposit() public payable {
        previousDepositTime = lastDepositTime;
        previousDepositAmount = lastDepositAmount;
        lastDepositTime = block.timestamp;
        lastDepositAmount = msg.value;
        totalDeposited += msg.value;
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
}
