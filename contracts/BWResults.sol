pragma solidity 0.4.24;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import './BWManaged.sol';
import './BWCashier.sol';
import './BWLottery.sol';


contract BWResults is BWManaged {
    using SafeMath for uint256;

    mapping(uint256 => uint256) public gameBalances;
    mapping(uint256 => bool[3]) public gameRezervedPrizes;
    uint256 public reservedAmount;
    uint256 public collectedEthers;

    event PrizeWithdrawn(uint256 ticketId, uint256 category, uint256 amount);
    event GameBalanceUpdated(uint256 _gameId, uint256 amount);

    constructor(address _management) public BWManaged(_management) {
    }

    //runs once in the moment of setting results
    function increaseGameBalance(uint256 _gameId) public payable requirePermission(CAN_INCREASE_GAME_BALANCE) {
        gameBalances[_gameId] = gameBalances[_gameId].add(msg.value).add(collectedEthers.sub(reservedAmount));
        collectedEthers = address(this).balance;
        emit GameBalanceUpdated(_gameId, gameBalances[_gameId]);
    }

    function getContractBalance() public view returns (uint256){
        return address(this).balance;
    }

    function calculateResult(
        uint256[5] _ticketBalls,
        uint256 _ticketPb,
        uint256[5] _balls,
        uint256 _pb
    ) public view returns (uint256 result){
        uint256 matches;
        bool powerball;
        for (uint256 i = 0; i < 5; i++) {
            for (uint256 j = 0; j < 5; j++) {
                if (_ticketBalls[j] == _balls[i]) {
                    matches = matches.add(1);
                }
            }
        }
        if (_ticketPb == _pb) {
            powerball = true;
        }
        if (matches == 4 && powerball == true) {
            result = FOUR_PB;
        } else if (matches == 5 && powerball == false) {
            result = FIVE;
        } else if (matches == 5 && powerball == true) {
            result = JACKPOT;
        }

    }

    function claim(uint256 _ticketId) public {
        BWLottery lottery = BWLottery(management.contractRegistry(LOTTERY));
        require(lottery.prevGame() != 0 && block.timestamp <= lottery.prevGame().add(14 days), ACCESS_DENIED);
        uint256[5] memory balls;
        uint256 pb;
        (balls, pb) = lottery.getGameReults(lottery.prevGame());
        uint256[5] memory ticketBalls;
        uint256 ticketPb;
        address ticketOwner;
        (ticketBalls, ticketPb, ticketOwner) = lottery.getGameTicketById(lottery.prevGame(), _ticketId);
        uint256 category = calculateResult(
            ticketBalls,
            ticketPb,
            balls,
            pb
        );
        if (false == gameRezervedPrizes[lottery.prevGame()][category.sub(1)]) {
            gameRezervedPrizes[lottery.prevGame()][category.sub(1)] = true;
            reservedAmount = reservedAmount.add(gameBalances[lottery.prevGame()].mul(payoutsPerCategory[category]).div(100));
        }
        lottery.saveClaim(lottery.prevGame(), category, _ticketId);
    }

    function withdrowPrize(uint256 _gameId, uint256 _ticketId) public {
        BWLottery lotteryContract = BWLottery(management.contractRegistry(LOTTERY));
        require(_gameId != 0 && block.timestamp >= _gameId.add(14 days), ACCESS_DENIED);

        uint256 winnersAmount;
        uint256 categoryId;
        (winnersAmount, categoryId) = lotteryContract.getResultsByTicketId(_gameId, _ticketId);
        lotteryContract.markTickedAsClaimed(_gameId, _ticketId);
        require(winnersAmount > 0);
        address owner = lotteryContract.getTicketOwnerById(_gameId, _ticketId);
        uint256 value =  gameBalances[_gameId].mul(payoutsPerCategory[categoryId]).div(100).div(winnersAmount);
        reservedAmount = reservedAmount.sub(value);
        collectedEthers = collectedEthers.sub(value);
        owner.transfer(value);
        emit PrizeWithdrawn(_ticketId, categoryId, value);
    }

}
