pragma solidity 0.4.24;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';


contract BWManagement is Ownable {

    // Contract Registry
    mapping(uint => address) public contractRegistry;

    // Permissions
    mapping(address => mapping(uint => bool)) public permissions;

    event PermissionsSet(address subject, uint permission, bool value);

    event ContractRegistered(uint key, address target);

    function setPermission(address _address, uint _permission, bool _value) public onlyOwner {
        permissions[_address][_permission] = _value;

        emit PermissionsSet(_address, _permission, _value);
    }

    function registerContract(uint _key, address _target) public onlyOwner {
        contractRegistry[_key] = _target;

        emit ContractRegistered(_key, _target);
    }

}