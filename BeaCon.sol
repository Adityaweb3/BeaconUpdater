// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/UpgradeableProxy.sol";

contract UniswapFuture {
    using SafeMath for uint256;
    address public owner;
    uint256 public limit;
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public balances;

    function setLimit(uint256 _maxBalance) external onlyWL {
      require(address(this).balance == 0, "Contract balance is not 0");
      limit = _maxBalance;
    }

    function initializeContract(uint256 _maxBalance) public {
        require(limit == 0, "Already initialized");
        limit = _maxBalance;
        owner = msg.sender;
    }

    modifier onlyWL {
        require(whitelisted[msg.sender], "Not WL");
        _;
    }

    function addEth() external payable onlyWL {
      require(address(this).balance <= limit, "Max balance reached");
      balances[msg.sender] = balances[msg.sender].add(msg.value);
    }

    function addToWL(address addr) external {
        require(msg.sender == owner, "Not the owner");
        whitelisted[addr] = true;
    }

    function execute(address to, uint256 value, bytes calldata data) external payable onlyWL {
        require(balances[msg.sender] >= value, "Insufficient balance");
        balances[msg.sender] = balances[msg.sender].sub(value);
        (bool success, ) = to.call{ value: value }(data);
        require(success, "failed");
    }

    function batchAll(bytes[] calldata data) external payable onlyWL {
        bool depositCalled = false;
        for (uint256 i = 0; i < data.length; i++) {
            bytes memory _data = data[i];
            bytes4 selector;
            assembly {
                selector := mload(add(_data, 32))
            }
            if (selector == this.addEth.selector) {
                require(!depositCalled, "addEth can only be called once");
                
                depositCalled = true;
            }
            (bool success, ) = address(this).delegatecall(data[i]);
            require(success, "Error");
        }
    }

    receive () external payable {}
}

contract Beacon is UpgradeableProxy {
    address public pendingBeacon;
    address public beacon;

    constructor(address _beacon, address _implementation, bytes memory _initData)public  UpgradeableProxy(_implementation, _initData) {
        beacon = _beacon;
    }

    modifier onlyBeacon {
      require(msg.sender == beacon, "Caller is not the admin");
      _;
    }

    function upgradeTo(address _newImplementation) external onlyBeacon {
        _upgradeTo(_newImplementation);
    }

    function proposeBeacon(address _newAdmin) external {
        pendingBeacon = _newAdmin;
        
    }

   function approveBeacon(address _expectedAdmin, address _newBeacon) external onlyBeacon {
    require(pendingBeacon == _expectedAdmin, "Expected new admin by the current admin is not the pending admin");
    beacon = _newBeacon;
}
}
