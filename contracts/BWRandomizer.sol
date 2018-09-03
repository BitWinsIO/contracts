pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import 'installed_contracts/oraclize-api/contracts/usingOraclize.sol';
import './BWManaged.sol';
import './Strings.sol';
import './BWLottery.sol';
import './BWCashier.sol';


contract BWRandomizer is BWManaged, usingOraclize {
    using SafeMath for uint256;
    using Strings for *;


    uint256 public randomQueryID;
    /* init gas for oraclize */
    uint256 public gasForOraclize = 235000;

    event LogInfo(string description);
    event LogRandomUpdate(string numbers);
    event GameResult(uint256 gameTimestampedId, uint256[5] numbers, uint256 powerBall);

    constructor(address _management) public BWManaged(_management) {
        /* init gas price for callback (default 20 gwei)*/
        oraclize_setCustomGasPrice(20000000000 wei);
    }

    function random() public payable {
        update();
    }

    function __callback(bytes32, string result) public {
        uint256[5] memory randomInt;
        require(msg.sender == oraclize_cbAddress(), ERROR_ACCESS_DENIED);
        var slResult = result.toSlice();
        slResult.beyond('['.toSlice()).until(']'.toSlice());
        for (uint256 i = 0; i < 5; i++) {
            randomInt[i] = parseInt(slResult.split(', '.toSlice()).toString());
        }
        insertionSortMemory(randomInt);
        uint256 powerBall = parseInt(slResult.split(', '.toSlice()).toString()) % management.maxPowerBall();
        BWLottery lottery = BWLottery(management.contractRegistry(CONTRACT_LOTTERY));
        uint256 gameTimestampedId = lottery.activeGame();
        require(block.timestamp <= gameTimestampedId.add(GAME_DURATION), ERROR_ACCESS_DENIED);
        lottery.setGameResult(gameTimestampedId, randomInt, powerBall);
        BWCashier cashier = BWCashier(management.contractRegistry(CONTRACT_CASHIER));
        cashier.setGameBalance(gameTimestampedId);
        emit LogRandomUpdate(result);
    }

    /* set gas limit for oraclize query */
    function ownerSetOraclizeSafeGas(uint32 newSafeGasToOraclize) public onlyOwner {
        gasForOraclize = newSafeGasToOraclize;
    }

    /* set gas price for oraclize callback */
    function ownerSetCallbackGasPrice(uint256 newCallbackGasPrice) public onlyOwner {
        oraclize_setCustomGasPrice(newCallbackGasPrice);
    }

    function update() public payable {
        // Check if we have enough remaining funds
        if (oraclize_getPrice('URL') > address(this).balance) {
            emit LogInfo('Oraclize query was NOT sent, please add some ETH to cover for the query fee');
        } else {
            // Using XPath to to fetch the right element in the JSON response
            randomQueryID += 1;
            // encoded with https://github.com/oraclize/encrypted-queries/issues/3
            string memory string1 = "[URL] ['json(https://api.random.org/json-rpc/1/invoke).result.random.data', '\\n{\"jsonrpc\":\"2.0\",\"method\":\"generateSignedIntegers\",\"params\":{\"apiKey\":${[decrypt] BKk2Pxt1G3j/TRTMH6sJeNDZ+P+3S6/KbyIxI0qGAHouNWh/5RdRixsSz0G4aIv1Zgz9AZLbVMqwI9RQ6EjSzyrtvWAVVxbfG6fDKiRifA9ai3zdFh1R4BHXps+/CAepLtDmzHS/tVKfvYo4sKkqQQXED+z/Qmc=},\"n\":6,\"min\":1,\"max\":";
            string memory string2 = uint2str(69);
            string memory string3 = ",\"replacement\":true,\"base\":10${[identity] \"}\"},\"id\":";
            string memory query0 = strConcat(string1, string2, string3);
            string memory string4 = uint2str(randomQueryID);
            string memory string5 = "${[identity] \"}\"}']";
            string memory query = strConcat(query0, string4, string5);
            oraclize_query("nested", query, gasForOraclize);
            emit LogInfo('Oraclize query was sent, standing by for the answer..');
        }

    }
}
