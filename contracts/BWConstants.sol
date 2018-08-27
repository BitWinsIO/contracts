pragma solidity 0.4.24;


contract BWConstants {

    // Permissions bit constants
    uint8 public constant CAN_RECORD_PURCHASE = 0;
    uint8 public constant CAN_RECORD_RESULT = 1;
    uint8 public constant CAN_RECORD_HASH = 2;
    uint8 public constant CAN_INCREASE_GAME_BALANCE = 3;

    uint256 public constant  MIN_NUMBER = 1;
    uint256 public constant  GAME_DURATION = 1 weeks;
    uint256 public constant  TIME_TO_CHECK_TICKET = 3 days;
    uint256 public constant  TIME_TO_CLAIM_PRIZE = 7 days;

    uint256 public constant JACKPOT = 1;
    uint256 public constant FIVE = 2;
    uint256 public constant FOUR_PB = 3;

    // Contract Registry keys
    uint256 public constant CASHIER = 1;
    uint256 public constant LOTTERY = 2;
    uint256 public constant RESULTS = 3;
    uint256 public constant RANDOMIZER = 4;

    string public constant ACCESS_DENIED = 'ACCESS_DENIED';
    string public constant WRONG_AMOUNT = 'WRONG_AMOUNT';
    string public constant NO_CONTRACT = 'NO_CONTRACT';
    string public constant NO_ACTIVE_LOTTERY = 'NO_ACTIVE_LOTTERY';
    string public constant NOT_AVAILABLE = 'NOT_AVAILABLE';

//    uint256[2][10] public RES_TWO = [[0, 1], [0, 2], [0, 3], [0, 4], [1, 2], [1, 3], [1, 4], [2, 3], [2, 4], [3, 4]];
//    uint256[3][10] public  RES_THREE = [[0, 1, 2], [0, 1, 3], [0, 1, 4], [0, 2, 3], [0, 2, 4], [0, 3, 4], [1, 2, 3], [1, 2, 4], [1, 3, 4], [2, 3, 4]];
    uint256[4][5] public resFour = [[0, 1, 2, 3], [0, 1, 2, 4], [0, 1, 3, 4], [0, 2, 3, 4], [1, 2, 3, 4]];

}