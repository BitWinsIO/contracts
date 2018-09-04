pragma solidity 0.4.24;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import './BWManaged.sol';
import './BWCashier.sol';
import './BWLottery.sol';


contract BWResults is BWManaged {
    using SafeMath for uint256;

    mapping(uint256 => uint256) public gameBalances;
    mapping(uint256 => bool[3]) public gameReservedPrizes;
    uint256 public reservedAmount;
    uint256 public collectedEthers;

    event PrizeWithdrawn(uint256 ticketId, uint256 category, uint256 amount);
    event GameBalanceUpdated(uint256 _gameTimestampedId, uint256 amount);

    constructor(address _management) public BWManaged(_management) {
    }

    //runs once in the moment of setting results
    function defineGameBalance(uint256 _gameTimestampedId) public payable requirePermission(CAN_INCREASE_GAME_BALANCE) {
        require(gameBalances[_gameTimestampedId] == 0);
        collectedEthers = address(this).balance;
        gameBalances[_gameTimestampedId] = collectedEthers.sub(reservedAmount);
        emit GameBalanceUpdated(_gameTimestampedId, gameBalances[_gameTimestampedId]);
    }

    function calculateResult(
        uint256[5] _ticketBalls,
        uint256 _ticketPb,
        uint256[5] _winingBalls,
        uint256 _winingPowerBall
    ) public pure returns (uint256 category) {
        uint256 matches;
        bool powerball;
        for (uint256 i = 0; i < 5; i++) {
            for (uint256 j = 0; j < 5; j++) {
                if (_ticketBalls[j] == _winingBalls[i]) {
                    matches = matches.add(1);
                }
            }
        }
        if (_ticketPb == _winingPowerBall) {
            powerball = true;
        }
        if (matches == 4 && powerball == true) {
            category = FOUR_PB;
        } else if (matches == 5 && powerball == false) {
            category = FIVE;
        } else if (matches == 5 && powerball == true) {
            category = JACKPOT;
        }

    }

    function claim(uint256 _ticketId) public {
        BWLottery lottery = BWLottery(management.contractRegistry(CONTRACT_LOTTERY));
        require(lottery.prevGame() != 0 && block.timestamp <= lottery.prevGame().add(TIME_TO_CHECK_TICKET), ERROR_ACCESS_DENIED);
        uint256[5] memory balls;
        uint256 powerBall;
        (balls, powerBall) = lottery.getGameResults(lottery.prevGame());
        uint256[5] memory ticketBalls;
        uint256 ticketPb;
        address ticketOwner;
        (ticketBalls, ticketPb, ticketOwner) = lottery.getGameTicketById(lottery.prevGame(), _ticketId);
        uint256 category = calculateResult(
            ticketBalls,
            ticketPb,
            balls,
            powerBall
        );
        require(category > 0, ERROR_NOT_AVAILABLE);
        if (false == gameReservedPrizes[lottery.prevGame()][category.sub(1)]) {
            gameReservedPrizes[lottery.prevGame()][category.sub(1)] = true;
            reservedAmount = reservedAmount.add(gameBalances[lottery.prevGame()].mul(management.payoutsPerCategory(category)).div(100));
        }
        lottery.saveClaim(lottery.prevGame(), category, _ticketId);
    }

    function withdrawPrize(uint256 _gameTimestampedId, uint256 _ticketId) public {
        BWLottery lotteryContract = BWLottery(management.contractRegistry(CONTRACT_LOTTERY));
        require(_gameTimestampedId != 0 && block.timestamp >= _gameTimestampedId.add(TIME_TO_CHECK_TICKET), ERROR_ACCESS_DENIED);
        require(block.timestamp <= _gameTimestampedId.add(TIME_TO_CHECK_TICKET).add(TIME_TO_CLAIM_PRIZE), ERROR_ACCESS_DENIED);

        uint256 winnersAmount;
        uint256 categoryId;
        (winnersAmount, categoryId) = lotteryContract.getResultsByTicketId(_gameTimestampedId, _ticketId);
        lotteryContract.markTicketAsWithdrawn(_gameTimestampedId, _ticketId);
        require(winnersAmount > 0, ERROR_NOT_AVAILABLE);
        address ticketOwner = lotteryContract.getTicketOwnerById(_gameTimestampedId, _ticketId);
        uint256 value = gameBalances[_gameTimestampedId].mul(management.payoutsPerCategory(categoryId)).div(100).div(winnersAmount);
        reservedAmount = reservedAmount.sub(value);
        collectedEthers = collectedEthers.sub(value);
        ticketOwner.transfer(value);
        emit PrizeWithdrawn(_ticketId, categoryId, value);
    }

}
