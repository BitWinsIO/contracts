pragma solidity 0.4.24;


contract BWConstants {

    // Permissions bit constants
    uint8 public constant CAN_RECORD_PURCHASE = 0;
    uint8 public constant CAN_RECORD_RESULT = 1;
    uint8 public constant CAN_RECORD_HASH = 2;

    uint public constant  MIN_NUMBER= 1;
    uint public constant  MAX_NUMBER= 69;
    uint public constant  MAX_POWERBALL= 26;
    uint public constant  GAME_DURATION= 1 weeks;

    // Contract Registry keys
    uint public constant CASHIER = 1;
    uint public constant LOTTERY = 2;
    uint public constant RESULTS = 3;

    string public constant ACCESS_DENIED = 'ACCESS_DENIED';
    string public constant WRONG_AMOUNT = 'WRONG_AMOUNT';
    string public constant NO_CONTRACT = 'NO_CONTRACT';
    string public constant NO_ACTIVE_LOTTERY = 'NO_ACTIVE_LOTTERY';
}