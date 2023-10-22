// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract PensionDAOFactory {

  struct PensionDAO {
    string name;
    address creator;
    mapping(address => uint) balances;
    address[] members;
  }

  mapping(string => PensionDAO) public daos;
  string[] public activePensionSchemes; // New storage for active pension scheme names

  uint256 constant public FIXED_DEPOSIT_AMOUNT = 1000000000000000; 

  function createPensionDAO(string memory name) public {
    require(bytes(daos[name].name).length == 0, "DAO already exists");

    PensionDAO storage dao = daos[name];
    dao.name = name;
    dao.creator = msg.sender;
    activePensionSchemes.push(name); // Add the name to the list of active pension schemes
  }

  function joinPensionDAO(string memory name) public payable {
    PensionDAO storage dao = daos[name];
    require(bytes(dao.name).length > 0, "DAO does not exist");
    require(msg.sender != dao.creator, "Creator cannot join the DAO");

    dao.balances[msg.sender] += msg.value;
    dao.members.push(msg.sender);
  }

  function depositToPension(string memory name) public payable {
    PensionDAO storage dao = daos[name];
    require(bytes(dao.name).length > 0, "DAO does not exist");
    require(msg.value == FIXED_DEPOSIT_AMOUNT, "Sent value does not match the fixed deposit amount");

    dao.balances[msg.sender] += msg.value;
  }

  function withdrawPension(string memory name) public {
    PensionDAO storage dao = daos[name];
    require(bytes(dao.name).length > 0, "DAO does not exist");

    uint totalBalance = getTotalBalance(name);
    require(totalBalance > 0, "No funds to withdraw");

    uint amountToDistribute = dao.balances[address(this)];
    require(amountToDistribute > 0, "No matched funds available");

    // Distribute the matched funds equally among all members
    for (uint i = 0; i < dao.members.length; i++) {
      address member = dao.members[i];
      uint memberBalance = dao.balances[member];
      uint share = (amountToDistribute * memberBalance) / totalBalance;
      dao.balances[member] += share;
    }

    // Reset the matched funds in the DAO to zero
    dao.balances[address(this)] = 0;
  }

  function getMemberBalances(string memory name) public view returns (address[] memory, uint[] memory) {
    PensionDAO storage dao = daos[name];
    require(msg.sender == dao.creator, "Only owner can view balances");

    uint numMembers = dao.members.length;
    address[] memory members = new address[](numMembers);
    uint[] memory balances = new uint[](numMembers);

    for (uint i = 0; i < numMembers; i++) {
      address member = dao.members[i];
      members[i] = member;
      balances[i] = dao.balances[member];
    }

    return (members, balances);
  }

  function getMyBalance(string memory name) public view returns (uint) {
    PensionDAO storage dao = daos[name];

    return dao.balances[msg.sender];
  }

  function getTotalBalance(string memory name) public view returns (uint) {
    PensionDAO storage dao = daos[name];
    require(msg.sender == dao.creator, "Only owner can view total balance");

    uint total = 0;
    for (uint i = 0; i < dao.members.length; i++) {
      total += dao.balances[dao.members[i]];
    }

    return total;
  }

  function matchTotalContribution(string memory name) public payable {
    PensionDAO storage dao = daos[name];
    require(dao.creator == msg.sender, "Only creator can match contributions");

    // Calculate the total balance of all members
    uint totalBalance = getTotalBalance(name);

    require(totalBalance > 0, "No funds to match");

    // Calculate the matching amount by the creator
    uint matchAmount = msg.value;

    // Add the matching amount to the DAO's balance
    dao.balances[address(this)] += matchAmount;

    // Distribute the matched amount equally among all members
    for (uint i = 0; i < dao.members.length; i++) {
      address member = dao.members[i];
      uint memberBalance = dao.balances[member];
      uint share = (matchAmount * memberBalance) / totalBalance;
      dao.balances[member] += share;
    }
  }

  // New function to get the list of active pension scheme names
  function getActivePensionSchemes() public view returns (string[] memory) {
    return activePensionSchemes;
}

}
