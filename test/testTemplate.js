//  To run the tests, the most efficient way is to run
//  `truffle develop`  and then  `test`

//  Storing the result of every 'await' in a 
//  variable will probably increase runtime.
//  See: 
//  https://stackoverflow.com/questions/65178324/why-should-we-store-promise-objects-in-variables


const Crowdsale = artifacts.require("Crowdsale");
const Queue = artifacts.require("Queue");
const Token = artifacts.require("Token");
var Web3 = require('web3');
var web3 = new Web3(Web3.givenProvider || 'ws://localhost:7545');

// This should be the same as the `queueSize` variable of the
// `migrations/1_deploy_all.js` file
var queueSize = 5;


describe("Deployment", async () => {
  it("The Crowdsale Contract should deploy a Queue and a Token contract", async () => {
    const crowdsale = await Crowdsale.deployed();
    const queue     = await Queue.at(await crowdsale.queue());
    const token     = await Token.at(await crowdsale.token());
    assert.equal(queue.address, await crowdsale.queue());
    assert.equal(token.address, await crowdsale.token());
  });
});

// We only want to check the Queue contract. BUT:
// 1. The Queue contract has functions that only it's owner can execute.
// 2. The Queue contract was INITIALLY NOT deployed (explicitly) in 
// our `migrations/1_deploy_all.js` migration file.
// (The reason for that was that in the project we want the Crowdsale 
// contract to be the owner of the Queue contract.) 
// For those reasons above, a Queue deployment was added in the 
// `migrations/1_deploy_all.js` file, resulting in 2 Queue contracts.
// One of them is owned by the Crowdsale contract and the other by an EOA account
// (defaults to accounts[0])



