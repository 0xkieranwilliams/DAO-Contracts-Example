// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";

import {MyGovernor} from "src/MyGovernor.sol";
import {GovToken} from "src/GovToken.sol";
import {TimeLock} from "src/TimeLock.sol";
import {Box} from "src/Box.sol";

contract MyGovernorTest is Test {
  MyGovernor governor;
  GovToken govToken;
  TimeLock timelock;
  Box box;

  address public USER = makeAddr("user");
  uint256 public constant INITIAL_SUPPLY = 100 ether;
  uint256 constant MIN_DELAY = 3600; // 1 hour after a vote passes

  address[] proposers;
  address[] executors;

  function setUp() public {
    govToken = new GovToken(address(this));
    govToken.mint(USER, INITIAL_SUPPLY); 

    vm.startPrank(USER);
    govToken.delegate(USER); 
    timelock = new TimeLock(MIN_DELAY, proposers, executors);
    governor = new MyGovernor(govToken, timelock);

    bytes32 proposerRole = timelock.PROPOSER_ROLE();
    bytes32 executorRole = timelock.EXECUTOR_ROLE();
    // bytes32 adminRole = timelock.TIMELOCK_ADMIN_ROLE();

    timelock.grantRole(proposerRole, address(governor));
    timelock.grantRole(executorRole, address(0));
    // timelock.revokeRole(adminRole, USER);
    vm.stopPrank();

    box = new Box();
    box.transferOwnership(address(timelock));
  }

  function testCantUpdateBoxWithoutGovernance() public {
    vm.expectRevert();
    box.store(1);
  }

  function testGovernanceUpdatesBox() public {

  }
}
