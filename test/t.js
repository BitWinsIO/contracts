const Cashier = artifacts.require('./BWCashier.sol');
const Lottery = artifacts.require("./test/BWLotteryTest.sol");
const Results = artifacts.require("./test/BWResultsTest.sol");
const Management = artifacts.require("./BWManagement.sol");
const Combinations = artifacts.require("./BWCombinations.sol");
const Randomizer = artifacts.require("./test/BWRandomizerTest.sol");

const Utils = require("./utils");
const BigNumber = require('bignumber.js');
let startGame = parseInt(new Date().getTime() / 1000),
    oneWeek = 604800;

contract('BWLottery', function (accounts) {
    console.log(web3.version.api);
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
        lottery = await Lottery.new(management.address, new BigNumber(startGame).sub(oneWeek).add(20));
        cashier = await Cashier.new(management.address, 10000, [fundation, BitWinsA, BitWinsB, Applicature, BitWinsC, BitWinsD], [40,49, 49, 196, 686,980]);
        combinations = await Combinations.new(management.address);
        results = await Results.new(management.address);
        randomizer = await Randomizer.new(management.address);
    });
/*
    it("check state", async function () {
        let activetime = new BigNumber(await lottery.activeGame.call()).valueOf();
        await management.registerContract(1, cashier.address);
        await management.registerContract(2, lottery.address);
        await management.registerContract(3, results.address);
        await management.registerContract(4, combinations.address);
        await management.registerContract(5, randomizer.address);
        await lottery.setResultsContract(results.address);

        await management.setPermission(lottery.address, 0, true);
        await management.setPermission(cashier.address, 3, true);

        await lottery.purchase([5, 25, 28, 40, 60], 12, {value: web3.toWei('1', 'ether')})
            .then(Utils.receiptShouldSucceed);
        await lottery.purchase([1, 6, 26, 39, 58], 24, {value: web3.toWei('1', 'ether')})
            .then(Utils.receiptShouldSucceed);
        await lottery.purchase([5, 25, 46, 50, 70], 12, {value: web3.toWei('1', 'ether')}).then(Utils.receiptShouldFailed).catch(Utils.catchReceiptShouldFailed);
        await lottery.purchase([5, 25, 46, 50, 58], 29, {value: web3.toWei('1', 'ether')}).then(Utils.receiptShouldFailed).catch(Utils.catchReceiptShouldFailed);
        let a = await lottery.ticketPrice.call().valueOf();
        assert.equal(a, web3.toWei('0.0025', 'ether').valueOf(), "contributionRange is not equal")
        let game = await lottery.lotteries.call(activetime);
        assert.equal(game[0].valueOf(), new BigNumber(web3.toWei('2', 'ether')).mul(0.8).valueOf(), "collectedEthers is not equal")
        assert.equal(game[1].valueOf(), 2, "ticketsIssued is not equal")
        assert.equal(game[2].valueOf(), 0, "pb is not equal")
        game = await lottery.getGame.call(activetime);
        assert.equal(game[0].valueOf(), new BigNumber(web3.toWei('2', 'ether')).mul(0.8).mul(0.8).valueOf(), "jp is not equal")
        assert.equal(game[1].valueOf(), new BigNumber(web3.toWei('2', 'ether')).mul(0.8).valueOf(), "collectedEthers is not equal")
        assert.equal(game[2].valueOf(), web3.toWei('0.0025', 'ether').valueOf(), "ticketPrice is not equal")
        assert.equal(game[3].valueOf(), 2, "ticketsIssued is not equal")
        assert.equal(game[4].valueOf(), 0, "pb is not equal")
        assert.equal(game[5][0].valueOf(), 0, "resultBalls is not equal")

        // await randomizer.randomTest({value: web3.toWei('1', 'ether')})
        // console.log(new BigNumber(await randomizer.randomInt.call()).valueOf());
        // await Utils.timeJump(30);
        // // await randomizer.random({value: web3.toWei('1', 'ether')})
        // // const logRandomUpdate = randomizer.LogRandomUpdate({fromBlock: 0, toBlock: 'latest'})
        await randomizer.__callback(web3.toAscii("0x6574"), "[26, 39, 1, 6, 27, 24]")
        console.log(await randomizer.testArray.call(0).valueOf());
        console.log(await randomizer.testArray.call(1).valueOf());
        console.log(await randomizer.testArray.call(2).valueOf());
        console.log(await randomizer.testArray.call(3).valueOf());
        console.log(await randomizer.testArray.call(4).valueOf());
        console.log(await randomizer.testPb.call().valueOf());
        await randomizer.__callback(web3.toAscii("0x6574"), "[26, 39, 1, 6, 27, 24]")
            .then(Utils.receiptShouldFailed)
            .catch(Utils.catchReceiptShouldFailed);
        let rez = await results.calculateResult.call(
            [1, 6, 26, 39, 58],
            24,
            [26, 39, 1, 6, 27],
            24,
        )
        console.log('rez', rez);
        await  results.claim(2)
        console.log(new BigNumber(parseInt(new Date().getTime() / 1000)).sub(oneWeek).sub(30).sub(new BigNumber(parseInt(new Date().getTime() / 1000))).valueOf());
        // await Utils.timeJump(oneWeek);
        // await Utils.timeJump(new BigNumber(parseInt(new Date().getTime() / 1000)).sub(oneWeek).sub(30).sub(new BigNumber(parseInt(new Date().getTime() / 1000))));

        a = await  results.getContractBalance.call()
        assert.equal(a.valueOf(), web3.toWei('1.6', 'ether').valueOf(), "contract balance is not equal")
        await  results.withdrowPrize(new BigNumber(startGame).sub(oneWeek).add(20), 2)
            .then(Utils.receiptShouldSucceed);

    });
*/
    it("check prev game transfer", async function () {
        lottery = await Lottery.new(management.address, new BigNumber(startGame).sub(oneWeek).sub(30));
        let activetime = new BigNumber(await lottery.activeGame.call()).valueOf();
        await management.registerContract(1, cashier.address);
        await management.registerContract(2, lottery.address);
        await management.registerContract(3, results.address);
        await management.registerContract(4, combinations.address);
        await management.registerContract(5, randomizer.address);
        await lottery.setResultsContract(results.address);

        await management.setPermission(lottery.address, 0, true);
        await management.setPermission(cashier.address, 3, true);

        await management.setPermission(accounts[0], 3, true);
        await results.increaseGameBalance(activetime, {value: web3.toWei('2', 'ether')})
        await lottery.createGame(startGame);
        await lottery.purchase([5, 25, 28, 40, 60], 12, {value: web3.toWei('1', 'ether')})
            .then(Utils.receiptShouldSucceed);
        game = await lottery.getGame.call(startGame);
        assert.equal(game[0].valueOf(), new BigNumber(web3.toWei('2', 'ether')).add(new BigNumber(web3.toWei('1', 'ether')).mul(0.8).mul(0.8)).valueOf(), "jp is not equal")
        assert.equal(game[1].valueOf(), new BigNumber(web3.toWei('1', 'ether')).mul(0.8).valueOf(), "collectedEthers is not equal")
        assert.equal(game[2].valueOf(), web3.toWei('0.0025', 'ether').valueOf(), "ticketPrice is not equal")
        assert.equal(game[3].valueOf(), 1, "ticketsIssued is not equal")
        assert.equal(game[4].valueOf(), 0, "pb is not equal")
        assert.equal(game[5][0].valueOf(), 0, "resultBalls is not equal")

    })

});