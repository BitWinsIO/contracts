const Cashier = artifacts.require('./BWCashier.sol');
const Lottery = artifacts.require("./test/BWLotteryTest.sol");
const Results = artifacts.require("./test/BWResultsTest.sol");
const Management = artifacts.require("./BWManagement.sol");
const Combinations = artifacts.require("./BWCombinations.sol");
const Randomizer = artifacts.require("./test/BWRandomizerTest.sol");

const Utils = require("./utils");
const BigNumber = require('bignumber.js');
let startGame = parseInt(new Date().getTime() / 1000),
    threeDays = 24*3*3600;

contract('BWCombinations', function (accounts) {
    let lottery,
        cashier,
        results,
        randomizer,
        management,
        combinations,
        etherHolder = accounts[0],
        precision = new BigNumber("1000000000000000000").valueOf(),
        fundation = accounts[8],
        BitWinsA = accounts[3],
        BitWinsB = accounts[7],
        Applicature = accounts[4],
        BitWinsC = accounts[5],
        BitWinsD = accounts[6];

    beforeEach(async function () {

        management = await Management.new();
        lottery = await Lottery.new(management.address, new BigNumber(startGame).sub(threeDays).add(200));
        cashier = await Cashier.new(management.address, 10000, [fundation, BitWinsA, BitWinsB, Applicature, BitWinsC, BitWinsD], [40, 49, 49, 196, 686, 980]);
        combinations = await Combinations.new(management.address);
        results = await Results.new(management.address);
        randomizer = await Randomizer.new(management.address);
    });
    it("check  encode & decode functions", async function () {

        let activetime = new BigNumber(await lottery.activeGame.call()).valueOf();
        await management.registerContract(1, cashier.address);
        await management.registerContract(2, lottery.address);
        await management.registerContract(3, results.address);
        await management.registerContract(4, combinations.address);
        await management.registerContract(5, randomizer.address);
        await lottery.setResultsContract(results.address);

        await management.setPermission(lottery.address, 0, true);
        await management.setPermission(cashier.address, 3, true);

        let fundationBalance = await Utils.getEtherBalance(fundation);
        let bitWinsABalance = await Utils.getEtherBalance(BitWinsA);
        let bitWinsBBalance = await Utils.getEtherBalance(BitWinsB);
        let applicatureBalance = await Utils.getEtherBalance(Applicature);
        let bitWinsCBalance = await Utils.getEtherBalance(BitWinsC);
        let bitWinsDBalance = await Utils.getEtherBalance(BitWinsD);

       // [5, 25, 28, 40, 60], 12
        let bid = await combinations.encode.call([5, 25, 28, 40, 60, 12])
        console.log('bid', bid);
        let decode = await combinations.decodeBid.call(bid);
        console.log('decode', decode);
        assert.equal(decode[0].valueOf(), 5, "ball is not equal")
        assert.equal(decode[1].valueOf(), 25, "ball is not equal")
        assert.equal(decode[2].valueOf(), 28, "ball is not equal")
        assert.equal(decode[3].valueOf(), 40, "ball is not equal")
        assert.equal(decode[4].valueOf(), 60, "ball is not equal")
        assert.equal(decode[5].valueOf(), 12, "ball is not equal")
    });
    it("check  calculateComb", async function () {

        let activetime = new BigNumber(await lottery.activeGame.call()).valueOf();
        await management.registerContract(1, cashier.address);
        await management.registerContract(2, lottery.address);
        await management.registerContract(3, results.address);
        await management.registerContract(4, combinations.address);
        await management.registerContract(5, randomizer.address);
        await lottery.setResultsContract(results.address);

        await management.setPermission(lottery.address, 0, true);
        await management.setPermission(cashier.address, 3, true);
       // [5, 25, 28, 40, 60], 12
        let bid = await combinations.calculateComb.call([5, 25, 28, 40, 60], 12)
        console.log('bid', bid);
        let decode = await combinations.decodeBid.call(bid[6]);
        assert.equal(decode[0].valueOf(), 5, "ball is not equal")
        assert.equal(decode[1].valueOf(), 25, "ball is not equal")
        assert.equal(decode[2].valueOf(), 28, "ball is not equal")
        assert.equal(decode[3].valueOf(), 40, "ball is not equal")
        assert.equal(decode[4].valueOf(), 60, "ball is not equal")
        assert.equal(decode[5].valueOf(), 12, "ball is not equal")
        decode = await combinations.decodeBid.call(bid[5]);
        assert.equal(decode[0].valueOf(), 5, "ball is not equal")
        assert.equal(decode[1].valueOf(), 25, "ball is not equal")
        assert.equal(decode[2].valueOf(), 28, "ball is not equal")
        assert.equal(decode[3].valueOf(), 40, "ball is not equal")
        assert.equal(decode[4].valueOf(), 60, "ball is not equal")
        assert.equal(decode[5].valueOf(), 0, "ball is not equal")

        decode = await combinations.decodeBid.call(bid[4]);
        assert.equal(decode[0].valueOf(), 0, "ball is not equal")
        assert.equal(decode[1].valueOf(), 25, "ball is not equal")
        assert.equal(decode[2].valueOf(), 28, "ball is not equal")
        assert.equal(decode[3].valueOf(), 40, "ball is not equal")
        assert.equal(decode[4].valueOf(), 60, "ball is not equal")
        assert.equal(decode[5].valueOf(), 12, "ball is not equal")

        decode = await combinations.decodeBid.call(bid[3]);
        assert.equal(decode[0].valueOf(), 5, "ball is not equal")
        assert.equal(decode[1].valueOf(), 0, "ball is not equal")
        assert.equal(decode[2].valueOf(), 28, "ball is not equal")
        assert.equal(decode[3].valueOf(), 40, "ball is not equal")
        assert.equal(decode[4].valueOf(), 60, "ball is not equal")
        assert.equal(decode[5].valueOf(), 12, "ball is not equal")

        decode = await combinations.decodeBid.call(bid[2]);
        assert.equal(decode[0].valueOf(), 5, "ball is not equal")
        assert.equal(decode[1].valueOf(), 25, "ball is not equal")
        assert.equal(decode[2].valueOf(), 0, "ball is not equal")
        assert.equal(decode[3].valueOf(), 40, "ball is not equal")
        assert.equal(decode[4].valueOf(), 60, "ball is not equal")
        assert.equal(decode[5].valueOf(), 12, "ball is not equal")

        decode = await combinations.decodeBid.call(bid[1]);
        assert.equal(decode[0].valueOf(), 5, "ball is not equal")
        assert.equal(decode[1].valueOf(), 25, "ball is not equal")
        assert.equal(decode[2].valueOf(), 28, "ball is not equal")
        assert.equal(decode[3].valueOf(), 0, "ball is not equal")
        assert.equal(decode[4].valueOf(), 60, "ball is not equal")
        assert.equal(decode[5].valueOf(), 12, "ball is not equal")
        decode = await combinations.decodeBid.call(bid[0]);
        assert.equal(decode[0].valueOf(), 5, "ball is not equal")
        assert.equal(decode[1].valueOf(), 25, "ball is not equal")
        assert.equal(decode[2].valueOf(), 28, "ball is not equal")
        assert.equal(decode[3].valueOf(), 40, "ball is not equal")
        assert.equal(decode[4].valueOf(), 0, "ball is not equal")
        assert.equal(decode[5].valueOf(), 12, "ball is not equal")
    });

});