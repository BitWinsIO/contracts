pragma solidity ^0.4.23;

import '../BWResults.sol';


contract BWResultsTest is BWResults {

    constructor(
        address _management
    ) public BWResults(_management) {
    }

    //test
    function withdrowPrize(uint256 _gameId, uint256 _ticketId) public {
        BWLottery lotteryContract = BWLottery(management.contractRegistry(LOTTERY));
        //        require(_gameId != 0 && block.timestamp >= _gameId.add(14 days), ACCESS_DENIED);
        uint256 winnersAmount;
        uint256 categoryId;
        (winnersAmount, categoryId) = lotteryContract.getResultsByTicketId(_gameId, _ticketId);
        lotteryContract.markTickedAsClaimed(_gameId, _ticketId);
        require(winnersAmount > 0);
        address owner = lotteryContract.getTicketOwnerById(_gameId, _ticketId);
        uint256 value =  gameBalances[_gameId].mul(payoutsPerCategory[categoryId]).div(100).div(winnersAmount);
        owner.transfer(value);
        emit PrizeWithdrawn(_ticketId, categoryId, value);

    }
}
