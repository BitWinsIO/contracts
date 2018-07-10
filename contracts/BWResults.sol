pragma solidity 0.4.24;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import './BWManaged.sol';
import './BWCashier.sol';
import './BWLottery.sol';


contract BWResults is BWManaged {
    using SafeMath for uint256;

    event Debug(string _s, uint _i);

    constructor(address _management) public BWManaged(_management) {
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
        address owner;
        (ticketBalls, ticketPb, owner) = lottery.getGameTicketById(lottery.prevGame(), _ticketId);
        uint256 category = calculateResult(
            ticketBalls,
            ticketPb,
            balls,
            pb
        );
        lottery.saveClaim(lottery.prevGame(), category, _ticketId);
    }

    function withdrowPrize(uint256 _gameId, uint256 _ticketId) public {
        BWLottery lotteryContract = BWLottery(management.contractRegistry(LOTTERY));
//        require(_gameId != 0 && block.timestamp >= _gameId.add(14 days), ACCESS_DENIED);
        uint256 winnersAmount = lotteryContract.getResultsByTicketId(_gameId, _ticketId);
        lotteryContract.markTickedAsClaimed(_gameId, _ticketId);
        require(winnersAmount > 0);

//        lottery.ticketToKey[_ticketId] = 0;
//        uint valuePerCategory;
        //@todo  adds immplementation
//        valuePerCategory.div(winnersAmount);
    }

}
