pragma solidity 0.4.24;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import './BWConstants.sol';
import './BWManagement.sol';


contract BWManaged is Ownable, BWConstants {

    BWManagement public management;

    bool public autoStartNextGame = true;

    event PriceUpdated(uint256 oldPrice, uint256 newPrice);

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

    function setNewPrice(uint256 _newPrice) public onlyOwner {
        require(_newPrice > 0);
        emit PriceUpdated(ticketPrice,_newPrice);
        ticketPrice = _newPrice;
    }

    function setMaxBall(uint256 _newVal) public onlyOwner {
        require(_newVal > MIN_NUMBER);
        maxBall = _newVal;
    }

    function setMaxPowerBall(uint256 _newVal) public onlyOwner {
        require(_newVal > MIN_NUMBER);
        maxPowerBall = _newVal;
    }

    function setAutoStartNextGame(bool _newVal) public onlyOwner {
        autoStartNextGame = _newVal;
    }

}