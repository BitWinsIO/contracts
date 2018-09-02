pragma solidity 0.4.24;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import './BWManaged.sol';
import './BWCashier.sol';
import './BWResults.sol';
import './BWRandomizer.sol';


contract BWLottery is BWManaged {

    using SafeMath for uint256;

    uint256 public prevGame;
    uint256 public activeGame;

    //timestamp => struct
    mapping(uint256 => Game) public games;

    struct Game {
        uint256 collectedEthers;
        uint256 ticketsIssued;
        uint256 powerBall;
        uint256[5] resultBalls;
        mapping(uint256 => Ticket) tickets;
        mapping(uint256 => uint256) results; //comination CategoryKey =>[tikets count
        //
        mapping(uint256 => uint256) winersCounsPerCategory;
        mapping(uint256 => uint256) ticketsToCategories;

    }

    event WinnerLogged(uint256 gameTimestampedId, uint256 ticketId, uint256 prize);
    event TicketBought(
        uint256 gameTimestampedId,
        uint256 ticketId,
        address ticketOwner,
        uint256[5] balls,
        uint256 powerBall
    );

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

    function purchase(uint256[5] _input, uint256 _powerBall)
        public payable requireContractExistsInRegistry(CONTRACT_CASHIER) {

        require(activeGame > 0, ERROR_NO_ACTIVE_LOTTERY);
        require(!isContract(msg.sender), ERROR_ACCESS_DENIED);
        require(block.timestamp <= activeGame.add(GAME_DURATION), ERROR_ACCESS_DENIED);
        require(_powerBall >= MIN_NUMBER && _powerBall <= management.maxPowerBall(), ERROR_WRONG_AMOUNT);

        BWRandomizer(management.contractRegistry(CONTRACT_RANDOMIZER)).insertionSortMemory(_input);
        require(_input[0] >= MIN_NUMBER && _input[4] <= management.maxBallNumber(), ERROR_WRONG_AMOUNT);

        Game storage game = games[activeGame];

        require((management.ticketPrice() == msg.value), ERROR_WRONG_AMOUNT);

        uint256 ticketId = game.ticketsIssued.add(1);
        game.ticketsIssued = ticketId;
        game.tickets[ticketId] = Ticket(_input, _powerBall, msg.sender);

        emit TicketBought(activeGame, ticketId, msg.sender, _input, _powerBall);
        BWCashier cashier = BWCashier(management.contractRegistry(CONTRACT_CASHIER));
        uint256 leftForPrizes = cashier.recordPurchase.value(msg.value)(activeGame, msg.sender);
        game.collectedEthers = game.collectedEthers.add(leftForPrizes);
    }

    function setGameResult(uint256 _gameTimestampedId, uint256[5] _input, uint256 _powerBall)
        public requireContractExistsInRegistry(CONTRACT_CASHIER)
        canCallOnlyRegisteredContract(CONTRACT_RANDOMIZER) {
        require(activeGame > 0, ERROR_ACCESS_DENIED);
        require(_gameTimestampedId.add(GAME_DURATION) <= block.timestamp, ERROR_ACCESS_DENIED);
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

    function createGame(uint256 _startTime) public onlyOwner {
        createGameInternal(_startTime);
    }

    function saveClaim(uint256 _gameTimestampedId, uint256 _category, uint256 _ticketId)
        public requireContractExistsInRegistry(CONTRACT_RESULTS)
        canCallOnlyRegisteredContract(CONTRACT_RESULTS) {
        require(_gameTimestampedId != 0 && block.timestamp <= _gameTimestampedId.add(TIME_TO_CHECK_TICKET), ERROR_ACCESS_DENIED);
        Game storage game = games[_gameTimestampedId];
        require(game.ticketsToCategories[_ticketId] == 0, ERROR_ACCESS_DENIED);
        game.winersCounsPerCategory[_category] = game.winersCounsPerCategory[_category].add(1);
        game.ticketsToCategories[_ticketId] = _category;

        emit WinnerLogged(_gameTimestampedId, _ticketId, _category);
    }

    function getGame(uint256 _gameTimestampedId) public view returns (
        uint256 jp,
        uint256 collectedEthers,
        uint256 price,
        uint256 ticketsIssued,
        uint256 powerBall,
        uint256[5] resultBalls
    ) {
        Game storage game = games[_gameTimestampedId];
        BWResults resultContract = BWResults(management.contractRegistry(CONTRACT_RESULTS));
        if (_gameTimestampedId < activeGame) {
            jp = resultContract.gameBalances(_gameTimestampedId).mul(management.payoutsPerCategory(JACKPOT)).div(100);
        } else {
            jp = game.collectedEthers.mul(management.payoutsPerCategory(JACKPOT)).div(100)
            .add(resultContract.collectedEthers().sub(resultContract.reservedAmount()));
        }
        collectedEthers = game.collectedEthers;
        price = management.ticketPrice();
        ticketsIssued = game.ticketsIssued;
        powerBall = game.powerBall;
        resultBalls = game.resultBalls;
    }

    function getGameResults(uint256 _gameTimestampedId) public view returns (
        uint256[5] resultBalls,
        uint256 powerBall
    ) {
        Game memory game = games[_gameTimestampedId];
        resultBalls = game.resultBalls;
        powerBall = game.powerBall;
    }

    function getGameTicketById(uint256 _gameTimestampedId, uint256 _ticketId) public view returns (
        uint256[5] balls,
        uint256 powerBall,
        address owner
    ) {
        Game storage game = games[_gameTimestampedId];
        Ticket memory ticket = game.tickets[_ticketId];
        balls = ticket.balls;
        powerBall = ticket.powerBall;
        owner = ticket.owner;
    }

    function getTicketOwnerById(uint256 _gameTimestampedId, uint256 _ticketId) public view returns (
        address owner
    ) {
        Game storage game = games[_gameTimestampedId];
        Ticket memory ticket = game.tickets[_ticketId];
        owner = ticket.owner;
    }

    function getResultsByTicketId(uint256 _gameTimestampedId, uint256 _ticketId) public view returns (uint256, uint256) {
        Game storage game = games[_gameTimestampedId];
        uint256 category = game.ticketsToCategories[_ticketId];
        return (game.winersCounsPerCategory[category], category);
    }

    function markTicketAsWithdrawed(uint256 _gameTimestampedId, uint256 _ticketId)
        public canCallOnlyRegisteredContract(CONTRACT_RESULTS) {
        Game storage game = games[_gameTimestampedId];
        game.ticketsToCategories[_ticketId] = 0;
    }

    function createGameInternal(uint256 _startTime) internal {
        require(activeGame.add(GAME_DURATION) <= _startTime);
        uint256[5] memory tmp;
        games[_startTime] = Game(0, 0, 0, tmp);
        activeGame = _startTime;
    }

    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}