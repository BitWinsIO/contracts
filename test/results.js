const Cashier = artifacts.require('./BWCashier.sol');
const Lottery = artifacts.require("./test/BWLotteryTest.sol");
const Results = artifacts.require("./test/BWResultsTest.sol");
const Management = artifacts.require("./BWManagement.sol");
const Randomizer = artifacts.require("./test/BWRandomizerTest.sol");

const Utils = require("./utils");
const BigNumber = require('bignumber.js');
let startGame = parseInt(new Date().getTime() / 1000),
    threeDays = 24*3*3600;

contract('BWResults', function (accounts) {
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
    it("check calculateResult function", async function () {

        let activetime = new BigNumber(await lottery.activeGame.call()).valueOf();
        await management.registerContract(1, cashier.address);
        await management.registerContract(2, lottery.address);
        await management.registerContract(3, results.address);
        await management.registerContract(4, randomizer.address);


        await management.setPermission(lottery.address, 0, true);
        await management.setPermission(cashier.address, 3, true);

        let resultCheck = await results.calculateResult([5, 25, 28, 40, 60], 12, [5, 25, 28, 40, 60], 12);
        assert.equal(resultCheck.valueOf(), 1, "calculateResult is not equal")
        resultCheck = await results.calculateResult([5, 25, 28, 40, 60], 12, [5, 7, 28, 40, 60], 12);
        assert.equal(resultCheck.valueOf(), 3, "calculateResult is not equal")
        resultCheck = await results.calculateResult([5, 7, 28, 40, 60], 5, [5, 7, 28, 40, 60], 12);
        assert.equal(resultCheck.valueOf(), 2, "calculateResult is not equal")

        resultCheck = await results.calculateResult([5, 7, 30, 40, 60], 12, [7, 5, 40, 30, 60], 12);
        assert.equal(resultCheck.valueOf(), 1, "calculateResult is not equal")

        resultCheck = await results.calculateResult([5, 6, 28, 40, 60], 5, [5, 7, 28, 40, 60], 12);
        assert.equal(resultCheck.valueOf(), 0, "calculateResult is not equal")
        resultCheck = await results.calculateResult([5, 6, 9, 40, 60], 12, [5, 7, 28, 40, 60], 12);
        assert.equal(resultCheck.valueOf(), 0, "calculateResult is not equal")
    });

    it("check defineGameBalance", async function () {
        let activetime = new BigNumber(await lottery.activeGame.call()).valueOf();
        await management.registerContract(1, cashier.address);
        await management.registerContract(2, lottery.address);
        await management.registerContract(3, results.address);
        await management.registerContract(4, randomizer.address);


        await management.setPermission(lottery.address, 0, true);
        await management.setPermission(cashier.address, 3, true);

        await results.defineGameBalance(activetime, {value: web3.toWei('0.0025', 'ether')})
            .then(Utils.receiptShouldFailed).catch(Utils.catchReceiptShouldFailed);
        await management.setPermission(accounts[0], 3, true);
        await results.defineGameBalance(activetime, {value: web3.toWei('0.0025', 'ether')})
            .then(Utils.receiptShouldSucceed);
        assert.equal(await results.gameBalances.call(activetime), web3.toWei('0.0025', 'ether'), 'gameBalances in not equal');
        await results.defineGameBalance(activetime, {value: web3.toWei('0.0025', 'ether')})
            .then(Utils.receiptShouldFailed).catch(Utils.catchReceiptShouldFailed);
        assert.equal(await results.gameBalances.call(activetime), web3.toWei('0.0025', 'ether'), 'gameBalances in not equal');

        await lottery.purchase([5, 25, 28, 40, 60], 12, {value: web3.toWei('0.0025', 'ether'), from:accounts[0]})
            .then(Utils.receiptShouldSucceed);
        await lottery.purchase([1, 6, 26, 39, 58], 24, {value: web3.toWei('0.0025', 'ether'), from:accounts[1]})
            .then(Utils.receiptShouldSucceed);
        await lottery.purchase([1, 6, 26, 39, 58], 24, {value: web3.toWei('0.0025', 'ether'), from:accounts[2]})
            .then(Utils.receiptShouldSucceed);

    });

    it("check claim & withdrawPrize", async function () {
        let activetime = new BigNumber(await lottery.activeGame.call()).valueOf();
        await management.registerContract(1, cashier.address);
        await management.registerContract(2, lottery.address);
        await management.registerContract(3, results.address);
        await management.registerContract(4, randomizer.address);


        await management.setPermission(lottery.address, 0, true);
        await management.setPermission(cashier.address, 3, true);

        //4+pb
        await lottery.purchase([6, 1, 26, 27, 29], 24, {value: web3.toWei('0.0025', 'ether'), from:accounts[0]})
            .then(Utils.receiptShouldSucceed);
        //4+pb
        await lottery.purchase([1, 6, 26, 27, 34], 24, {value: web3.toWei('0.0025', 'ether'), from:accounts[1]})
            .then(Utils.receiptShouldSucceed);
        //5+pb
        await lottery.purchase([1, 6, 26, 27, 39], 24, {value: web3.toWei('0.0025', 'ether'), from:accounts[2]})
            .then(Utils.receiptShouldSucceed);
        //0
        await lottery.purchase([1, 6, 29, 39, 45], 24, {value: web3.toWei('0.0025', 'ether'), from:accounts[2]})
            .then(Utils.receiptShouldSucceed);
        await randomizer.__callback(web3.toAscii("0x6574"), "[26, 39, 1, 6, 27, 24]")
        console.log(await randomizer.testArray.call(0).valueOf());
        console.log(await randomizer.testArray.call(1).valueOf());
        console.log(await randomizer.testArray.call(2).valueOf());
        console.log(await randomizer.testArray.call(3).valueOf());
        console.log(await randomizer.testArray.call(4).valueOf());
        console.log(await randomizer.testPb.call().valueOf());

        await  results.claim(1)
            .then(Utils.receiptShouldSucceed);
        // await  results.claim(2)
        //     .then(Utils.receiptShouldSucceed);
        // await  results.claim(3)
        //     .then(Utils.receiptShouldSucceed);
        // await  results.claim(4)
        //     .then(Utils.receiptShouldFailed)
        //     .catch(Utils.catchReceiptShouldFailed)
        // a = await  results.getContractBalance.call()
        // assert.equal(a.valueOf(), new BigNumber (web3.toWei('0.01', 'ether')).mul(80).div(100).valueOf(), "contract balance is not equal")
        // await  results.withdrawPrize( new BigNumber(startGame).sub(threeDays).add(200), 1)
        //     .then(Utils.receiptShouldSucceed);
        // // 0.01*0.8-0.01*0.8*0.05/2= 0.0078 // 0.0002
        // assert.equal(new BigNumber(await  results.getContractBalance.call()).valueOf(), new BigNumber(web3.toWei('0.01', 'ether')).mul(80).div(100).sub(web3.toWei('0.0002', 'ether')).valueOf(), "contract balance is not equal")
        // await  results.withdrawPrize( new BigNumber(startGame).sub(threeDays).add(200), 3)
        //     .then(Utils.receiptShouldSucceed);
        // // 0.01*0.8-0.01*0.8*0.8 = 0.0016 // 0.0064
        // // 0.01*0.8 -0.0064-0.0002 =0.0014
        // assert.equal(new BigNumber(await results.getContractBalance.call()).valueOf(), new BigNumber(web3.toWei('0.0014', 'ether')).valueOf(), "contract balance is not equal")

    });
});