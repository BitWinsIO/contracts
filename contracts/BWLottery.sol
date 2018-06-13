pragma solidity 0.4.24;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './BWManaged.sol';
import './BWCashier.sol';


contract BWLottery is BWManaged {

    using SafeMath for uint256;

    uint256 public activeGame;

    //timestamp => struct
    mapping(uint256 => Game) public lotteries;

    struct Game {
        uint256 result;
        uint256 jackpot;
        uint256 collectedEthers;
        uint256[2] contributionRange;
        mapping(address => uint256[]) contributors;
        mapping(uint256 => address[]) bids; //(for  5 numbers)
        mapping(uint256 => address[]) bidsWithPowerball; //(for  6 numbers)
    }


    constructor(
        address _management,
        uint256 _minContribution,
        uint256 _maxContribution,
        uint256 _initialJackpot
    ) public BWManaged(_management) {
        createGame(_minContribution, _maxContribution, _initialJackpot);
    }

    function purchase(uint8[6] _input) public payable requireRegisteredContract(CASHIER) {
        require(activeGame > 0, NO_ACTIVE_LOTTERY);
        require(!isContract(msg.sender), ACCESS_DENIED);
        require(block.timestamp <= activeGame.add(GAME_DURATION), ACCESS_DENIED);

        Game storage lottery = lotteries[activeGame];

        require((lottery.contributionRange[0] < msg.value
        && (lottery.contributionRange[1] == 0 || lottery.contributionRange[1] >= msg.value)), WRONG_AMOUNT);

        uint256[2] memory numbers = encode(_input);
        require((numbers[0] != 0 && numbers[1] != 0), WRONG_AMOUNT);

        lottery.bids[numbers[0]].push(msg.sender);
        lottery.bidsWithPowerball[numbers[1]].push(msg.sender);
        lottery.collectedEthers = lottery.collectedEthers.add(msg.value);
        lottery.contributors[msg.sender].push(msg.value);

        BWCashier cashier = BWCashier(management.contractRegistry(CASHIER));
        cashier.recordPurchase.value(msg.value)(activeGame, msg.sender);

    }

    function setGameResult(uint256 _gameId, uint8[6] _input) public requireRegisteredContract(CASHIER)
    returns (address[], address[]){
        require(msg.sender == management.contractRegistry(RESULTS), ACCESS_DENIED);
        require(_gameId.add(GAME_DURATION) <= block.timestamp, ACCESS_DENIED);
        Game storage lottery = lotteries[_gameId];
        uint256[2] memory numbers = encode(_input);
        require((numbers[0] != 0 && numbers[1] != 0), WRONG_AMOUNT);
        lottery.result = numbers[1];
        return (lottery.bids[numbers[0]], lottery.bidsWithPowerball[numbers[1]]);
    }

    function getGame(uint256 _time) public view returns (
        uint8[6] result,
        uint256 collectedEthers,
        uint256[2] contributionRange,
        address[] jpWinners,
        address[] fiveWinners
    ) {
        Game storage lottery = lotteries[_time];
        result = decodeBid(lottery.result);
        collectedEthers = lottery.collectedEthers;
        contributionRange = lottery.contributionRange;
        if (lottery.result != 0) {
            jpWinners = lottery.bidsWithPowerball[lottery.result];
            fiveWinners = lottery.bids[encode(result)[0]];
        }
    }

    function decodeBid(uint256 _bid) public pure returns (uint8[6] result){
        result[0] = uint8(bytes2(_bid >> 16));
        result[1] = uint8(bytes2(_bid >> 32));
        result[2] = uint8(bytes2(_bid >> 48));
        result[3] = uint8(bytes2(_bid >> 64));
        result[4] = uint8(bytes2(_bid >> 80));
        result[5] = uint8(bytes2(_bid >> 96));
    }

    function encode(uint8[6] _input) public pure returns (uint256[2] results){
        uint256 bid;
        for (uint256 i = 0; i < _input.length; i++) {
            if (_input[i] < _input.length - 1) {
                if (_input[i] < MIN_NUMBER || _input[i] > MAX_NUMBER) {
                    bid = 0;
                    return [bid, bid];
                }
                bid = bid.add(_input[i] << uint256(16).mul(i+1));
            } else {
                results[0] = bid;
                if (_input[i] < MIN_NUMBER || _input[i] > MAX_POWERBALL) {
                    bid = 0;
                    return [bid, bid];
                }
                bid = bid.add(_input[i] << uint256(16).mul(i+1));
                results[1] = bid;
            }
        }
    }

    function createGame(uint256 _minContribution, uint256 _maxContribution, uint256 _jackpot) internal {
        //@todo increase jackpot if not win prev
        lotteries[block.timestamp] = Game(0, _jackpot, 0, [_minContribution, _maxContribution]);
    }

    function isContract(address _addr) private view returns (bool iscontract){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}