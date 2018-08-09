pragma solidity ^0.4.24;

import '../BWRandomizer.sol';


contract BWRandomizerTest is BWRandomizer {

    uint256 public testPb;
    uint256[5] public testArray;

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
        uint256 pb = parseInt(slResult.split(', '.toSlice()).toString()) % management.maxPowerBall();
        BWLottery lottery = BWLottery(management.contractRegistry(LOTTERY));
        uint256 gameId = lottery.activeGame();
//        require(block.timestamp <= gameId.add(GAME_DURATION), ACCESS_DENIED);
        lottery.setGameResult(gameId, randomInt, pb);
        BWCashier cashier = BWCashier(management.contractRegistry(CASHIER));
        cashier.setGameBalance(gameId);
        emit LogRandomUpdate(result);
    }

}
