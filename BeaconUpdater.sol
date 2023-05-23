pragma solidity ^0.6.0;

contract BeaconUpdater {
    address public beaconContract;
    address public newBeaconAddress;

    constructor(address _beaconContract, address _newBeaconAddress) public {
        beaconContract = _beaconContract;
        newBeaconAddress = _newBeaconAddress;
    }

    function updateBeacon() external {
        bytes4 selector = bytes4(keccak256("approveBeacon(address,address)"));
        bytes memory data = abi.encodeWithSelector(selector, address(this), newBeaconAddress);

        // Use delegate call to update the beacon address
        (bool success, ) = beaconContract.delegatecall(data);
        require(success, "Beacon update failed");
    }
}
