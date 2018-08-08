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

contract('BWCachier', function (accounts) {
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
        lottery = await Lottery.new(management.address, new BigNumber(startGame).sub(oneWeek).add(200));
        cashier = await Cashier.new(management.address, 10000, [fundation, BitWinsA, BitWinsB, Applicature, BitWinsC, BitWinsD], [40, 49, 49, 196, 686, 980]);
        combinations = await Combinations.new(management.address);
        results = await Results.new(management.address);
        randomizer = await Randomizer.new(management.address);
    });
    it("check recordPurchase: transfers ethers to  founders; increases contributed balance", async function () {
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

        await lottery.purchase([5, 25, 28, 40, 60], 12, {value: web3.toWei('0.0025', 'ether')})
            .then(Utils.receiptShouldSucceed);
        await lottery.purchase([1, 6, 26, 39, 58], 24, {value: web3.toWei('0.0025', 'ether')})
            .then(Utils.receiptShouldSucceed);
        await lottery.purchase([1, 6, 26, 39, 58], 24, {value: web3.toWei('0.0024', 'ether')})
            .then(Utils.receiptShouldFailed).catch(Utils.catchReceiptShouldFailed);
        await lottery.purchase([5, 25, 46, 50, 70], 12, {value: web3.toWei('0.0025', 'ether')}).then(Utils.receiptShouldFailed).catch(Utils.catchReceiptShouldFailed);
        // 40, 49, 49, 196, 686, 980
        // console.log('----',web3.toWei('0.0025', 'ether')*2*40/10000);
        await Utils.checkEtherBalance(fundation, new BigNumber(fundationBalance).add(web3.toWei('0.00002', 'ether')));
        await Utils.checkEtherBalance(BitWinsA, bitWinsABalance.add(web3.toWei('0.0000245', 'ether')));
        await Utils.checkEtherBalance(BitWinsB, bitWinsBBalance.add(web3.toWei('0.0000245', 'ether')));
        await Utils.checkEtherBalance(Applicature, applicatureBalance.add(web3.toWei('0.000098', 'ether')));
        await Utils.checkEtherBalance(BitWinsC, bitWinsCBalance.add(web3.toWei('0.000343', 'ether')));
        await Utils.checkEtherBalance(BitWinsD, bitWinsDBalance.add(web3.toWei('0.00049', 'ether')));

        assert.equal(await cashier.balances.call(accounts[0]), web3.toWei('0.005', 'ether').valueOf(), "balance is not equal")
        assert.equal(await cashier.balances.call(accounts[1]), web3.toWei('0', 'ether').valueOf(), "balance is not equal")
        assert.equal(await cashier.balances.call(accounts[2]), web3.toWei('0', 'ether').valueOf(), "balance is not equal")

    });
    it("check update percentages & update address of founders", async function () {
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
        let accountsTwo = await Utils.getEtherBalance(accounts[2]);

        await lottery.purchase([5, 25, 28, 40, 60], 12, {value: web3.toWei('0.0025', 'ether')})
            .then(Utils.receiptShouldSucceed);
        await cashier.updateEtherHolderAddress(0, accounts[2]);
        await cashier.updateEtherHolderPercentages(2, 51)
        assert.equal(await cashier.etherHolders.call(0), accounts[2], "etherHolders is not equal")
        assert.equal(await cashier.percentages.call(2), 51, "percentages is not equal")
        await lottery.purchase([1, 6, 26, 39, 58], 24, {value: web3.toWei('0.0025', 'ether')})
            .then(Utils.receiptShouldSucceed);

        // 40, 49, 49, 196, 686, 980
        // console.log('----',web3.toWei('0.0025', 'ether')*2*40/10000);
        await Utils.checkEtherBalance(fundation, new BigNumber(fundationBalance).add(web3.toWei('0.00001', 'ether')));
        await Utils.checkEtherBalance(accounts[2], new BigNumber(accountsTwo).add(web3.toWei('0.00001', 'ether')));
        await Utils.checkEtherBalance(BitWinsA, bitWinsABalance.add(web3.toWei('0.0000245', 'ether')));
        await Utils.checkEtherBalance(BitWinsB, bitWinsBBalance.add(web3.toWei('0.000025', 'ether')));
        await Utils.checkEtherBalance(Applicature, applicatureBalance.add(web3.toWei('0.000098', 'ether')));
        await Utils.checkEtherBalance(BitWinsC, bitWinsCBalance.add(web3.toWei('0.000343', 'ether')));
        await Utils.checkEtherBalance(BitWinsD, bitWinsDBalance.add(web3.toWei('0.00049', 'ether')));

        assert.equal(await cashier.balances.call(accounts[0]), web3.toWei('0.005', 'ether').valueOf(), "balance is not equal")
        assert.equal(await cashier.balances.call(accounts[1]), web3.toWei('0', 'ether').valueOf(), "balance is not equal")
        assert.equal(await cashier.balances.call(accounts[2]), web3.toWei('0', 'ether').valueOf(), "balance is not equal")

    });

    it("check setGameBalance: forwards all the contract ethereums on result contract;" +
        "should run by randomizer contract", async function () {
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

        await lottery.purchase([5, 25, 28, 40, 60], 12, {value: web3.toWei('0.0025', 'ether')})
            .then(Utils.receiptShouldSucceed);
        await lottery.purchase([1, 6, 26, 39, 58], 24, {value: web3.toWei('0.0025', 'ether')})
            .then(Utils.receiptShouldSucceed);
        // //('0.0025*2)*0.8 = 0.004
        assert.equal(await Utils.getEtherBalance(cashier.address).valueOf(), new BigNumber(web3.toWei('0.004', 'ether')).valueOf(), "contract balance is not equal")
        assert.equal(await Utils.getEtherBalance(results.address).valueOf(), new BigNumber(web3.toWei('0', 'ether')).valueOf(), "contract balance is not equal")
        await cashier.setGameBalance(activetime)
            .then(Utils.receiptShouldFailed).catch(Utils.catchReceiptShouldFailed);
        await randomizer.__callback(web3.toAscii("0x6574"), "[26, 39, 1, 6, 27, 24]")
            .then(Utils.receiptShouldSucceed);
        assert.equal(await Utils.getEtherBalance(cashier.address).valueOf(), new BigNumber(web3.toWei('0', 'ether')).valueOf(), "contract balance is not equal")
        assert.equal(await Utils.getEtherBalance(results.address).valueOf(), new BigNumber(web3.toWei('0.004', 'ether')).valueOf(), "contract balance is not equal")
    });

})