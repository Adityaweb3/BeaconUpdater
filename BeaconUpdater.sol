pragma solidity ^0.6.0 ;

contract BeaconUpdater {
    address public beaconContract;
    address public newBeaconAddress;

    bool public beaconUpdateProposed;
    bool public beaconUpdateApproved;

    constructor(address _beaconContract, address _newBeaconAddress) public {
        beaconContract = _beaconContract;
        newBeaconAddress = _newBeaconAddress;
    }

    function proposeBeaconUpdate() external {
        require(!beaconUpdateProposed, "Beacon update already proposed");
        Beacon(beaconContract).proposeBeacon(address(this));
        beaconUpdateProposed = true;
    }

    function approveBeaconUpdate() external {
        require(beaconUpdateProposed, "Beacon update not yet proposed");
        Beacon(beaconContract).approveBeacon(address(this), newBeaconAddress);
        beaconUpdateApproved = true;
    }

    function executeBeaconUpdate() external {
        require(beaconUpdateApproved, "Beacon update not yet approved");
        Beacon(beaconContract).approveBeacon(address(this), newBeaconAddress);
    }
}

interface Beacon {
    function proposeBeacon(address _newAdmin) external;
    function approveBeacon(address _expectedAdmin, address _newBeacon) external;
}
