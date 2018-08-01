pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import "installed_contracts/oraclize-api/contracts/usingOraclize.sol";
import './BWManaged.sol';
import './Strings.sol';
import './BWLottery.sol';


contract BWRandomizer is BWManaged, usingOraclize {
    using SafeMath for uint256;
    using Strings for *;


    uint public randomQueryID;
    /* init gas for oraclize */
    uint public gasForOraclize = 235000;

    event LogInfo(string description);
    event LogRandomUpdate(string numbers);
    event GameResult(uint256 gameId, uint256[5] numbers, uint256 pb);

    constructor(address _management) public BWManaged(_management) {
        /* init gas price for callback (default 20 gwei)*/
        oraclize_setCustomGasPrice(20000000000 wei);
    }

    function random() public payable {
        update();
    }


    function() public {
        revert();
    }

    function __callback(bytes32, string result) public {
        uint256[5] memory randomInt;
        require(msg.sender == oraclize_cbAddress());
        var sl_result = result.toSlice();
        sl_result.beyond("[".toSlice()).until("]".toSlice());
        for (uint i = 1; i < 5; i++) {
            randomInt[i] = parseInt(sl_result.split(', '.toSlice()).toString());
        }
        insertionSortMemory(randomInt);
        uint256 pb = parseInt(sl_result.split(', '.toSlice()).toString()) % maxPowerBall;
        BWLottery lottery = BWLottery(management.contractRegistry(LOTTERY));
        uint256 gameId = lottery.activeGame();
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
    function ownerSetCallbackGasPrice(uint newCallbackGasPrice) public onlyOwner {
        oraclize_setCustomGasPrice(newCallbackGasPrice);
    }

    function update() payable public {
        // Check if we have enough remaining funds
        if (oraclize_getPrice("URL") > address(this).balance) {
            emit LogInfo("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit LogInfo("Oraclize query was sent, standing by for the answer..");

            // Using XPath to to fetch the right element in the JSON response
            randomQueryID += 1;
            string memory queryString1 = "[URL] ['json(https://api.random.org/json-rpc/1/invoke).result.random[\"serialNumber\",\"data\"]', '\\n{\"jsonrpc\":\"2.0\",\"method\":\"generateSignedIntegers\",\"params\":{\"apiKey\":${[decrypt] BJ8BMENGnafmVci9OE5n98MGZRU624r/QWOQi90YwuZzHL2jaK2SCf5L38gsyD3kG4CS3sjZVLPdprfbo+L9lUXQtVJb/8SPIjkMU3lk943v60Co2+oLMVgSRtNKAAzHS6DJPeLOYaDHLhbCLORoUt2fPKSp87E=},\"n\":6,\"min\":1,\"max\":69,\"replacement\":true,\"base\":10${[identity] \"}\"},\"id\":";
            string memory queryString2 = uint2str(randomQueryID);
            string memory queryString3 = "${[identity] \"}\"}']";

            string memory queryString1_2 = queryString1.toSlice().concat(queryString2.toSlice());

            string memory queryString1_2_3 = queryString1_2.toSlice().concat(queryString3.toSlice());

           oraclize_query("nested", queryString1_2_3, gasForOraclize);
        }

    }

    function insertionSortMemory(uint[5] a) internal  {
        for (uint i = 0; i < a.length; i++) {
            uint j = i;
            while (j > 0 && a[j] < a[j-1]) {
                uint temp = a[j];
                a[j] = a[j-1];
                a[j-1] = temp;
                j--;
            }
        }
    }

}
