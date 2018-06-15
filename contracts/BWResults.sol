pragma solidity 0.4.24;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './BWManaged.sol';
import './BWCashier.sol';
import './BWLottery.sol';


contract BWResults is BWManaged {

    using SafeMath for uint256;

    mapping(uint256 => bytes32[10]) public hashes;
    mapping(uint256 => uint8) public hashesCount;

    event GameResult(uint256 gameId, uint8[6] numbers);

    constructor(address _management) public BWManaged(_management) {
    }

    function setHash(uint256 _gameId) public
    requireRegisteredContract(CASHIER)
    requirePermission(CAN_RECORD_HASH) {
        require(hashesCount[_gameId] < 10, ACCESS_DENIED);
        hashesCount[_gameId] = hashesCount[_gameId] + 1;
        //@todo add implementation
    //hashes[_gameId];
    }

    function random(uint256 _gameId) public
    requireRegisteredContract(CASHIER)
    requirePermission(CAN_RECORD_HASH) returns (uint256, uint8[6]){
        require(hashesCount[_gameId] == 10, ACCESS_DENIED);
        uint8[6] memory numbers;
        //@todo add implementation
        BWLottery lottery =  BWLottery(management.contractRegistry(LOTTERY));
        lottery.setGameResult(_gameId, numbers);

        emit GameResult(_gameId, numbers);

        return (_gameId, numbers);
    }
}
