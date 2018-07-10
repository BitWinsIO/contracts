pragma solidity 0.4.24;


contract BWConstants {

    // Permissions bit constants
    uint8 public constant CAN_RECORD_PURCHASE = 0;
    uint8 public constant CAN_RECORD_RESULT = 1;
    uint8 public constant CAN_RECORD_HASH = 2;

    uint public constant  MIN_NUMBER = 1;
    uint public constant  GAME_DURATION = 1 weeks;

    uint public constant JACKPOT = 1;
    uint public constant FIVE = 2;
    uint public constant FOUR_PB = 3;

    // Contract Registry keys
    uint public constant CASHIER = 1;
    uint public constant LOTTERY = 2;
    uint public constant RESULTS = 3;
    uint public constant COMBINATIONS = 4;
    uint public constant RANDOMIZER = 5;

    string public constant ACCESS_DENIED = 'ACCESS_DENIED';
    string public constant WRONG_AMOUNT = 'WRONG_AMOUNT';
    string public constant NO_CONTRACT = 'NO_CONTRACT';
    string public constant NO_ACTIVE_LOTTERY = 'NO_ACTIVE_LOTTERY';

//    uint[2][10] public RES_TWO = [[0, 1], [0, 2], [0, 3], [0, 4], [1, 2], [1, 3], [1, 4], [2, 3], [2, 4], [3, 4]];
//    uint[3][10] public  RES_THREE = [[0, 1, 2], [0, 1, 3], [0, 1, 4], [0, 2, 3], [0, 2, 4], [0, 3, 4], [1, 2, 3], [1, 2, 4], [1, 3, 4], [2, 3, 4]];
    uint[4][5] public  RES_FOUR = [[0, 1, 2, 3], [0, 1, 2, 4], [0, 1, 3, 4], [0, 2, 3, 4], [1, 2, 3, 4]];

    uint256 public ticketPrice = 0.0025 ether;
    uint public maxBall = 69;
    uint public maxPowerBall = 26;
}