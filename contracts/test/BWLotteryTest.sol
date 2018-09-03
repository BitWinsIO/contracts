pragma solidity 0.4.24;

import '../BWLottery.sol';


contract BWLotteryTest is BWLottery {


    constructor(
        address _management,
        uint256 _firstGameStartAt
    ) public BWLottery(_management, _firstGameStartAt) {
    }


    function setGameResult(uint256 _gameTimestampedId, uint256[5] _input, uint256 _powerBall)
        public requireContractExistsInRegistry(CONTRACT_CASHIER)
        canCallOnlyRegisteredContract(CONTRACT_RANDOMIZER) {
        require(activeGame > 0, ERROR_ACCESS_DENIED);
//        require(_gameTimestampedId.add(GAME_DURATION) <= block.timestamp, ERROR_ACCESS_DENIED);
        require(_powerBall >= MIN_NUMBER && _powerBall <= management.maxPowerBall(), ERROR_WRONG_AMOUNT);

        BWRandomizer(management.contractRegistry(CONTRACT_RANDOMIZER)).insertionSortMemory(_input);
        require(_input[0] >= MIN_NUMBER && _input[4] <= management.maxBallNumber(), ERROR_WRONG_AMOUNT);
        Game storage game = games[_gameTimestampedId];
        require(game.powerBall == 0, ERROR_ACCESS_DENIED);
        game.resultBalls = _input;
        game.powerBall = _powerBall;
        prevGame = _gameTimestampedId;
        activeGame = 0;
        if (management.autoStartNextGame()) {
            createGameInternal(block.timestamp);
        }
    }
}