var BigNumber = require('bignumber.js');
var abi = require('ethereumjs-abi');

var gasToUse = 0x47E7C4;

function receiptShouldSucceed(result) {
    return new Promise(function(resolve, reject) {
        var receipt = web3.eth.getTransaction(result.tx);

        if(result.receipt.gasUsed == gasToUse) {
            try {
                assert.notEqual(result.receipt.gasUsed, gasToUse, "tx failed, used all gas");
            }
            catch(err) {
                reject(err);
            }
        }
        else {
            console.log('gasUsed',result.receipt.gasUsed);
            resolve();
        }
    });
}

function receiptShouldFailed(result) {
    return new Promise(function(resolve, reject) {
        var receipt = web3.eth.getTransaction(result.tx);

        if(result.receipt.gasUsed == gasToUse) {
            resolve();
        }
        else {
            try {
                assert.equal(result.receipt.gasUsed, gasToUse, "tx succeed, used not all gas");
            }
            catch(err) {
                reject(err);
            }
        }
    });
}

function catchReceiptShouldFailed(err) {
    function catchReceiptShouldFailed(err) {
        if (err.message.indexOf("invalid opcode") == -1 && err.message.indexOf("revert") == -1) {
            throw err;
        }
    }
}

function balanceShouldEqualTo(instance, address, expectedBalance, notCall) {
    return new Promise(function(resolve, reject) {
        var promise;

        if(notCall) {
            promise = instance.balanceOf(address)
                .then(function() {
                    return instance.balanceOf.call(address);
                });
        }
        else {
            promise = instance.balanceOf.call(address);
        }

        promise.then(function(balance) {
            try {
                assert.equal(balance.valueOf(), expectedBalance, "balance is not equal");
            }
            catch(err) {
                reject(err);

                return;
            }

            resolve();
        });
    });
}

function timeout(timeout) {
    return new Promise(function(resolve, reject) {
        setTimeout(function() {
            resolve();
        }, timeout * 1000);
    })
}

function getEtherBalance(_address) {
    return web3.eth.getBalance(_address);
}

function checkEtherBalance(_address, expectedBalance) {
    var balance = web3.eth.getBalance(_address);

    assert.equal(balance.valueOf(), expectedBalance.valueOf(), "address balance is not equal");
}

function getTxCost(result) {
    var tx = web3.eth.getTransaction(result.tx);

    return result.receipt.gasUsed * tx.gasPrice;
}

async function checkStateMethod(contract, contractId, stateId, args) {
    if(Array.isArray(args)) {
        for(let item of args) {
            await checkStateMethod(contract, contractId, stateId, item);
        }
    }
    else if(typeof args == "object" && args.constructor.name != "BigNumber") {
        const keys = Object.keys(args);

        if(keys.length == 1) {
            const val = (await contract[stateId].call(keys[0])).valueOf();

            assert.equal(val, args[keys[0]],
                `Contract ${contractId} state ${stateId} with arg ${keys[0]} & value ${val} is not equal to ${args[keys[0]]}`);

            return;
        }

        const passArgs = [];

        if(! args.hasOwnProperty("__val")) {
            assert.fail(new Error("__val is not present"));
        }

        for(let arg of Object.keys(args)) {
            if(arg == "__val") {
                continue;
            }

            passArgs.push(args[arg]);
        }

        const val = (await contract[stateId].call( ...passArgs )).valueOf();

        assert.equal(val, args["__val"], `Contract ${contractId} state ${stateId} with value ${val} is not equal to ${args['__val']}`);
    }
    else {
        const val = (await contract[stateId].call()).valueOf();

        assert.equal(val, args, `Contract ${contractId} state ${stateId} with value ${val} is not equal to ${args.valueOf()}`);
    }
}

async function checkState(contracts, states) {
    for(let contractId in states) {
        if(! contracts.hasOwnProperty(contractId)) {
            assert.fail("no such contract " + contractId);
        }

        let contract = contracts[contractId];

        for(let stateId in states[contractId]) {
            if(! contract.hasOwnProperty(stateId)) {
                assert.fail("no such property " + stateId);
            }

            await checkStateMethod(contract, contractId, stateId, states[contractId][stateId]);
        }
    }
}
module.exports = {
    receiptShouldSucceed: receiptShouldSucceed,
    receiptShouldFailed: receiptShouldFailed,
    catchReceiptShouldFailed: catchReceiptShouldFailed,
    balanceShouldEqualTo: balanceShouldEqualTo,
    timeout: timeout,
    getEtherBalance: getEtherBalance,
    checkEtherBalance: checkEtherBalance,
    getTxCost: getTxCost,
    checkState: checkState,
};