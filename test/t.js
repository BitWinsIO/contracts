const Cashier = artifacts.require('./BWCashier.sol');
const Lottery = artifacts.require("./test/BWLotteryTest.sol");
const Results = artifacts.require("./BWResults.sol");
const Management = artifacts.require("./BWManagement.sol");
const Combinations = artifacts.require("./BWCombinations.sol");
const Randomizer = artifacts.require("./test/BWRandomizerTest.sol");

const Utils = require("./utils");
const BigNumber = require('bignumber.js');
let startGame = parseInt(new Date().getTime() / 1000),
    oneWeek= 604800;

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
        fundation= accounts[3],
        Applicature= accounts[4],
        Drew= accounts[5],
        Rayan= accounts[6];

    beforeEach(async function () {

        management = await Management.new();
        lottery = await Lottery.new(management.address,new BigNumber(10).mul(precision).valueOf(), new BigNumber(startGame).sub(oneWeek).add(20));
        cashier = await Cashier.new(management.address, [fundation,Applicature,Drew,Rayan],[2,2,7,11]);
        combinations = await Combinations.new(management.address);
        results = await Results.new(management.address);
        randomizer = await Randomizer.new(management.address);
    });

    it("check state", async function () {
        let activetime = new BigNumber(await lottery.activeGame.call()).valueOf();
        await management.registerContract(1, cashier.address);
        await management.registerContract(2, lottery.address);
        await management.registerContract(3, results.address);
        await management.registerContract(4, combinations.address);
        await management.registerContract(5, randomizer.address);

        await management.setPermission(lottery.address,0,true);
        await lottery.purchase([5,25,28,40,60], 12,{value: web3.toWei('1', 'ether')})
            .then(Utils.receiptShouldSucceed);
        await lottery.purchase([1, 6, 26, 39, 58], 24, {value: web3.toWei('1', 'ether')})
            .then(Utils.receiptShouldSucceed);
        await lottery.purchase([5, 25, 46, 50, 70], 12, {value: web3.toWei('1', 'ether')}).then(Utils.receiptShouldFailed).catch(Utils.catchReceiptShouldFailed);
        await lottery.purchase([5, 25, 46, 50, 58], 29, {value: web3.toWei('1', 'ether')}).then(Utils.receiptShouldFailed).catch(Utils.catchReceiptShouldFailed);
        let a =await lottery.ticketPrice.call().valueOf();
        assert.equal(a, web3.toWei('0.0025', 'ether').valueOf(), "contributionRange is not equal")
        let game =await lottery.lotteries.call(activetime);
        assert.equal(game[0].valueOf(), new BigNumber(10).mul(precision).valueOf(), "jackpot is not equal")
        assert.equal(game[1].valueOf(), web3.toWei('2', 'ether').valueOf(), "collectedEthers is not equal")
        assert.equal(game[2].valueOf(), 2, "ticketsIssued is not equal")
        assert.equal(game[3].valueOf(), 0, "pb is not equal")
        game = await lottery.getGame.call(activetime);
        assert.equal(game[0].valueOf(), new BigNumber(10).mul(precision).valueOf(), "jackpot is not equal")
        assert.equal(game[1].valueOf(), web3.toWei('2', 'ether').valueOf(), "collectedEthers is not equal")
        assert.equal(game[3].valueOf(), 2, "ticketsIssued is not equal")
        assert.equal(game[4].valueOf(), 0, "pb is not equal")
        assert.equal(game[5][0].valueOf(), 0, "resultBalls is not equal")

        // await randomizer.randomTest({value: web3.toWei('1', 'ether')})
        // console.log(new BigNumber(await randomizer.randomInt.call()).valueOf());



            await Utils.timeJump(30);
        // // await randomizer.random({value: web3.toWei('1', 'ether')})
        // // const logRandomUpdate = randomizer.LogRandomUpdate({fromBlock: 0, toBlock: 'latest'})
        await randomizer.__callback(web3.toAscii("0x6574"), "[26, 39, 1, 6, 27, 24]")
        console.log(await randomizer.testArray.call(0).valueOf());
        console.log(await randomizer.testArray.call(1).valueOf());
        console.log(await randomizer.testArray.call(2).valueOf());
        console.log(await randomizer.testArray.call(3).valueOf());
        console.log(await randomizer.testArray.call(4).valueOf());
        console.log(await randomizer.testPb.call().valueOf());
        let b = await lottery.getGame.call(new BigNumber(startGame).sub(oneWeek).add(20))
        console.log(b[4]);
        await randomizer.__callback(web3.toAscii("0x6574"), "[26, 39, 1, 6, 27, 24]")
            .then(Utils.receiptShouldFailed)
            .catch(Utils.catchReceiptShouldFailed);
        let rez =  await results.calculateResult.call(
            [1, 6, 26, 39, 58],
            24,
            [26, 39, 1, 6, 27],
            24,
        )
        console.log('rez',rez);
        await  results.claim(2)
        console.log(new BigNumber(parseInt(new Date().getTime() / 1000)).sub(oneWeek).sub(30).sub(new BigNumber(parseInt(new Date().getTime() / 1000))).valueOf());
        await Utils.timeJump(oneWeek);
        await Utils.timeJump(new BigNumber(parseInt(new Date().getTime() / 1000)).sub(oneWeek).sub(30).sub(new BigNumber(parseInt(new Date().getTime() / 1000))));
        await  results.withdrowPrize(new BigNumber(startGame).sub(oneWeek).add(20), 2)
            .then(Utils.receiptShouldFailed)
        // create promise so Mocha waits for value to be returned
        // let checkForNumber = new Promise((resolve, reject) => {
        // //     // watch for our logRandomUpdate event
        //     logRandomUpdate.watch(async function(error, result) {
        //         if (error) {
        //             reject(error)
        //         }
        //         await randomizer.random({value: web3.toWei('1', 'ether')})
        //         // template.randomNumber() returns a BigNumber object
        //         const bigNumber = await randomizer.randomInt.call()
        //         // convert BigNumber to ordinary number
        //         let randomNumber = bigNumber.toNumber()
        //         // stop watching event and resolve promise
        //         logRandomUpdate.stopWatching()
        //         resolve(randomNumber)
        //     }) // end LogResultReceived.watch()
        // }) // end new Promise

        // call promise and wait for result
        // const randomNumber = await checkForNumber
        // console.log('randomNumber',randomNumber);




        //
        // await randomizer.randomTest({value: web3.toWei('1', 'ether')})
        //     .then(Utils.receiptShouldFailed)
    });
});