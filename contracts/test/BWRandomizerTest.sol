pragma solidity ^0.4.24;

import '../BWRandomizer.sol';


contract BWRandomizerTest is BWRandomizer {

    uint256 public testPb;
    uint256[5] public testArray;

    event Debug(string _s, uint256 _v);

    constructor(address _management) public BWRandomizer(_management) {
        OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);

        oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
    }

    function __callback(bytes32, string result) public {
        uint256[5] memory randomInt;
//        require(msg.sender == oraclize_cbAddress());
        var slResult = result.toSlice();
        slResult.beyond('['.toSlice()).until(']'.toSlice());
        for (uint256 i = 0; i < 5; i++) {
            randomInt[i] = parseInt(slResult.split(', '.toSlice()).toString());
        }
        insertionSortMemory(randomInt);
        uint256 powerBall = parseInt(slResult.split(', '.toSlice()).toString()) % management.maxPowerBall();
        BWLottery lottery = BWLottery(management.contractRegistry(CONTRACT_LOTTERY));
        uint256 gameTimestampedId = lottery.activeGame();
//        require(block.timestamp <= gameTimestampedId.add(GAME_DURATION), ERROR_ACCESS_DENIED);
        lottery.setGameResult(gameTimestampedId, randomInt, powerBall);
        BWCashier cashier = BWCashier(management.contractRegistry(CONTRACT_CASHIER));
        cashier.setGameBalance(gameTimestampedId);
        emit LogRandomUpdate(result);
    }

}
