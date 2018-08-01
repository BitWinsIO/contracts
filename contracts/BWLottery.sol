pragma solidity 0.4.24;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import './BWManaged.sol';
import './BWCashier.sol';
import './BWCombinations.sol';
import './BWResults.sol';


contract BWLottery is BWManaged {

    using SafeMath for uint256;

    uint256 public prevGame;
    uint256 public activeGame;
    BWResults public resultContract;

    //timestamp => struct
    mapping(uint256 => Game) public lotteries;

    struct Game {
        uint256 collectedEthers;
        uint256 ticketsIssued;
        uint256 pb;
        uint256[5] resultBalls;
        uint256[7] resultCombinations;
        mapping(uint256 => Ticket) tickets;
        mapping(uint256 => uint256) results; //comination key =>[tiketsID/ count
        //
        mapping(uint256 => uint256) winnersPerLev;
        mapping(uint256 => uint256) ticketToKey;

    }
    event WinnerLogged(uint256 gameId, uint256 ticketId, uint256 prize);
    event TicketBought(uint256 gameId, uint256 ticketId, uint256[5] balls, uint256 pb);

    struct Ticket {
        uint256[5] balls;
        uint256 powerBall;
        address owner;
    }

    constructor(
        address _management,
        uint256 _firstGameStartAt
    ) public BWManaged(_management) {
        createGameInternal(_firstGameStartAt);
    }

    function purchase(uint256[5] _input, uint256 _powerBall) public payable requireRegisteredContract(CASHIER) {
        require(activeGame > 0, NO_ACTIVE_LOTTERY);
        require(!isContract(msg.sender), ACCESS_DENIED);
        require(block.timestamp <= activeGame.add(GAME_DURATION), ACCESS_DENIED);
        require(_input[0] >= MIN_NUMBER && _input[4] <= maxBall, WRONG_AMOUNT);
        require(_powerBall >= MIN_NUMBER && _powerBall <= maxPowerBall, WRONG_AMOUNT);

        Game storage lottery = lotteries[activeGame];

        require((ticketPrice <= msg.value), WRONG_AMOUNT);

        uint256 ticketId = lottery.ticketsIssued.add(1);
        lottery.ticketsIssued = ticketId;
        lottery.tickets[ticketId] = Ticket(_input, _powerBall, msg.sender);

        BWCombinations combination = BWCombinations(management.contractRegistry(COMBINATIONS));
        uint256[7] memory combinations = combination.calculateComb(_input, _powerBall);
        for (uint256 i = 0; i < _input.length; i++) {
            lottery.results[combinations[i]]++;
        }
        emit TicketBought(activeGame, ticketId, _input, _powerBall);
        BWCashier cashier = BWCashier(management.contractRegistry(CASHIER));
        uint256 leftForPrizes = cashier.recordPurchase.value(msg.value)(activeGame, msg.sender);
        lottery.collectedEthers = lottery.collectedEthers.add(leftForPrizes);
    }

    function setGameResult(uint256 _gameId, uint256[5] _input, uint256 _pb) public requireRegisteredContract(CASHIER) {
        require(activeGame > 0, ACCESS_DENIED);
        require(msg.sender == management.contractRegistry(RANDOMIZER), ACCESS_DENIED);
        require(_gameId.add(GAME_DURATION) <= block.timestamp, ACCESS_DENIED);
        require(_pb >= MIN_NUMBER && _pb <= maxPowerBall, WRONG_AMOUNT);
        require(_input[0] >= MIN_NUMBER && _input[4] <= maxBall, WRONG_AMOUNT);
        Game storage lottery = lotteries[_gameId];
        require(lottery.pb == 0, ACCESS_DENIED);
        lottery.resultBalls = _input;
        lottery.pb = _pb;
        BWCombinations combination = BWCombinations(management.contractRegistry(COMBINATIONS));
        lottery.resultCombinations = combination.calculateComb(_input, _pb);
        prevGame = _gameId;
        activeGame = 0;
//        if(autoStartNextGame){
//            createGameInternal(_startTime);
//        }
    }

    function setResultsContract(BWResults _results) onlyOwner {
        require(_results == management.contractRegistry(RESULTS), ACCESS_DENIED);
        resultContract = BWResults(_results);
    }

    function createGame(uint256 _startTime) public onlyOwner {
        createGameInternal(_startTime);
    }

    function saveClaim(uint256 _gameId, uint256 _category, uint256 _ticketId) public requireRegisteredContract(RESULTS) {
        require(_gameId != 0 && block.timestamp <= _gameId.add(14 days), ACCESS_DENIED);
        Game storage lottery = lotteries[_gameId];
        lottery.winnersPerLev[_category] = lottery.winnersPerLev[_category].add(1);
        lottery.ticketToKey[_ticketId] = _category;
        emit WinnerLogged(_gameId, _ticketId, _category);
    }

    function getGame(uint256 _time) public view returns (
        uint256 jp,
        uint256 collectedEthers,
        uint256 price,
        uint256 ticketsIssued,
        uint256 pb,
        uint256[5] resultBalls,
        uint256[7] resultCombinations
    ) {
        Game storage lottery = lotteries[_time];
        if (_time < activeGame) {
            jp = resultContract.gameBalances(_time).mul(resultContract.payoutsPerCategory(JACKPOT)).div(100);
        } else {
            jp = lottery.collectedEthers.mul(resultContract.payoutsPerCategory(JACKPOT)).div(100)
            .add(resultContract.collectedEthers().sub(resultContract.reservedAmount()));
        }
        collectedEthers = lottery.collectedEthers;
        price = ticketPrice;
        ticketsIssued= lottery.ticketsIssued;
        pb = lottery.pb;
        resultBalls = lottery.resultBalls;
        resultCombinations = lottery.resultCombinations;
    }

    function getGameReults(uint256 _time) public view returns (
        uint256[5] resultBalls,
        uint256 pb
    ) {
        Game memory lottery = lotteries[_time];
        resultBalls = lottery.resultBalls;
        pb = lottery.pb;
    }

    function getGameTicketById(uint256 _time, uint256 _ticketId) public view returns (
        uint256[5] balls,
        uint256 powerBall,
        address owner
    ) {
        Game storage lottery = lotteries[_time];
        Ticket memory ticket = lottery.tickets[_ticketId];
        balls = ticket.balls;
        powerBall = ticket.powerBall;
        owner = ticket.owner;
    }

    function getTicketOwnerById(uint256 _time, uint256 _ticketId) public view returns (
        address owner
    ) {
        Game storage lottery = lotteries[_time];
        Ticket memory ticket = lottery.tickets[_ticketId];
        owner = ticket.owner;
    }

    function getResultsByTicketId(uint256 _time, uint256 _ticketId) public view returns (uint256, uint256) {
        Game storage lottery = lotteries[_time];
        uint256 category = lottery.ticketToKey[_ticketId];
        return (lottery.winnersPerLev[category], category);
    }

    function markTickedAsClaimed(uint256 _time, uint256 _ticketId) public returns (uint256) {
        require(msg.sender == management.contractRegistry(RESULTS), ACCESS_DENIED);
        Game storage lottery = lotteries[_time];
        lottery.ticketToKey[_ticketId]= 0;
    }

    function createGameInternal(uint256 _startTime) internal {
        require(activeGame.add(GAME_DURATION) <= _startTime);
        uint256[5] memory tmp;
        uint256[7] memory tmp2;
        lotteries[_startTime] = Game(0, 0, 0, tmp, tmp2);
        if (prevGame > 0) {

        }
        activeGame = _startTime;
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}