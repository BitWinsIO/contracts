pragma solidity 0.4.24;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import './BWManaged.sol';
import './BWResults.sol';


contract BWCashier is BWManaged {

    using SafeMath for uint256;

    BWResults public resultsContract;

    uint256 public proportionAbsMax;
    address[6] public etherHolders;
    uint256[6] public percentages;

    mapping(address => uint256) public balances;

    event LotteryPurchased(address indexed contributor, uint256 gameId);
    event Claim(address account, uint256 value);

    constructor(
        address _management,
        uint256 _proportionAbsMax,
        address[6] _etherHolders,
        uint256[6] _percentages
    ) public BWManaged(_management) {
        proportionAbsMax = _proportionAbsMax;
        for (uint256 i = 0; i < _etherHolders.length; i++) {
            require(_etherHolders[i] != address(0), ACCESS_DENIED);
            etherHolders[i] = _etherHolders[i];
            percentages[i] = _percentages[i];
        }
    }

    function recordPurchase(
        uint256 _gameId,
        address _contributor
    ) public payable requirePermission(CAN_RECORD_PURCHASE) requireRegisteredContract(RESULTS) returns (uint256) {
        emit LotteryPurchased(_contributor, _gameId);
        balances[_contributor] = balances[_contributor].add(msg.value);
        uint256 etherWithdrawed;
        for (uint256 i = 0; i < etherHolders.length; i++) {
            uint256 amount = msg.value.mul(percentages[i]).div(proportionAbsMax);
            etherWithdrawed = etherWithdrawed.add(amount);
            etherHolders[i].transfer(amount);
        }
        return msg.value.sub(etherWithdrawed);
    }

    function setGameBalance(uint256 _gameId) public requireRegisteredContract(RESULTS) {
        require(msg.sender == management.contractRegistry(RANDOMIZER), ACCESS_DENIED);
        BWResults result = BWResults(management.contractRegistry(RESULTS));
        result.increaseGameBalance.value(address(this).balance)(_gameId);
    }

    function updateEtherHolderAddress(uint256 _index, address _newAddress) public onlyOwner {
        require((_index >= 0 && _index < 6), ACCESS_DENIED);
        require(_newAddress != address(0), ACCESS_DENIED);
        etherHolders[_index] = _newAddress;
    }

    function updateEtherHolderPercentages(uint256 _index, uint256 _newValue) public onlyOwner {
        require((_index >= 0 && _index < 6), ACCESS_DENIED);
        require(_newValue <= proportionAbsMax, ACCESS_DENIED);
        uint256 percentagesUsed;
        for (uint256 i = 0; i < percentages.length; i++) {
            if (i != _index) {
                percentagesUsed = percentagesUsed.add(percentages[i]);
            }
        }
        require(percentagesUsed.add(_newValue) <= proportionAbsMax, WRONG_AMOUNT);
        percentages[_index] = _newValue;
    }
}