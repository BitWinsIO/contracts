pragma solidity 0.4.24;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './BWManaged.sol';
import './BWResults.sol';


contract BWCashier is BWManaged {

    using SafeMath for uint256;

    BWResults public resultsContract;

    address public etherHolder;
    uint256 public allocatedEther;
    mapping(address => uint256) public payoutBalances;

    mapping(address => uint256) public balances;

    event LotteryPurchased(
        address indexed contributor,
        uint256 gameId
    );
    event Claim(address account, uint256 value);


    constructor(address _management, address _etherHolder) public BWManaged(_management) {
        require(etherHolder != address(0), ACCESS_DENIED);
        etherHolder = _etherHolder;
    }

    function claim() public {
        uint balance = payoutBalances[msg.sender];

        require(balance > 0);

        allocatedEther = allocatedEther.sub(balance);
        payoutBalances[msg.sender] = 0;
        msg.sender.transfer(balance);

        emit Claim(msg.sender, balance);
    }

    function recordPurchase(
        uint256 _gameId,
        address _contributor
    ) public payable
    requirePermission(CAN_RECORD_PURCHASE)
    requireRegisteredContract(RESULTS) {
        emit LotteryPurchased(_contributor, _gameId);
        balances[_contributor] = balances[_contributor].add(msg.value);
    }

    function setEtherHolder(address _etherHolder) public onlyOwner {
        require(_etherHolder != address(0), ACCESS_DENIED);

        etherHolder = _etherHolder;
    }

    function withdrawEthers() public {
        require(msg.sender == etherHolder, ACCESS_DENIED);

        etherHolder.transfer(address(this).balance.sub(allocatedEther));
    }
}