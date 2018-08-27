const Cashier = artifacts.require('./BWCashier.sol');
const Lottery = artifacts.require("./test/BWLotteryTest.sol");
const Results = artifacts.require("./test/BWResultsTest.sol");
const Management = artifacts.require("./BWManagement.sol");
const Randomizer = artifacts.require("./test/BWRandomizerTest.sol");

const Utils = require("./utils");
const BigNumber = require('bignumber.js');
let startGame = parseInt(new Date().getTime() / 1000),
    threeDays = 24*3*3600;

contract('BWRandomizer', function (accounts) {
    let lottery,
        cashier,
        results,
        randomizer,
        management,
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

        results = await Results.new(management.address);
        randomizer = await Randomizer.new(management.address);
    });
    it("random: payable function needs money for oraclize;" +
        "fallback function doesn't work", async function () {

        let activetime = new BigNumber(await lottery.activeGame.call()).valueOf();
        await management.registerContract(1, cashier.address);
        await management.registerContract(2, lottery.address);
        await management.registerContract(3, results.address);
        await management.registerContract(4, randomizer.address);
        await lottery.setResultsContract(results.address);

        await management.setPermission(lottery.address, 0, true);
        await management.setPermission(cashier.address, 3, true);

        let fundationBalance = await Utils.getEtherBalance(fundation);
        let bitWinsABalance = await Utils.getEtherBalance(BitWinsA);
        let bitWinsBBalance = await Utils.getEtherBalance(BitWinsB);
        let applicatureBalance = await Utils.getEtherBalance(Applicature);
        let bitWinsCBalance = await Utils.getEtherBalance(BitWinsC);
        let bitWinsDBalance = await Utils.getEtherBalance(BitWinsD);

        await randomizer.sendTransaction({value: web3.toWei('0.0025', 'ether')})
            .then(Utils.receiptShouldFailed).catch(Utils.catchReceiptShouldFailed);

        await randomizer.random({value: web3.toWei('1', 'ether')})
            .then(Utils.receiptShouldSucceed);

        await lottery.purchase([5, 25, 28, 40, 60], 12, {value: web3.toWei('0.0025', 'ether')})
            .then(Utils.receiptShouldSucceed);
        await lottery.purchase([1, 6, 26, 39, 58], 24, {value: web3.toWei('0.0025', 'ether')})
            .then(Utils.receiptShouldSucceed);
    });
    it("insertionSortMemory:sort numbers", async function () {

        let activetime = new BigNumber(await lottery.activeGame.call()).valueOf();
        await management.registerContract(1, cashier.address);
        await management.registerContract(2, lottery.address);
        await management.registerContract(3, results.address);
        await management.registerContract(4, randomizer.address);
        await lottery.setResultsContract(results.address);

        await management.setPermission(lottery.address, 0, true);
        await management.setPermission(cashier.address, 3, true);


        let sort = await randomizer.insertionSortMemory.call([26, 39, 1, 6, 27])
        assert.equal(sort[0].valueOf(), 1, "sorting doesn't work")
        assert.equal(sort[1].valueOf(), 6, "sorting doesn't work")
        assert.equal(sort[2].valueOf(), 26, "sorting doesn't work")
        assert.equal(sort[3].valueOf(), 27, "sorting doesn't work")
        assert.equal(sort[4].valueOf(), 39, "sorting doesn't work")
    });

    it("check ownerSetOraclizeSafeGas; ownerSetCallbackGasPrice; should run by owner", async function () {

        let activetime = new BigNumber(await lottery.activeGame.call()).valueOf();
        await management.registerContract(1, cashier.address);
        await management.registerContract(2, lottery.address);
        await management.registerContract(3, results.address);
        await management.registerContract(4, randomizer.address);
        await lottery.setResultsContract(results.address);

        await management.setPermission(lottery.address, 0, true);
        await management.setPermission(cashier.address, 3, true);

        assert.equal(await randomizer.gasForOraclize.call(), 235000, "gasForOraclize is not correct")
        await randomizer.ownerSetOraclizeSafeGas(245000)
            .then(Utils.receiptShouldSucceed);
        await randomizer.ownerSetOraclizeSafeGas(246000,{from: accounts[1]})
            .then(Utils.receiptShouldFailed).catch(Utils.catchReceiptShouldFailed);
        assert.equal(new BigNumber(await randomizer.gasForOraclize.call()).valueOf(), 245000, "gasForOraclize is not correct")
        await randomizer.ownerSetCallbackGasPrice(245000)
            .then(Utils.receiptShouldSucceed);
        await randomizer.ownerSetCallbackGasPrice(246000,{from: accounts[1]})
            .then(Utils.receiptShouldFailed).catch(Utils.catchReceiptShouldFailed);
    });
});