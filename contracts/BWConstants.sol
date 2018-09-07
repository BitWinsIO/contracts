pragma solidity 0.4.24;


contract BWConstants {

    // Permissions bit constants
    uint256 public constant CAN_RECORD_PURCHASE = 0;
    uint256 public constant CAN_RECORD_RESULT = 1;
    uint256 public constant CAN_RECORD_HASH = 2;
    uint256 public constant CAN_INCREASE_GAME_BALANCE = 3;

    uint256 public constant MIN_NUMBER = 1; // min number on the ball
    uint256 public constant GAME_DURATION = 7 days;
    uint256 public constant TIME_TO_CHECK_TICKET = 3 days;
    uint256 public constant TIME_TO_CLAIM_PRIZE = 7 days;

    // prize categories
    uint256 public constant JACKPOT = 1;
    uint256 public constant FIVE = 2;
    uint256 public constant FOUR_PB = 3;

    // Contract Registry keys
    uint256 public constant CONTRACT_CASHIER = 1;
    uint256 public constant CONTRACT_LOTTERY = 2;
    uint256 public constant CONTRACT_RESULTS = 3;
    uint256 public constant CONTRACT_RANDOMIZER = 4;

    string public constant ERROR_ACCESS_DENIED = 'ERROR_ACCESS_DENIED';
    string public constant ERROR_WRONG_AMOUNT = 'ERROR_WRONG_AMOUNT';
    string public constant ERROR_NO_CONTRACT = 'ERROR_NO_CONTRACT';
    string public constant ERROR_NO_ACTIVE_LOTTERY = 'ERROR_NO_ACTIVE_LOTTERY';
    string public constant ERROR_NOT_AVAILABLE = 'ERROR_NOT_AVAILABLE';
}