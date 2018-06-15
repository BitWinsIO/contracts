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
        mapping(uint256 => Bids) bids;
    }

    struct Bids {
        mapping(uint256 => address[]) bidToAddress;
        address[] bidders;
        mapping(address => uint256[]) addressToBid;
        mapping(address => bool) payoutsSet; //addressId => set
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
        Bids storage bid = lottery.bids[numbers[0]];
        bid.bidToAddress[numbers[0]].push(msg.sender);
        bid.bidders.push(msg.sender);
        lottery.collectedEthers = lottery.collectedEthers.add(msg.value);
        lottery.contributors[msg.sender].push(msg.value);

        BWCashier cashier = BWCashier(management.contractRegistry(CASHIER));
        cashier.recordPurchase.value(msg.value)(activeGame, msg.sender);

    }

    function setGameResult(uint256 _gameId, uint8[6] _input) public requireRegisteredContract(CASHIER) {
        require(msg.sender == management.contractRegistry(RESULTS), ACCESS_DENIED);
        require(_gameId.add(GAME_DURATION) <= block.timestamp, ACCESS_DENIED);
        Game storage lottery = lotteries[_gameId];
        uint256[2] memory numbers = encode(_input);
        require((numbers[0] != 0 && numbers[1] != 0), WRONG_AMOUNT);
        lottery.result = numbers[1];
    }

    //  winner  range to avoid  out of gas error
    // - [0,0] - not run;
    // - [a,b] - run from a to b; a - included  if b is gather than length run to length
    function setPurchase(uint256 _gameId, uint256[2] _range) public requireRegisteredContract(CASHIER) {
        require(msg.sender == management.contractRegistry(RESULTS), ACCESS_DENIED);
        require(_gameId.add(GAME_DURATION) <= block.timestamp, ACCESS_DENIED);
        Game storage lottery = lotteries[_gameId];
        require(lottery.result != 0);
        uint8[6] memory result = decodeBid(lottery.result);
        Bids storage bid = lottery.bids[encode(result)[0]];
        address[] memory fiveWinners = bid.bidders;
        uint256[] memory bids = bid.addressToBid[fiveWinners[i]];
        uint256 jWinCount = bid.bidToAddress[lottery.result].length;
        uint256 fiveWinCount = bids.length.sub(jWinCount);
        uint256 iterations = _range[1] <= fiveWinners.length ? _range[1] : fiveWinners.length;
        for (uint256 i = _range[0]; i < iterations; i++) {
            if(bid.payoutsSet[fiveWinners[i]]== true){
                continue;
            }
            bid.payoutsSet[fiveWinners[i]]= true;
            for (uint256 j = 0; j < bids.length; j++) {
                if (bids[j] == lottery.result) {
                 //value = (jpAmount).div(jWinCount);
                    //@todo win JP
                    //increasePayoutBalances(fiveWinners[i], value);
                } else {
                    //value = (jpAmount).div(fiveWinCount);
                    //todo adds five nubers win
                    //increasePayoutBalances(fiveWinners[i], value);
                }
            }
        }
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
            Bids storage bid = lottery.bids[encode(result)[0]];
            jpWinners = bid.bidToAddress[lottery.result];
            fiveWinners = bid.bidders;
        }
    }

    function getGameWinners(uint256 _time) public view returns (
        address[] jpWinners,
        address[] fiveWinners
    ) {
        Game storage lottery = lotteries[_time];
        uint8[6] memory result = decodeBid(lottery.result);
        if (lottery.result != 0) {
            Bids storage bid = lottery.bids[encode(result)[0]];
            jpWinners = bid.bidToAddress[lottery.result];
            fiveWinners = bid.bidders;
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