const Cashier = artifacts.require('./BWCashier.sol');
const Lottery = artifacts.require("./test/BWLotteryTest.sol");
const Results = artifacts.require("./test/BWResultsTest.sol");
const Management = artifacts.require("./BWManagement.sol");
const Randomizer = artifacts.require("./test/BWRandomizerTest.sol");

const Utils = require("./utils");
const BigNumber = require('bignumber.js');
let startGame = parseInt(new Date().getTime() / 1000),
    threeDays = 24*3*3600,
oneWeek = 604800;

contract('BWLottery', function (accounts) {
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

            await lottery.purchase([5, 25, 28, 40, 60], 12, {value: web3.toWei('0.0025', 'ether')})
                .then(Utils.receiptShouldSucceed);
            await lottery.purchase([5, 25, 80, 40, 60], 12, {value: web3.toWei('0.0025', 'ether')})
                .then(Utils.receiptShouldFailed).catch(Utils.catchReceiptShouldFailed);
            await lottery.purchase([1, 6, 26, 39, 58], 24, {value: web3.toWei('0.0025', 'ether')})
                .then(Utils.receiptShouldSucceed);
            await lottery.purchase([5, 25, 46, 50, 70], 12, {value: web3.toWei('0.0025', 'ether')}).then(Utils.receiptShouldFailed).catch(Utils.catchReceiptShouldFailed);
            await lottery.purchase([5, 25, 46, 50, 58], 29, {value: web3.toWei('0.0025', 'ether')}).then(Utils.receiptShouldFailed).catch(Utils.catchReceiptShouldFailed);
            let a = await management.ticketPrice.call().valueOf();
            assert.equal(a, web3.toWei('0.0025', 'ether').valueOf(), "price is not equal")
            let game = await lottery.games.call(activetime);
            assert.equal(game[0].valueOf(), new BigNumber(web3.toWei('0.005', 'ether')).mul(0.8).valueOf(), "collectedEthers is not equal")
            assert.equal(game[1].valueOf(), 2, "ticketsIssued is not equal")
            assert.equal(game[2].valueOf(), 0, "pb is not equal")
            game = await lottery.getGame.call(activetime);
            assert.equal(game[0].valueOf(), new BigNumber(web3.toWei('0.005', 'ether')).mul(0.8).mul(0.8).valueOf(), "jp is not equal")
            assert.equal(game[1].valueOf(), new BigNumber(web3.toWei('0.005', 'ether')).mul(0.8).valueOf(), "collectedEthers is not equal")
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
            let rez = await results.calculateResult.call(
                [1, 6, 26, 39, 58],
                24,
                [26, 39, 1, 6, 27],
                24,
            )
            console.log('rez', rez);
            await  results.claim(2)
            console.log(new BigNumber(parseInt(new Date().getTime() / 1000)).sub(threeDays).sub(30).sub(new BigNumber(parseInt(new Date().getTime() / 1000))).valueOf());
            // await Utils.timeJump(threeDays);
            // await Utils.timeJump(new BigNumber(parseInt(new Date().getTime() / 1000)).sub(threeDays).sub(30).sub(new BigNumber(parseInt(new Date().getTime() / 1000))));

            a = await Utils.getEtherBalance(results.address)
            assert.equal(a.valueOf(), web3.toWei('0.004', 'ether').valueOf(), "contract balance is not equal")
            await  results.withdrawPrize(new BigNumber(startGame).sub(threeDays).add(200), 2)
                .then(Utils.receiptShouldSucceed);

        });

    it("check prev game transfer", async function () {
        lottery = await Lottery.new(management.address, new BigNumber(startGame).sub(oneWeek).sub(30));
        let activetime = new BigNumber(await lottery.activeGame.call()).valueOf();
        await management.registerContract(1, cashier.address);
        await management.registerContract(2, lottery.address);
        await management.registerContract(3, results.address);
        await management.registerContract(4, randomizer.address);


        await management.setPermission(lottery.address, 0, true);
        await management.setPermission(cashier.address, 3, true);

        await management.setPermission(accounts[0], 3, true);
        await results.defineGameBalance(activetime, {value: web3.toWei('0.0025', 'ether')})
        await lottery.createGame(startGame);
        // await lottery.purchase([5, 25, 28, 40, 60], 12, {value: web3.toWei('0.0025', 'ether')})
        //     .then(Utils.receiptShouldSucceed);
        // game = await lottery.getGame.call(startGame);
        // assert.equal(game[0].valueOf(), new BigNumber(web3.toWei('2', 'ether')).add(new BigNumber(web3.toWei('1', 'ether')).mul(0.8).mul(0.8)).valueOf(), "jp is not equal")
        // assert.equal(game[1].valueOf(), new BigNumber(web3.toWei('1', 'ether')).mul(0.8).valueOf(), "collectedEthers is not equal")
        // assert.equal(game[2].valueOf(), web3.toWei('0.0025', 'ether').valueOf(), "ticketPrice is not equal")
        // assert.equal(game[3].valueOf(), 1, "ticketsIssued is not equal")
        // assert.equal(game[4].valueOf(), 0, "pb is not equal")
        // assert.equal(game[5][0].valueOf(), 0, "resultBalls is not equal")

    })


    it("set results; New game created automaticaly; " +
        "claim  increases reservedAmount; " +
        "duble claim doesn't do  anything" +
        "withdrawPrize  decreases reservedAmount; ",
        async function () {
        let activetime = new BigNumber(await lottery.activeGame.call()).valueOf();
        await management.registerContract(1, cashier.address);
        await management.registerContract(2, lottery.address);
        await management.registerContract(3, results.address);
        await management.registerContract(4, randomizer.address);


        await management.setPermission(lottery.address, 0, true);
        await management.setPermission(cashier.address, 3, true);
        await management.setPermission(accounts[0], 3, true);

        await lottery.purchase([5, 25, 28, 40, 60], 12, {value: web3.toWei('0.0025', 'ether')})
            .then(Utils.receiptShouldSucceed);
        await lottery.purchase([1, 6, 26, 39, 58], 24, {value: web3.toWei('0.0025', 'ether')})
            .then(Utils.receiptShouldSucceed);
        let oldActiveGame = await lottery.activeGame.call();
        await randomizer.__callback(web3.toAscii("0x6574"), "[26, 39, 1, 6, 27, 24]")
        console.log(await randomizer.testArray.call(0).valueOf());
        console.log(await randomizer.testArray.call(1).valueOf());
        console.log(await randomizer.testArray.call(2).valueOf());
        console.log(await randomizer.testArray.call(3).valueOf());
        console.log(await randomizer.testArray.call(4).valueOf());
        console.log(await randomizer.testPb.call().valueOf());
        console.log('newActiveGame', await lottery.activeGame.call());
        assert.notEqual(await lottery.activeGame.call(), oldActiveGame, "activeGame is not equal")

        let rez = await results.calculateResult.call(
            [1, 6, 26, 39, 58],
            24,
            [26, 39, 1, 6, 27],
            24,
        )
        console.log('rez', rez);
        assert.equal(await results.collectedEthers.call().valueOf(), new BigNumber(web3.toWei('0.004', 'ether')).valueOf(), "collectedEthers is not equal")
        await results.claim(2)

        assert.equal(await results.gameReservedPrizes.call(oldActiveGame,0), false, "claim is not equal")
        assert.equal(await results.gameReservedPrizes.call(oldActiveGame,1), false, "claim is not equal")
        assert.equal(await results.gameReservedPrizes.call(oldActiveGame,2), true, "claim is not equal")
        //0.005*10^18*0.8*0.05
        assert.equal(new BigNumber(await results.reservedAmount()).valueOf(), new BigNumber('200000000000000').valueOf(), "reservedAmount is not equal")
        await results.claim(2)
            .then(Utils.receiptShouldFailed).catch(Utils.catchReceiptShouldFailed);
        assert.equal(new BigNumber(await results.reservedAmount()).valueOf(), new BigNumber('200000000000000').valueOf(), "reservedAmount is not equal")
        console.log(new BigNumber(parseInt(new Date().getTime() / 1000)).sub(threeDays).sub(30).sub(new BigNumber(parseInt(new Date().getTime() / 1000))).valueOf());
        assert.equal(await results.collectedEthers.call().valueOf(), new BigNumber(web3.toWei('0.004', 'ether')).valueOf(), "collectedEthers is not equal")
        a = await  Utils.getEtherBalance(results.address)
        assert.equal(a.valueOf(), web3.toWei('0.004', 'ether').valueOf(), "contract balance is not equal")
        await results.withdrawPrize(new BigNumber(startGame).sub(threeDays).add(200), 2)
            .then(Utils.receiptShouldSucceed);
        a = await  Utils.getEtherBalance(results.address)
        assert.equal(a.valueOf(), new BigNumber(web3.toWei('0.004', 'ether')).sub("200000000000000").valueOf(), "contract balance is not equal")
        assert.equal(await results.collectedEthers.call().valueOf(), new BigNumber(web3.toWei('0.004', 'ether')).sub("200000000000000").valueOf(), "collectedEthers is not equal")
        assert.equal(new BigNumber(await results.reservedAmount()).valueOf(), new BigNumber('0').valueOf(), "reservedAmount is not equal")
    });

});