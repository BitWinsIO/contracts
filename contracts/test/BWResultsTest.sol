pragma solidity ^0.4.23;

import '../BWResults.sol';


contract BWResultsTest is BWResults {

    constructor(
        address _management
    ) public BWResults(_management) {
    }

    //test
    function withdrawPrize(uint256 _gameTimestampedId, uint256 _ticketId) public {
        BWLottery lotteryContract = BWLottery(management.contractRegistry(CONTRACT_LOTTERY));
//        require(_gameTimestampedId != 0 && block.timestamp >= _gameTimestampedId.add(TIME_TO_CHECK_TICKET), ERROR_ACCESS_DENIED);
//        require(block.timestamp <= _gameTimestampedId.add(TIME_TO_CHECK_TICKET).add(TIME_TO_CLAIM_PRIZE), ERROR_ACCESS_DENIED);
        uint256 winnersAmount;
        uint256 categoryId;
        (winnersAmount, categoryId) = lotteryContract.getResultsByTicketId(_gameTimestampedId, _ticketId);
        lotteryContract.markTicketAsClaimed(_gameTimestampedId, _ticketId);
        require(winnersAmount > 0);
        address ticketOwner = lotteryContract.getTicketOwnerById(_gameTimestampedId, _ticketId);
        uint256 value =  gameBalances[_gameTimestampedId].mul(management.payoutsPerCategory(categoryId)).div(100).div(winnersAmount);
        reservedAmount = reservedAmount.sub(value);
        collectedEthers = collectedEthers.sub(value);
        ticketOwner.transfer(value);
        emit PrizeWithdrawn(_ticketId, categoryId, value);

    }
}
