pragma solidity 0.4.24;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import './BWManaged.sol';


contract BWCombinations is BWManaged {
    using SafeMath for uint256;

    constructor(address _management) public BWManaged(_management) {
    }

    function decodeBid(uint256 _bid) public pure returns (uint256[6] result){
        result[0] = uint256(bytes2(_bid >> 16));
        result[1] = uint256(bytes2(_bid >> 32));
        result[2] = uint256(bytes2(_bid >> 48));
        result[3] = uint256(bytes2(_bid >> 64));
        result[4] = uint256(bytes2(_bid >> 80));
        result[5] = uint256(bytes2(_bid >> 96));
    }

    function encode(uint256[6] _input) public view returns (uint256 bid){
        for (uint256 i = 0; i < _input.length; i++) {
            if (i < _input.length - 1) {
                if (_input[i] > maxBall) {
                    bid = 0;
                    return bid;
                }
                bid = bid.add(_input[i] << uint256(16).mul(i+1));
            } else {
                if (_input[i] > maxPowerBall) {
                    bid = 0;
                    return bid;
                }
                bid = bid.add(_input[i] << uint256(16).mul(i+1));
            }
        }
        return bid;
    }

    function calculateComb(uint256[5] _balls, uint256 _pb) public view returns (uint256[7] result) {
        uint256 key;
        uint256[6] memory ballsTmp;
        ballsTmp[5] = _pb;

        for (uint256 i = 0; i < RES_FOUR.length; i++) {
            ballsTmp[RES_FOUR[i][0]] = _balls[RES_FOUR[i][0]];
            ballsTmp[RES_FOUR[i][1]] = _balls[RES_FOUR[i][1]];
            ballsTmp[RES_FOUR[i][2]] = _balls[RES_FOUR[i][2]];
            ballsTmp[RES_FOUR[i][3]] = _balls[RES_FOUR[i][3]];

            result[key] = encode(ballsTmp);
            key = uint256(key).add(uint256(1));
            ballsTmp[RES_FOUR[i][0]] = 0;
            ballsTmp[RES_FOUR[i][1]] = 0;
            ballsTmp[RES_FOUR[i][2]] = 0;
            ballsTmp[RES_FOUR[i][3]] = 0;
        }
        for (i = 0; i < 5; i++) {
            ballsTmp[i] = _balls[i];
        }
        result[key] = encode(ballsTmp);
        key = uint256(key).add(uint256(1));
        ballsTmp[5] = _pb;
        result[key] = encode(ballsTmp);
    }
}
