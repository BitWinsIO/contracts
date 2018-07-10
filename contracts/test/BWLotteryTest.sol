pragma solidity 0.4.24;

import '../BWLottery.sol';


contract BWLotteryTest is BWLottery {


    constructor(
        address _management,
        uint256 _initialJackpot,
        uint256 _firstGameStartAt
    ) public BWLottery(_management, _initialJackpot, _firstGameStartAt) {
    }


//    function setGameId(uint256 _time) public {
//        Game storage lottery = lotteries[activeGame];
//        activeGame = _time;
//        lotteries[_time] = lottery;
//    }

}