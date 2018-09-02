pragma solidity 0.4.24;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import './BWConstants.sol';

contract BWManagement is Ownable, BWConstants {

    //autostart new game when owner sets results
    bool public autoStartNextGame = true;

    uint256 public ticketPrice = 0.0025 ether;
    uint256 public maxBallNumber = 69;
    uint256 public maxPowerBall = 26;
    mapping(uint256 => uint256) public payoutsPerCategory;

    // Contract Registry
    mapping(uint256 => address) public contractRegistry;

    // Permissions
    mapping(address => mapping(uint256 => bool)) public permissions;

    event PriceUpdated(uint256 oldPrice, uint256 newPrice);

    event PermissionsSet(address subject, uint256 permission, bool value);

    event ContractRegistered(uint256 key, address target);

    constructor() public {
        payoutsPerCategory[JACKPOT] = 80;
        payoutsPerCategory[FIVE] = 15;
        payoutsPerCategory[FOUR_PB] = 5;
    }

    function setPermission(address _address, uint256 _permission, bool _value) public onlyOwner {
        permissions[_address][_permission] = _value;

        emit PermissionsSet(_address, _permission, _value);
    }

    function registerContract(uint256 _key, address _target) public onlyOwner {
        contractRegistry[_key] = _target;

        emit ContractRegistered(_key, _target);
    }

    function setNewPrice(uint256 _newPrice) public onlyOwner {
        require(_newPrice > 0);
        emit PriceUpdated(ticketPrice, _newPrice);
        ticketPrice = _newPrice;
    }

    function setMaxBall(uint256 _newVal) public onlyOwner {
        require(_newVal > MIN_NUMBER, ERROR_WRONG_AMOUNT);
        maxBallNumber = _newVal;
    }

    function setMaxPowerBall(uint256 _newVal) public onlyOwner {
        require(_newVal > MIN_NUMBER, ERROR_WRONG_AMOUNT);
        maxPowerBall = _newVal;
    }

    function setAutoStartNextGame(bool _newVal) public onlyOwner {
        autoStartNextGame = _newVal;
    }

    function setPayoutsPerCategory(uint256 _categoryId, uint256 _value) public onlyOwner {
        require(_value <= 100, ERROR_WRONG_AMOUNT);
        payoutsPerCategory[_categoryId] = _value;
    }

}