pragma solidity 0.4.24;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import './BWConstants.sol';
import './BWManagement.sol';


contract BWManaged is Ownable, BWConstants {

    BWManagement public management;

    modifier requirePermission(uint256 _permissionBit) {
        require(hasPermission(msg.sender, _permissionBit), ERROR_ACCESS_DENIED);
        _;
    }

    modifier canCallOnlyRegisteredContract(uint256 _key) {
        require(msg.sender == management.contractRegistry(_key), ERROR_ACCESS_DENIED);
        _;
    }

    modifier requireContractExistsInRegistry(uint256 _key) {
        require(management.contractRegistry(_key) != address(0), ERROR_NO_CONTRACT);
        _;
    }

    modifier requireNotContractSender() {
        require(isContract(msg.sender) == false, ERROR_ACCESS_DENIED);
        _;
    }

    constructor(address _managementAddress) public {
        management = BWManagement(_managementAddress);
    }

    function setManagementContract(address _management) public onlyOwner {
        require(address(0) != _management);

        management = BWManagement(_management);
    }

    function insertionSortMemory(uint256[5] a) public pure returns (uint256[5]) {
        for (uint256 i = 0; i < a.length; i++) {
            uint256 j = i;
            while (j > 0 && a[j] < a[j - 1]) {
                uint256 temp = a[j];
                a[j] = a[j - 1];
                a[j - 1] = temp;
                j--;
            }
        }
        return a;
    }

    function hasPermission(address _subject, uint256 _permissionBit) internal view returns (bool) {
        return management.permissions(_subject, _permissionBit);
    }

    function isContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}