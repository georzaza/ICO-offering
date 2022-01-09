# SET THE SYNTAX HIGHLIGHT OF THIS DOCUMENT TO EG. RUBY or PYTHON
# for a better view, and depending on how you're viewing this file.
# How to do that?
# Usually the shortcut to an editor's command pallete is Ctrl+Shift+P
# If you're working with 'code', type in "Change Language" and select 
# the appropriate option. If you're working with 'sublime' type 'Set syntax'.
# If neither, go do a google search.

# Includes a guided testing by interacting with the truffle console.
# Just copy and paste these commands on truffle one by one to do the testing.
# If you are going to use this file to test the implementation then you might
# want to keep it opened next to a truffle console. That way, 3-clicking on
# a line of this doc to select it and then moving the mouse OVER your 
# terminal and hitting the middle mouse key, will paste the line in truffle.
 
# Tests are yet to come, cause this is high time-consuming. This file 
# contains only basic testing. Eg. the Token transferFrom() and approve() 
# function are not being tested thoroughly.
# I will not showcase testing of the following Crowdsale characteristics:
#   1. the 'saleActive' cases.
#   2. the collect() and extendTimeout() functions.
# I have tested them and they were working fine.
# Let's start.


# get an instance of all the contracts.
# The 2 last lines get an instance of the contracts queue and token that
# were deployed by the Crowdsale contract.
# Prior to discovering how to do that, my code was VERY different, with LOTS
# of security holes.
c = await Crowdsale.deployed();
queue = await Queue.at(await c.queue());
token = await Token.at(await c.token());

# get the accounts.
acc = await web3.eth.getAccounts();

# lets add a buyer in the qeuue
buyer1joins1 = await c.getInLine({from: acc[1]});

# To see the relevant event we can do:
# After that, we will not get into the events too much.
events = await queue.getPastEvents();
events[0];
events[0].args.

# see how many buyers are in the queue
queue.qsize().then((s,e)=>console.log(s.toNumber()))


# Try to buy
nope = await c.buyTokens(100, {from: acc[1], value: 1000})

# before adding another account lets see if we can kick 
# the 1st account using the queue instance. 
# First let's see for how much time the first in the line is allowed to stay.
queue.countdown().then((s,e)=>console.log(s.toNumber()))

# 0!! Meaning, he can stay forever, unless a new buyer joins too.
# Let's try to kick him out from any account that is not an owner, again
# through the queue Contract.
queue.dequeue({from: acc[2]})

# Nope!
# Let's now try from the account of the owner.
queue.dequeue()

# Nope!
# What if we try this:
queue.dequeue({from: c.address});

# It's not working of course. A contract can not be the initiator (tx origin) 
# of a transaction.
# So the only way for him to leave his position is either to make a purchase
# or his time to run out AND someone else to call the queue.checkTime() 
# function.


# Let's add another buyer in the queue, acc[2]
buyer2joins = await c.getInLine({from: acc[2]});

events = await queue.getPastEvents();
events[0].event;
events[0].args._timeRemaining.toNumber();
events[0].args._countdownStartedAt.toNumber();
events[1].event;
events[1].args._address


# See if he was added to the queue
queue.qsize().then((s,e)=>console.log(s.toNumber()))

# We can test now if we can kick the buyer.
# If it took you more than 60 to get here, then this will kick the 
# buyer. Kicking him will make the rest of the commands on this doc
# to not work, so if you need to test this, you have to start over.
# a = await queue.checkTime();
# queue.qsize().then( (s,e) => console.log(s.toNumber()));

# At this point there are 2 buyers in the queue, with the acc[1] to be the first one.
# Let's try to buy from an account that is not in the queue
c.buyTokens(100, {from: acc[9], value: 1000});

# try to buy from an account that is in the queue, but is not the next Buyer
c.buyTokens(100, {from: acc[2], value:1000});

# 1 token = 10 wei, set in the deployment file.
# try to buy from the 1st buyer, but by providing lower ether than he should
c.buyTokens(100, {from: acc[1], value:999});

# last step before making the 1st purchase.
# save the available balance of the Crowdsale contract & the acc[1] prior to
# the purchase. todo see if these are needed.
contractBalanceBeforeFirstBuy = await web3.eth.getBalance(c.address);
account1BalanceBeforeFirstBuy = await web3.eth.getBalance(acc[1]);

# buy 100 tokens from account 1
x = await c.buyTokens(100, {from: acc[1], value: 1000});

# see the event
x

# see, through the event, who bought and how many
x.logs[0].args[0]
x.logs[0].args[1].toNumber();

