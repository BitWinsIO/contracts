pragma solidity 0.4.24;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import './BWManaged.sol';
import './BWResults.sol';


contract BWCashier is BWManaged {

    using SafeMath for uint256;

    BWResults public resultsContract;

    address[4] public etherHolders;
    uint256[4] public percentages;
//    mapping(address => uint256)[4] public etherHolders;
    mapping(address => uint256) public payoutBalances;

    mapping(address => uint256) public balances;

    event LotteryPurchased(
        address indexed contributor,
        uint256 gameId
    );
    event Claim(address account, uint256 value);


    constructor(address _management, address[4] _etherHolders, uint256[4] _percentages) public BWManaged(_management) {
        for (uint256 i = 0; i < _etherHolders.length; i++) {
            require(_etherHolders[i] != address(0), ACCESS_DENIED);
            etherHolders[i] = _etherHolders[i];
            percentages[i] = _percentages[i];
        }
    }

    function recordPurchase(
        uint256 _gameId,
        address _contributor
    ) public payable
    requirePermission(CAN_RECORD_PURCHASE)
    requireRegisteredContract(RESULTS) {
        emit LotteryPurchased(_contributor, _gameId);
        balances[_contributor] = balances[_contributor].add(msg.value);
        for (uint256 i = 0; i < etherHolders.length; i++) {
            payoutBalances[etherHolders[i]] = payoutBalances[etherHolders[i]].add(msg.value.mul(percentages[i]).div(100));
        }
    }

    function withdrawEthers() public {
        uint balance = payoutBalances[msg.sender];
        require(balance > 0 && address(this).balance >= balance);
        payoutBalances[msg.sender] = 0;
        msg.sender.transfer(balance);
    }
}