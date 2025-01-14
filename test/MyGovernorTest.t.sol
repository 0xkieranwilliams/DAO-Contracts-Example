// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";

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
  uint256 public constant MIN_DELAY = 3600; // 1 hour after a vote passes
  uint256 public constant VOTING_DELAY = 1; // how many votes will a vote be active
  uint256 public constant VOTING_PERIOD = 50400;

  address[] proposers;
  address[] executors;
  uint256[] values;
  bytes[] calldatas;
  address[] targets;


  function setUp() public {
    govToken = new GovToken(address(this));
    govToken.mint(USER, INITIAL_SUPPLY); 

    vm.startPrank(USER);
    govToken.delegate(USER); 

    require(govToken.getVotes(USER) > 0, "User has no voting power");
    
    timelock = new TimeLock(MIN_DELAY, proposers, executors);
    governor = new MyGovernor(govToken, timelock);

    console.log("timelock", governor.timelock());

    bytes32 proposerRole = timelock.PROPOSER_ROLE();
    bytes32 executorRole = timelock.EXECUTOR_ROLE();
    bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();

    timelock.grantRole(proposerRole, address(governor));
    timelock.grantRole(executorRole, address(0));

    timelock.revokeRole(adminRole, USER);
    vm.stopPrank();

    box = new Box();
    box.transferOwnership(address(timelock));
  }

  function testCantUpdateBoxWithoutGovernance() public {
    vm.expectRevert();
    box.store(1);
  }

  function testGovernanceUpdatesBox() public {
    uint256 valueToStore = 888;
    string memory description = "store what number in the Box?";
    bytes memory encodedFunctionCall = abi.encodeWithSignature("store(uint256)", valueToStore);
    values.push(0); 
    calldatas.push(encodedFunctionCall);
    targets.push(address(box));

    // 1. Propose to the DAO
    uint256 proposalId = governor.propose(targets, values, calldatas, description);   

    console.log("Proposal id: ", proposalId);
    console.log("Proposal State: ", uint256(governor.state(proposalId)));


    vm.roll(block.number + VOTING_DELAY + 10000);
    vm.warp(block.timestamp + VOTING_DELAY * 12000);

    console.log("Proposal State: ", uint256(governor.state(proposalId)));
    
    // 2. Vote
    string memory reason = "I want it";
    uint8 voteDecision = 1; // voting yes
    vm.prank(USER);
    governor.castVoteWithReason(proposalId, voteDecision, reason);


    vm.roll(block.number + VOTING_PERIOD + 1);
    vm.warp(block.timestamp + VOTING_PERIOD * 12);

    console.log("Proposal State: ", uint256(governor.state(proposalId)));

    // 3. Queue the TX
    bytes32 descriptionHash = keccak256(abi.encodePacked(description));
    governor.queue(targets,values, calldatas, descriptionHash);

    vm.roll(block.number + MIN_DELAY + 1);
    vm.warp(block.timestamp + MIN_DELAY * 12);

    console.log("box owner", box.owner());
    console.log("timelock", address(timelock));
    console.log("governor", address(governor));

    // 4. Execute
    governor.execute(targets, values, calldatas, descriptionHash);

    assert(box.readNumber() == valueToStore);
    console.log("Proposal State: ", uint256(governor.state(proposalId)));
    console.log("Box value: ", box.readNumber());
  }
}

