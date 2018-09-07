const Cashier = artifacts.require('./BWCashier.sol');
const Lottery = artifacts.require("./test/BWLotteryTest.sol");
const Results = artifacts.require("./test/BWResultsTest.sol");
const Management = artifacts.require("./BWManagement.sol");

const Randomizer = artifacts.require("./test/BWRandomizerTest.sol");

const Utils = require("./utils");
const BigNumber = require('bignumber.js');
let startGame = parseInt(new Date().getTime() / 1000),
    threeDays = 24*3*3600;

contract('BWManagement', function (accounts) {
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

    it("check state", async function () {
        let activetime = new BigNumber(await lottery.activeGame.call()).valueOf();
        await management.registerContract(1, cashier.address);
        await management.registerContract(2, lottery.address);
        await management.registerContract(3, results.address);
        await management.registerContract(4, randomizer.address);


        await management.setPermission(lottery.address, 0, true);
        await management.setPermission(cashier.address, 3, true);
        let a = await management.ticketPrice.call().valueOf();
        assert.equal(a, web3.toWei('0.0025', 'ether').valueOf(), "price is not equal")
        await management.setNewPrice(web3.toWei('0.0027', 'ether'), {from: accounts[1]})
            .then(Utils.receiptShouldFailed).catch(Utils.catchReceiptShouldFailed);
        await management.setNewPrice(web3.toWei('0.0028', 'ether'))
            .then(Utils.receiptShouldSucceed);
        await management.setNewPrice(web3.toWei('0', 'ether'))
            .then(Utils.receiptShouldFailed).catch(Utils.catchReceiptShouldFailed);
        assert.equal(await management.ticketPrice.call().valueOf(), web3.toWei('0.0028', 'ether').valueOf(), "price is not equal")

        assert.equal(await management.maxBallNumber.call().valueOf(), 69, "maxBall is not equal")
        await management.setMaxBall(45);
        await management.setMaxBall(1, {from: accounts[0]})
            .then(Utils.receiptShouldFailed).catch(Utils.catchReceiptShouldFailed);
        await management.setMaxBall(50, {from: accounts[5]})
    .then(Utils.receiptShouldFailed).catch(Utils.catchReceiptShouldFailed);
        assert.equal(await management.maxBallNumber.call().valueOf(), 45, "maxBall is not equal")

        assert.equal(await management.maxPowerBall.call().valueOf(), 26, "maxPBall is not equal")
        await management.setMaxPowerBall(45);
        await management.setMaxPowerBall(1, {from: accounts[0]})
            .then(Utils.receiptShouldFailed).catch(Utils.catchReceiptShouldFailed);
        await management.setMaxPowerBall(50, {from: accounts[5]})
            .then(Utils.receiptShouldFailed).catch(Utils.catchReceiptShouldFailed);
        assert.equal(await management.maxPowerBall.call().valueOf(), 45, "maxPBall is not equal")


        assert.equal(await management.autoStartNextGame.call().valueOf(), true, "autoStartNextGame is not equal")
        await management.setAutoStartNextGame(false);
        await management.setAutoStartNextGame(true, {from: accounts[5]})
            .then(Utils.receiptShouldFailed).catch(Utils.catchReceiptShouldFailed);
        assert.equal(await management.autoStartNextGame.call().valueOf(), false, "autoStartNextGame is not equal")

        assert.equal(await management.payoutsPerCategory.call(1).valueOf(), 80, "payoutsPerCategory isn't equal")
        await management.setPayoutsPerCategory(1, 78);
        await management.setPayoutsPerCategory(1, 105)
            .then(Utils.receiptShouldFailed).catch(Utils.catchReceiptShouldFailed);
        await management.setPayoutsPerCategory(1,75, {from: accounts[5]})
            .then(Utils.receiptShouldFailed).catch(Utils.catchReceiptShouldFailed);
        assert.equal(await management.payoutsPerCategory.call(1).valueOf(), 78, "payoutsPerCategory isn't equal")
    });
});