contract("Queue", async () => {
  let q = await Queue.deployed();
  let accounts = await web3.eth.getAccounts();
  // the time that each buyer is allowed to stay in first place.
  // we need that to set the timeout of some tests. 
  // Why do we need to set a timeout?
  // The 'timeout' has been added to some 'it' tests to face the below issue:
  // "Timeout of 2000ms exceeded. For async tests and hooks, 
  // ensure "done()" is called; if returning a Promise, ensure it resolves"
  // 2 things cause this error: the Queue.enqueue() function and a function called
  // 'delay()' which is defined and used later in this test file, to check the 
  // Queue.checkTime() function.
  const timelimit = await q.TIMELIMIT();
  
  
  describe('Queue - Core functionality', async () => {
    
    it("should be empty at start", async () => {
      let q = await Queue.deployed();
      // an empty queue will have the address 0x00..0 in the position of the head 
      assert.match(await q.getFirst(), /^0x[0]+/);
      assert.isTrue(await q.empty());
      assert.equal(0, await q.qsize());
    });
    
    it("should allow enqueue and dequeue operations to owner only.", async () => {
      for (let i=1; i<accounts.length; i++) {
        try {
          await q.enqueue(accounts[i], {from: accounts[i]});
          assert.fail('enqueue() should be owner-only.');
        }
        catch(error){
          assert.include(error.message, 'revert');
          assert.include(error.message, "ONLY OWNERS CAN DO THAT");
        }
        try {
          await q.dequeue({from: accounts[i]});
          assert.fail('dequeue() should be owner-only.');
        }
        catch(error){
          assert.include(error.message, 'revert');
          assert.include(error.message, "ONLY OWNERS CAN DO THAT");
        }
      }
    }).timeout(10000);
    
    
    it("should enqueue "+queueSize+" elements", async () => {
      // enqueue queueSize elements
      // |_H_|___|___|___|_T_|
      // | 1 | 2 | 3 | 4 | 5 |    
      for (let i=1; i<=queueSize; i++)
        await q.enqueue(accounts[i]);
    }).timeout(10000);
    
    it("should not enqueue more than "+queueSize+" elements", async () => {
      try {
        await q.enqueue(accounts[9]);
        assert.fail('Should not enqueue more than queueSize elements');
      }
      catch(error) {
        assert.include(error.message, 'revert');
        assert.include(error.message, "QUEUE IS FULL");
      }
    });

    it("should dequeue "+queueSize+" elements.", async () => {  
      // dequeue all but the last one
      // |_H_|___|___|___|_T_|   -->   |___|___|___|___|_H_T_|
      // | 1 | 2 | 3 | 4 | 5 |   -->   |   |   |   |   |  5  |
      for (let i=1; i<queueSize;  i++) {
        assert.equal(accounts[i], await q.getFirst());
        assert.equal(accounts[queueSize], await q.getLast());
        assert.isFalse(await q.empty());
        assert.equal(1, (await q.checkPlace(accounts[i])).toNumber());
        await q.dequeue();
        assert.equal(queueSize-i, await q.qsize());
      }
      assert.equal(1, await q.qsize());
      assert.isFalse(await q.empty());
      assert.notMatch(await q.getFirst(), /^0x[0]+/);
      assert.equal(await q.getFirst(), await q.getLast());    
      // dequeue the last one too
      // |___|___|___|___|_H_T_|  -->   |___|___|___|___|_H_T_|
      // |   |   |   |   |  5  |  -->   |   |   |   |   | 0x0 |
      await q.dequeue();
      assert.equal(0, await q.qsize());
      assert.isTrue(await q.empty());
      assert.match(await q.getFirst(), /^0x[0]+/);
      assert.equal(await q.getFirst(), await q.getLast());
    }).timeout(10000);

    
    it("should not enqueue the same element twice", async () => {
      await q.enqueue(accounts[1]);
      try {
        await q.enqueue(accounts[1]);
        await q.dequeue();
        assert.fail('Should not enqueue the same element twice');
      }
      catch(error){
        assert.include(error.message, 'revert');
        assert.include(error.message, "ELEMENT ALREADY IN QUEUE");
      }
      await q.dequeue();
    }).timeout(10000);
    
  }).timeout(40000);

  
  describe("Queue - For each of the following tests\n"+
    "\tnot only should enqueue and dequeue work as expected but\n"+
    "\talso functions getFirst, getLast, empty, qsize and checkPlace\n", async () =>  {
    
    // Note: You may need to check the definition of the
    //       function Queue.checkPlace()  

    // |_H_T_|___|___|___|___|
    // |  1  |   |   |   |   |
    it("enqueue accounts[1]", async () => {
      await q.enqueue(accounts[1]);
      assert.equal(accounts[1], await q.getFirst());
      assert.equal(await q.getFirst(), await q.getLast());
      assert.equal(1, await q.qsize());
      assert.isFalse(await q.empty());
      assert.equal(0, (await q.checkPlace(accounts[0])).toNumber());
      assert.equal(0, (await q.checkPlace(accounts[2])).toNumber());
      assert.equal(1, (await q.checkPlace(accounts[1])).toNumber());
    });

    // |_H_T_|___|___|___|___|  -->   |_H_|___|_T_|___|___|
    // |  1  |   |   |   |   |  -->   | 1 | 2 | 3 |   |   |
    it("enqueue accounts[2] and accounts[3]", async () => {
      await q.enqueue(accounts[2]);
      await q.enqueue(accounts[3]);
      assert.equal(accounts[1], await q.getFirst());
      assert.equal(accounts[3], await q.getLast());
      assert.equal(3, await q.qsize());
      assert.isFalse(await q.empty());
      assert.equal(0, (await q.checkPlace(accounts[0])).toNumber());
      assert.equal(0, (await q.checkPlace(accounts[4])).toNumber());
      for (let i=1; i<4; i++)
        assert.equal(i, (await q.checkPlace(accounts[i])).toNumber());
    }).timeout(10000);
    
    

    // |_H_|___|_T_|___|___|  -->   |___|_H_|_T_|___|___|
    // | 1 | 2 | 3 |   |   |  -->   |   | 2 | 3 |   |   |
    it("dequeue once", async () => {
      await q.dequeue();
      assert.equal(accounts[2], await q.getFirst());
      assert.equal(accounts[3], await q.getLast());
      assert.equal(2, await q.qsize());
      assert.isFalse(await q.empty());
      assert.equal(0, (await q.checkPlace(accounts[4])).toNumber());
      for (let i=0; i<2; i++)
        assert.equal(0, (await q.checkPlace(accounts[i])).toNumber());
      for (let i=2; i<4; i++)
        assert.equal(i-1, (await q.checkPlace(accounts[i])).toNumber());
    });
    

    // |___|_H_|_T_|___|___|  -->   |___|___|_H_T_|___|___|
    // |   | 2 | 3 |   |   |  -->   |   |   |  3  |   |   |
    it("dequeue once again", async () => {
      await q.dequeue();
      assert.notMatch(await q.getFirst(), /^0x[0]+/);
      assert.equal(await q.getFirst(), await q.getLast());
      assert.equal(1, await q.qsize());
      assert.isFalse(await q.empty());
      assert.equal(1, (await q.checkPlace(accounts[3])).toNumber());
      assert.equal(0, (await q.checkPlace(accounts[4])).toNumber());
      for (let i=0; i<3; i++) {
        assert.equal(0, (await q.checkPlace(accounts[i])).toNumber());
      }
    });
    // |___|___|_H_T_|___|___|  -->   |___|___|_H_T_|___|___|
    // |   |   |  3  |   |   |  -->   |   |   | 0x0 |   |   |
    it("dequeue once again", async () => {
      await q.dequeue();
      assert.match(await q.getFirst(), /^0x[0]+/);
      assert.equal(await q.getFirst(), await q.getLast());
      assert.equal(0, await q.qsize());
      assert.isTrue(await q.empty());
      for (let i=0; i<accounts.length; i++)
        assert.equal(0, (await q.checkPlace(accounts[i])).toNumber());
    });

    // |___|___|_H_T_|___|___|  -->   |_T_|___|_H_|___|___|
    // |   |   | 0x0 |   |   |  -->   | 4 |   | 1 | 2 | 3 |
    it("enqueue accounts[1] through accounts[4]", async () => {
      for (let i=1; i<queueSize; i++)
        await q.enqueue(accounts[i]);
      assert.equal(accounts[1], await q.getFirst());
      assert.equal(accounts[4], await q.getLast());
      assert.equal(4, await q.qsize());
      assert.isFalse(await q.empty());
      assert.equal(0, (await q.checkPlace(accounts[0])).toNumber());
      assert.equal(0, (await q.checkPlace(accounts[5])).toNumber());
      for (let i=1; i<5; i++)
        assert.equal(i, (await q.checkPlace(accounts[i])).toNumber());
    }).timeout(10000);
    
    // |_T_|___|_H_|___|___|  -->   |___|_T_|_H_|___|___|
    // | 4 |   | 1 | 2 | 3 |  -->   | 4 | 5 | 1 | 2 | 3 |
    it("enqueue accounts[5]", async () => {
      await q.enqueue(accounts[5]);
      assert.equal(accounts[1], await q.getFirst());
      assert.equal(accounts[5], await q.getLast());
      assert.equal(5, await q.qsize());
      assert.isFalse(await q.empty());
      assert.equal(0, (await q.checkPlace(accounts[0])).toNumber());
      assert.equal(0, (await q.checkPlace(accounts[6])).toNumber());
      for (let i=1; i<6; i++)
        assert.equal(i, (await q.checkPlace(accounts[i])).toNumber());
    });
    
    // |___|_T_|_H_|___|___|  -->   |___|_T_|___|_H_|___|
    // | 4 | 5 | 1 | 2 | 3 |  -->   | 4 | 5 |   | 2 | 3 |
    it("dequeue once", async () => {
      await q.dequeue();
      assert.equal(accounts[2], await q.getFirst());
      assert.equal(accounts[5], await q.getLast());
      assert.equal(4, await q.qsize());
      assert.isFalse(await q.empty());
      assert.equal(0, (await q.checkPlace(accounts[0])).toNumber());
      assert.equal(0, (await q.checkPlace(accounts[1])).toNumber());
      assert.equal(0, (await q.checkPlace(accounts[6])).toNumber());
      for (let i=2; i<6; i++)
        assert.equal(i-1, (await q.checkPlace(accounts[i])).toNumber());
    });

    // |___|_T_|___|_H_|___|  -->   |___|_H_T_|___|___|___|
    // | 4 | 5 |   | 2 | 3 |  -->   |   |  5  |   |   |   |
    it("dequeue accounts 2, 3 and 4.", async () => {
      for (let i=0; i<3; i++)
        await q.dequeue();
      assert.equal(accounts[5], await q.getFirst());
      assert.equal(accounts[5], await q.getLast());
      assert.equal(1, await q.qsize());
      assert.isFalse(await q.empty());
      assert.equal(1, (await q.checkPlace(accounts[5])).toNumber());
      assert.equal(0, (await q.checkPlace(accounts[6])).toNumber());
      for (let i=0; i<5; i++)
        assert.equal(0, (await q.checkPlace(accounts[i])).toNumber());
    });

    // |___|_H_T_|___|___|___|  -->   |___|_H_T_|___|___|___|
    // |   |  5  |   |   |   |  -->   |   | 0x0 |   |   |   |
    it("dequeue once more so that queue is empty", async () => {
      await q.dequeue();
      assert.match(await q.getFirst(), /^0x[0]+/);
      assert.equal(await q.getFirst(), await q.getLast());
      assert.equal(0, await q.qsize());
      assert.isTrue(await q.empty());
      for (let i=0; i<accounts.length; i++)
        assert.equal(0, (await q.checkPlace(accounts[i])).toNumber());
    });
  }).timeout(50000);
  

  
  describe("Timeout checks.", async () => {
    /**
     * When there is only 1 buyer in line, he can not buy. 
     * So it is only fair that his countdown only start when 
     * there are 2 buyers in line. That is the logic of the Queue 
     * contract, so in our tests we include these kinds of checks.
    */

    it("checkTime() should revert with less than 2 buyers in queue.", async () => {
      try {
        await q.checkTime();
        assert.fail('checkTime() should fail will less than 2 buyers.');
      }
      catch(error) {
        assert.include(error.message, 'revert');
        assert.include(error.message, 'LESS THAN 2 ELEMENTS IN QUEUE');
      }
      await q.enqueue(accounts[1]);
      try {
        await q.checkTime();
        assert.fail('checkTime() should fail will less than 2 buyers.');
      }
      catch(error) {
        assert.include(error.message, 'revert');
        assert.include(error.message, 'LESS THAN 2 ELEMENTS IN QUEUE');
      }
      await q.dequeue();
    }).timeout(10000);
    

    /*
    // This test is not so helpful, but was my first approach to testing
    // the checkTime() function along with the variable latestChange.
    it("should enqueue 2 buyers and start the countdown for the\n"+
      "1st buyer right when the 2nd buyer joins the queue", async () => {
      
      // get the latest block before doing any operations.
      let latestBlockBefore = await web3.eth.getBlock('latest');

      // get the latest block timestamp
      let latestBlockBeforeTimestamp = latestBlockBefore.timestamp;

      // enqueue 1 buyer & assign the transaction block to a variable.
      // 'latestChange' should only change after 2 or more buyers are in the queue.
      // |_H_T_|___|___|___|___|  -->   |_H_T_|___|___|___|___|
      // | 0x0 |   |   |   |   |  -->   |  1  |   |   |   |   |
      let queued1 = await q.enqueue(accounts[1]);
      let queued1block = await web3.eth.getBlock(queued1.receipt.blockNumber);
      
      // The real value of 'latestChange' should either be the timestamp of the 
      // 'latestBlockBefore' block, or some block even before that.
      // Here, test that 'latestChange' is less than the 'queued1' block timestamp.
      assert.isBelow((await q.latestChange()).toNumber(), queued1block.timestamp);

      // enqueue a 2nd buyer, then test that 'latestChange' has the same timestamp
      // as the block of the enqueue transaction.
      // |_H_T_|___|___|___|___|  -->   |_H_|_T_|___|___|___|
      // |  1  |   |   |   |   |  -->   | 1 | 2 |   |   |   |
      let queued2 = await q.enqueue(accounts[2]);
      let queued2block = await web3.eth.getBlock(queued2.receipt.blockNumber);
      assert.equal(queued2block.timestamp, (await q.latestChange()).toNumber());

      await q.dequeue();
      await q.dequeue();
    }).timeout(10000);
    */

    // A more suited test for the checkTime() function. 
    it("checkTime() should work correctly with more than 1 buyers in queue.", async () => {  
      console.log("\tThis test will take a while depending on the TIMELIMIT of each buyer of the Queue.");

      // |_H_T_|___|___|___|___|  -->   |_H_|_T_|___|___|___|
      // | 0x0 |   |   |   |   |  -->   | 1 | 2 |   |   |   |
      let queued1 = await q.enqueue(accounts[1]);
      let queued2 = await q.enqueue(accounts[2]);
      
      // get the block of the 2nd enqueue transaction
      let queued2block = await web3.eth.getBlock(queued2.receipt.blockNumber);

      assert.equal(2, (await q.qsize()).toNumber());
      assert.equal(queued2block.timestamp, (await q.latestChange()).toNumber());

      // used to implement a sleep(time) by using Promises.
      // Will result in a delay of 'time' seconds when used in a Promise-like statement.      
      function delay(time) {
        return new Promise(success => setTimeout(success, time*1000));
      }

      // for debug
      //let queued1block = await web3.eth.getBlock(queued1.receipt.blockNumber);
      //console.log("queued1.timestamp: "+ queued1block.timestamp);
      //console.log("queued2.timestamp: "+ queued2block.timestamp);
      //console.log("latestChange: "+ (await q.latestChange()).toNumber()+"\n");

      // try to kick the 1st buyer 2 times while he is still in his time limit.
      // if he was kicked, checkTime() is not working correctly.
      // Trying to run this for each second was throwing 'out of gas' for even
      // a small time-limit of 10 seconds.
      // 'timelimit' is defined in the start of this 'contract' declaration (line ~44)
      for (let i=1; i<Math.floor(timelimit/3); i++) {
        //for debug
        //console.log("\twaiting for "+Math.floor(timelimit/3)+" seconds");
        await delay(Math.floor(timelimit/3));
        //for debug
        //console.log("\tcalling checkTime() @ " + Math.floor((new Date()).getTime()/1000));
        await q.checkTime();
        assert.equal(2, (await q.qsize()).toNumber());
      }

      // Now delay another 1+timelimit/3 seconds so that 1st buyer's time limit has passed.
      await delay(Math.floor(timelimit/3)+2);
      await q.checkTime();
      assert.equal(1, (await q.qsize()).toNumber());
      
      // if the checkTime() succeeded in kicking the 1st buyer
      // try to kick the last remaining buyer. This should fail,
      // even after 'timelimit' seconds.
      if ((await q.qsize()).toNumber()==1) {
        for (let i=0; i<2; i++) {
          try {
            await q.checkTime();
            assert.fail("checkTime() should have failed with only 1 buyer in queue.");
          }
          catch(error) {
            assert.include(error.message, 'revert');
            assert.include(error.message, "LESS THAN 2 ELEMENTS IN QUEUE");
          }
          await delay(Math.floor(timelimit)+1);
        }
      }

      // In the case that everything went well so far, we are left
      // with only 1 buyer in the queue, whose time limit has passed.
      // If we enqueue a 2nd buyer again, the 1st buyer's timelimit should reset.
      await q.enqueue(accounts[3]);
      assert.equal(2, (await q.qsize()).toNumber());
      await q.checkTime();
      assert.equal(2, (await q.qsize()).toNumber());
      
      // Then, after 'timelimit' seconds, the 1st buyer should be kicked 
      // if the checkTime() is called.
      await delay(timelimit+1);
      await q.checkTime();
      assert.equal(1, (await q.qsize()).toNumber());

      // To clear the queue, we might either need to call
      // dequeue() 1, 2, or 3 times depending on whether the 
      // checkTime() has succeeded or not 1, 2 or 3 times.
      try {
        await q.dequeue();
        await q.dequeue();
        await q.dequeue();
      }
      catch(error) {
        ;
      }
    }).timeout(timelimit*3e4);
  }).timeout(timelimit*3.2e4);
});