# save the new balances and print a summary
# Remember: 1 token = 10 wei
contractBalanceAfterFirstBuy = await web3.eth.getBalance(c.address);
account1BalanceAfterFirstBuy = await web3.eth.getBalance(acc[1]);
# copy this long line and paste to see the balances after the purchase.
console.log("\n\ncontractBalanceBeforeFirstBuy: " + contractBalanceBeforeFirstBuy + "\ncontractBalanceAfterFirstBuy : " + contractBalanceAfterFirstBuy + "\n\naccount1BalanceBeforeFirstBuy: " + account1BalanceBeforeFirstBuy + "\naccount1BalanceAfterFirstBuy : " + account1BalanceAfterFirstBuy);

# see how many he bought through the crowdsale contract
# todo change that
buyer1tokens = await token.balanceOf(acc[1]);
buyer1tokens.toNumber();

# check total tokensSold in Crowdsale
c.tokensSold().then((s,e) => console.log(s.toNumber()))

# confirm that acc[1] is not in the queue anymore.
queue.qsize().then( (s,e) => console.log(s.toNumber()));
acc[1]
queue.getFirst();

# try to buy with acc[2]
c.buyTokens(100, {from: acc[2], value: 1000})

# add acc[1] again in the queue. This should not work, but the exercise
# mentions that implementing a whitelist/blacklist is optional, so it works 
# in our case.
buyer1joins2 = await c.getInLine({from: acc[1]});

# again, see if he was added
queue.qsize().then( (s,e) => console.log(s.toNumber()));

# The queue now has acc[2] first in line, and acc[1] behind him 
queue.getFirst();
acc[2]


# REFUND.
# lets try to refund acc[2] while he is the first in line.
refund = await c.refundTokens(50, {from: acc[2]});

# lets try to refund acc[1] who is second in line
refund = await c.refundTokens(50, {from: acc[1]});


# The problem is that based on the ERC20 Interface, we cannot transfer 
# the tokens from the buyer account back to the Crowdsale account.
# The ERC20 Interface defines 2 ways that we are able to transfer tokens.
# Either by calling the function transfer(_to, _tokens), or by calling
# the function transferFrom(_owner, _spender, _tokens). But to use the 2nd one
# we first need to use another function of the contract, 
# the function approve(_spender, _tokens)
#
# So the solution to our problem is that the buyer needs to first make a 
# transaction with our deployed Token, and approve us to take his tokens back. 
# Then, he can call the refund function.
# 
# I was stuck in this for 2 days 'cause I didn't know how to interact with the
# Crowdsale's token instance functions. It appears we can get an instance of this 
# token with:
# token = await Token.at(await c.token()), ( update: we have already done that )
#


# Let's give our approval, from acc[1] to the Crowdsale contract
approval = token.approve(c.address, 50, {from: acc[1]})

# see through the Token instance if this actually succeeded.
token.allowance(acc[1], c.address).then((s,e) => console.log(s.toNumber()));

# or through the event
refundEvent = await token.getPastEvents();
refundEvent[0].args._owner;
refundEvent[0].args._spender;
refundEvent[0].args._value.toNumber();


# we specified 50 tokens. Now the crowdsale contract can spend 50 tokens 
# from the acc[1] using the function transferFrom of the Token instance.
# Let's try to refund him more than 50
refund = await c.refundTokens(51, {from: acc[1]});

# Now lets make a refund of 40/50 tokens. 
# Just copy paste those commands, at the end we print them all.
accountBalanceBeforeRefund = await web3.eth.getBalance(acc[1])
accountTokensBeforeRefund = await token.balanceOf(acc[1]);
contractBalanceBeforeRefund = await web3.eth.getBalance(c.address);
contractTokensBeforeRefund = await token.balanceOf(c.address);
tokensSoldBeforeRefund = await c.tokensSold();
refund = await c.refundTokens(40, {from: acc[1]});
refund;
accountBalanceAfterRefund = await web3.eth.getBalance(acc[1])
accountTokensAfterRefund = await token.balanceOf(acc[1]);
contractBalanceAfterRefund = await web3.eth.getBalance(c.address);
contractTokensAfterRefund = await token.balanceOf(c.address);
tokensSoldAfterRefund = await c.tokensSold();
console.log("\n\naccountBalanceBeforeRefund  : "+accountBalanceBeforeRefund+"\n"+ "accountBalanceAfterRefund   : "+accountBalanceAfterRefund+"\n\n"+ "contractBalanceBeforeRefund : "+contractBalanceBeforeRefund+"\n"+ "contractBalanceAfterRefund  : "+contractBalanceAfterRefund+"\n\n"+ "accountTokensBeforeRefund   : "+accountTokensBeforeRefund+"\n"+ "accountTokensAfterRefund    : "+accountTokensAfterRefund+"\n\n"+ "contractTokensBeforeRefund  : "+contractTokensBeforeRefund+"\n"+ "contractTokensAfterRefund   : "+contractTokensAfterRefund+"\n\n"+"tokensSoldBeforeRefund      : "+tokensSoldBeforeRefund+"\n"+ "tokensSoldAfterRefund       : "+tokensSoldAfterRefund+"\n\n");

