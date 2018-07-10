pragma solidity ^0.4.24;

import '../BWRandomizer.sol';


contract BWRandomizerTest is BWRandomizer {

    uint public testPb;
    uint[5] public testArray;

    constructor(address _management) public BWRandomizer(_management) {
        OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);

        oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
    }

    function __callback(bytes32, string result) public {
        uint256[5] memory randomInt;
//        require(msg.sender == oraclize_cbAddress());
        var sl_result = result.toSlice();
        sl_result.beyond("[".toSlice()).until("]".toSlice());
        for (uint i = 0; i < 5; i++) {
            randomInt[i] = parseInt(sl_result.split(', '.toSlice()).toString());
        }
        insertionSortMemory(randomInt);
        for (i = 0; i < 5; i++) {
            testArray[i] = randomInt[i];
        }

        uint256 pb = parseInt(sl_result.split(', '.toSlice()).toString()) % maxPowerBall;
        testPb = pb;
        BWLottery lottery = BWLottery(management.contractRegistry(LOTTERY));
        lottery.setGameResult(lottery.activeGame(), randomInt, pb);
        emit LogRandomUpdate(result);
        // update();
    }

}
