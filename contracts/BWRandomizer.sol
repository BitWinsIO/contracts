pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import 'installed_contracts/oraclize-api/contracts/usingOraclize.sol';
import './BWManaged.sol';
import './Strings.sol';
import './BWLottery.sol';


contract BWRandomizer is BWManaged, usingOraclize {
    using SafeMath for uint256;
    using Strings for *;


    uint256 public randomQueryID;
    /* init gas for oraclize */
    uint256 public gasForOraclize = 235000;

    event LogInfo(string description);
    event LogRandomUpdate(string numbers);
    event GameResult(uint256 gameId, uint256[5] numbers, uint256 pb);

    constructor(address _management) public BWManaged(_management) {
        /* init gas price for callback (default 20 gwei)*/
        oraclize_setCustomGasPrice(20000000000 wei);
    }

    function() public payable {
        revert();
    }

    function random() public payable {
        update();
    }

    function __callback(bytes32, string result) public {
        uint256[5] memory randomInt;
        require(msg.sender == oraclize_cbAddress());
        var slResult = result.toSlice();
        slResult.beyond('['.toSlice()).until(']'.toSlice());
        for (uint256 i = 0; i < 5; i++) {
            randomInt[i] = parseInt(slResult.split(', '.toSlice()).toString());
        }
        insertionSortMemory(randomInt);
        uint256 pb = parseInt(slResult.split(', '.toSlice()).toString()) % management.maxPowerBall();
        BWLottery lottery = BWLottery(management.contractRegistry(LOTTERY));
        uint256 gameId = lottery.activeGame();
        require(block.timestamp <= gameId.add(GAME_DURATION), ACCESS_DENIED);
        lottery.setGameResult(gameId, randomInt, pb);
        BWCashier cashier = BWCashier(management.contractRegistry(CASHIER));
        cashier.setGameBalance(gameId);
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
            emit LogInfo('Oraclize query was sent, standing by for the answer..');

            // Using XPath to to fetch the right element in the JSON response
            randomQueryID += 1;
            string memory queryString1 = '[URL] [\'json(https://api.random.org/json-rpc/1/invoke).result.random[\'serialNumber\',\'data\']\', \'\\n{\'jsonrpc\':\'2.0\',\'method\':\'generateSignedIntegers\',\'params\':{\'apiKey\':${[decrypt] BJ8BMENGnafmVci9OE5n98MGZRU624r/QWOQi90YwuZzHL2jaK2SCf5L38gsyD3kG4CS3sjZVLPdprfbo+L9lUXQtVJb/8SPIjkMU3lk943v60Co2+oLMVgSRtNKAAzHS6DJPeLOYaDHLhbCLORoUt2fPKSp87E=},\'n\':6,\'min\':1,\'max\':69,\'replacement\':true,\'base\':10${[identity] \'}\'},\'id\':';
            string memory queryString2 = uint2str(randomQueryID);
            string memory queryString3 = '${[identity] \'}\'}\']';

            string memory queryString12 = queryString1.toSlice().concat(queryString2.toSlice());

            string memory queryString123 = queryString12.toSlice().concat(queryString3.toSlice());

            oraclize_query('nested', queryString123, gasForOraclize);
        }

    }

    function insertionSortMemory(uint256[5] a) public pure returns (uint256[5]) {
        for (uint256 i = 0; i < a.length; i++) {
            uint256 j = i;
            while (j > 0 && a[j] < a[j - 1]) {
                uint256 temp = a[j];
                a[j] = a[j - 1];
                a[j - 1] = temp;
                j--;
            }
        }
        return a;
    }

}
