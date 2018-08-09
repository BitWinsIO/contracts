pragma solidity 0.4.24;

import '../BWLottery.sol';


contract BWLotteryTest is BWLottery {


    constructor(
        address _management,
        uint256 _firstGameStartAt
    ) public BWLottery(_management, _firstGameStartAt) {
    }


    function setGameResult(uint256 _gameId, uint256[5] _input, uint256 _pb) public requireRegisteredContract(CASHIER) {
        require(activeGame > 0, ACCESS_DENIED);
        require(msg.sender == management.contractRegistry(RANDOMIZER), ACCESS_DENIED);
//        require(_gameId.add(GAME_DURATION) <= block.timestamp, ACCESS_DENIED);
        require(_pb >= MIN_NUMBER && _pb <= management.maxPowerBall(), WRONG_AMOUNT);
        require(_input[0] >= MIN_NUMBER && _input[4] <= management.maxBall(), WRONG_AMOUNT);
        Game storage lottery = lotteries[_gameId];
        require(lottery.pb == 0, ACCESS_DENIED);
        lottery.resultBalls = _input;
        lottery.pb = _pb;
        BWCombinations combination = BWCombinations(management.contractRegistry(COMBINATIONS));
        lottery.resultCombinations = combination.calculateComb(_input, _pb);
        prevGame = _gameId;
        activeGame = 0;
        if(management.autoStartNextGame()){
            createGameInternal(block.timestamp);
        }
    }
}