// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Box is Ownable {
  uint256 private s_number; 

  event NumberChanged(uint256);


  constructor() Ownable(msg.sender){ }
  
  function store(uint256 newNumber) public onlyOwner {
    s_number = newNumber;
    emit NumberChanged(newNumber);
  }

  function readNumber() public view onlyOwner returns (uint256){
    return s_number;
  }
}
