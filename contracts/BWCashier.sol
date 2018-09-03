pragma solidity 0.4.24;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import './BWManaged.sol';
import './BWResults.sol';


contract BWCashier is BWManaged {

    using SafeMath for uint256;

    BWResults public resultsContract;

    uint256 public proportionAbsMax; //max percentages value to divided ethers (default - 100 )
    //founders and team addresses
    address[6] public etherHolders;
    // value in percents for each  etherHolder
    uint256[6] public percentages;

    mapping(address => uint256) public balances;

    event LotteryTicketPurchased(address indexed contributor, uint256 gameTimestampedId);

    modifier indexMeetSpecifiedRange(uint256 _index) {
        require((_index >= 0 && _index < 6), ERROR_ACCESS_DENIED);
        _;
    }

    constructor(
        address _management,
        uint256 _proportionAbsMax,
        address[6] _etherHolders,
        uint256[6] _percentages
    ) public BWManaged(_management) {
        proportionAbsMax = _proportionAbsMax;
        for (uint256 i = 0; i < _etherHolders.length; i++) {
            require(_etherHolders[i] != address(0), ERROR_ACCESS_DENIED);
            etherHolders[i] = _etherHolders[i];
            percentages[i] = _percentages[i];
        }
    }

    function recordPurchase(
        uint256 _gameTimestampedId,
        address _contributor
    ) public payable requirePermission(CAN_RECORD_PURCHASE) requireContractExistsInRegistry(CONTRACT_RESULTS) returns (uint256) {
        emit LotteryTicketPurchased(_contributor, _gameTimestampedId);
        balances[_contributor] = balances[_contributor].add(msg.value);
        uint256 etherWithdrawed;
        for (uint256 i = 0; i < etherHolders.length; i++) {
            uint256 amount = msg.value.mul(percentages[i]).div(proportionAbsMax);
            etherWithdrawed = etherWithdrawed.add(amount);
            etherHolders[i].transfer(amount);
        }
        return msg.value.sub(etherWithdrawed);
    }

    function setGameBalance(uint256 _gameTimestampedId)
        public requireContractExistsInRegistry(CONTRACT_RESULTS)
        canCallOnlyRegisteredContract(CONTRACT_RANDOMIZER)
    {
        BWResults result = BWResults(management.contractRegistry(CONTRACT_RESULTS));
        result.defineGameBalance.value(address(this).balance)(_gameTimestampedId);
    }

    function updateEtherHolderAddress(uint256 _index, address _newAddress)
        public onlyOwner indexMeetSpecifiedRange(_index) {
        require(_newAddress != address(0), ERROR_ACCESS_DENIED);
        etherHolders[_index] = _newAddress;
    }

    function updateEtherHolderPercentages(uint256 _index, uint256 _newValue)
        public onlyOwner indexMeetSpecifiedRange(_index)
        requireNotContractSender() {
        require(_newValue <= proportionAbsMax, ERROR_ACCESS_DENIED);
        uint256 percentagesUsed;
        for (uint256 i = 0; i < percentages.length; i++) {
            if (i != _index) {
                percentagesUsed = percentagesUsed.add(percentages[i]);
            }
        }
        require(percentagesUsed.add(_newValue) <= proportionAbsMax, ERROR_WRONG_AMOUNT);
        percentages[_index] = _newValue;
    }
}