# lets also check if the allowance of was decreased to 10.
token.allowance(acc[1], c.address).then((s,e) => console.log(s.toNumber()));

# This means that the Crowdsale contract can still manipulate 10 tokens 
# that belong to acc[1] !
# A decreaseAllowance() function should therefore be implemented in the Token 
# contract that will allow acc[1] to remove the ownership rights that he has
# previously given to another account. todo do it.

#todo add more testing for transfer, approval, refund
#todo add tests for Token functions without the crowdsale

# 3. BURNING

# Note that the number of burnt tokens from an account is not tracked in 
# the Crowdsale contract. To see how many tokens were burned in total one
# needs to use the token.totalSupply(), Crowdsale.initialSupply() and
# the Crowdsale.tokensSold() functions to figure it out.


# Examining Access to token.burn & burning tokens not sold yet.

# Let's try to burn some - not owned - tokens directly, from any account
# it will fail.
token.burn(100, {from: acc[2]});

# Let's try to do that from the Crowdsale contract.
# it will fail. A smart contract can not initialize a transaction (be tx origin)
token.burn(100, {from: c.address});

# The owner of the Token contract is the Crowdsale contract. So we can 
# only call the function `burn` of the Token contract THROUGH the Crowdsale
# contract AND ONLY IF we are the creators of the Crowdsale contract AND ONLY IF
# the amount of tokens to be burned does not exceed the amount of tokens that 
# have been sold. (tokensToBurn <= totalSupply - tokensSold)

# Try from a -not-owner of Crowdsale contract- account to burn tokens.
# it will fail.
c.burn(100, {from: acc[1]});

# Try from the owner of the Crowdsale to burn more tokens than those remaining.
# it will fail.
token.getTotalSupply().then( (s,e) => console.log(s.toNumber()));
c.burn(123456790);

# try to burn a can-be-burnt amount of tokens from the owner account.
# it will succeed.
token.getTotalSupply().then( (s,e) => console.log(s.toNumber()));
burntTransaction = await c.burn(100);
token.getTotalSupply().then( (s,e) => console.log(s.toNumber()));

# We can also see the event Burnt like this.
# The second and third values are the msg.sender and the amount of tokens that
# were burnt accordingly. 
burntTransaction.receipt.rawLogs[0].topics;
console.log(6*16+4);


# Users burning their tokens.
# Users can only do that through the function token.burnTokens()
# Lets try to burn tokens that a user does not own.
token.burnTokens(100, {from: acc[2]});

# Lets now burn 10 tokens from acc[1]

# acc[1] balance
token.balanceOf(acc[1]).then(s => console.log(s.toNumber()));

# total supply
token.getTotalSupply().then( (s,e) => console.log(s.toNumber()));

# burn 23 tokens
accountBurntTokens = await token.burnTokens(23, {from: acc[1]});

# new acc[1] balance
token.balanceOf(acc[1]).then(s => console.log(s.toNumber()));

# new total supply
token.getTotalSupply().then( (s,e) => console.log(s.toNumber()));


# MINTING
# As with the burn() function of the Token instance, the mint()
# function can only be called through the Crowdsale contract AND
# the caller should be the owner of the Crowdsale contract.
# As with the deployment, all new tokens go the Crowdsale contract.
token.getTotalSupply().then( (s,e) => console.log(s.toNumber()));
minting = await c.mint(3333);
token.getTotalSupply().then( (s,e) => console.log(s.toNumber()));
token.balanceOf(acc[1]).then(s => console.log(s.toNumber()));
token.balanceOf(c.address).then(s => console.log(s.toNumber()));


# If you have followed the flow of this document, by the time 
# that we executed all those, the countdown time of the 1st account
# of the queue shall have ended. Let's try to kick acc[2] from the 
# first position of the queue to test if that is working.
kick = await queue.checkTime({from: acc[8]});
kick;

# Note that we used acc[8] as the msg.sender, while acc[8] was never
# in the queue. This would mean that anyone can spam the queue, but 
# at this point and for this exercise's goals, it's not clear whether
# this behaviour is harmful or not.
