pragma solidity 0.4.24;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import './BWConstants.sol';
import './BWManagement.sol';


contract BWManaged is Ownable, BWConstants {

    BWManagement public management;

    modifier requirePermission(uint8 _permissionBit) {
        require(hasPermission(msg.sender, _permissionBit), ACCESS_DENIED);
        _;
    }

    modifier onlyRegistered(uint256 _key) {
        require(msg.sender == management.contractRegistry(_key), ACCESS_DENIED);
        _;
    }

    modifier requireRegisteredContract(uint256 _key) {
        require(management.contractRegistry(_key) != address(0), NO_CONTRACT);
        _;
    }

    constructor(address managementAddress) public {
        management = BWManagement(managementAddress);
    }

    function setManagementContract(address _management) public onlyOwner {
        require(address(0) != _management);

        management = BWManagement(_management);
    }

    function hasPermission(address _subject, uint256 _permissionBit) internal view returns(bool) {
        return management.permissions(_subject, _permissionBit);
    }
}