// SPDX-License-Identifier: UNLICENSED
/**
 *  Crowdsale.sol contract specifications:
 *
 *  Must deploy Token.sol
 *    - Satisfied.
 * 
 *  Must keep track of how many tokens have been sold.
 *    - Satisfied.
 *      Variable tokensSold.
 *  
 *  Must only sell to/refund buyers between start-time and end-time.
 *    - Satisfied.
 *      Modifier saleActive.
 * 
 *  Must forward all funds to the owner after sale is over.
 *    - Satisfied.
 *      Function collect().
 * 
 *  Owner:
 *    Must be set on deployment
 *      - Satisfied.
 *        Variable owner.
 *
 *    Must be able to time-cap the sale
 *    Must keep track of start-time
 *    Must keep track of end-time/time remaining
 *      - Satisfied. (not fully)
 *        See modifier `saleActive`. Also function `extendTimeout`
 *        was added that resets a sale or extends the sale period.
 *        we do not time-cap the sale.
 *
 *    Must be able to specify an initial amount of tokens to create
 *      - TODO For now these are set on deployment.
 *
 *    Must be able to specify the amount of tokens 1 wei is worth
 *      - TODO For now these are set on deployment.
 *
 *    Must be able to mint new tokens
 *    This amount would be added to totalSupply in Token.sol
 *      - Satisfied. 
 * 
 *    Must be able to burn tokens not sold yet
 *    This amount would be subtracted from totalSupply in Token.sol
 *      - Satisfied.
 *
 *    Must be able to receive funds from contract after the sale is over
 *      - Satisfied.
 *
 *  Buyers:
 *    Must be able to buy tokens directly from the contract and as long as the
 *    sale has not ended, if they are first in the queue and there is someone 
 *    waiting line behind them. This would change their balance in Token.sol.
 *    This would change the number of tokens sold.
 *      - Satisfied.
 *
 *    Must be able to refund their tokens as long as the sale has not ended.
 *    Their place in the queue does not matter. This would change their balance
 *    in Token.sol. This would change the number of tokens sold. 
 *      - Satisfied.
 *
 *  Events:
 *    Fired on token purchase
 *      - Satisfied.
 *
 *    Fired on token refund
 *      - Satisfied.
 */


pragma solidity >= 0.8.10;

import './Queue.sol';
import './Token.sol';

/// @title A simple Crowdsale contract
/// @author George Zazanis
contract Crowdsale {

    /*###############################################################
    #######       S T A T E    V A R I A B L E S             ########
    ################################################################*/

    address private immutable owner;
    uint256 public immutable ratio;
    uint256 public tokensSold;
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    Token public token;
    Queue public queue;


    /*##############################################################
    #######             E  V  E  N  T  S                     #######
    ################################################################*/

    event Purchase(address indexed _buyer, uint256 indexed _tokens);
    event Refund(address indexed _buyer, uint256 indexed _value);
    event NoPurchase(address indexed _address, uint256 indexed _weiSent, uint256 indexed _tokens);


    /*##############################################################
    #######         M  O  D  I  F  I  E  R  S                #######
    ################################################################*/

    modifier ownerOnly 
    {
        require (msg.sender == owner, 
            "WHAT ARE YOU TRYING TO DO THERE?");
        _;
    }

    modifier saleOver 
    {
        require (block.timestamp>=saleEndTime, 
            "THE SALE IS STILL ACTIVE.");
        _;
    }

    modifier saleActive
    {
        require (block.timestamp>=saleStartTime && block.timestamp<saleEndTime,
            "THE SALE IS OVER.");
        _;
    }

    modifier enoughFunds(uint256 _tokens)
    {
        require (msg.value >= _tokens*ratio, 
            "NOT ENOUGH ETHER");
        _;
    }

    modifier ratioGreaterThanZero(uint256 _ratio) 
    {
        require (_ratio>0, 
            "RATIO IS LOWER OR EQUAL TO ZERO");
        _;
    }

    modifier ratioLowerThan1Gwei(uint256 _ratio) 
    {
        require (_ratio <= 10**9, 
            "RATIO IS NOT LOWER OR EQUAL TO 1 GWEI");
        _;
    }

    modifier saleEndTimeInFuture(uint256 _saleEndTime) 
    {
        require (block.timestamp < _saleEndTime, 
            "WRONG SALE_END_TIME");
        _;
    }

    modifier senderHasEnoughTokens(uint256 _tokens)
    {
        require(token.balanceOf(msg.sender) >= _tokens, 
            "MSG.SENDER DOES NOT OWN THAT MANY TOKENS");
        _;
    }

    modifier senderHasApproved(uint256 _tokens)
    {
        require(token.allowance(msg.sender, address(this)) >= _tokens,
            "YOU NEED TO APPROVE FIRST. CHECK THE MANUAL?");
        _;
    }

    modifier firstInLine
    {
        require(queue.getFirst() == msg.sender,
            "BUYER NEEDS TO WAIT FOR HIS TURN");
        _;
    }

    modifier notFirstInLine
    {
        require(queue.getFirst() != msg.sender,
            "BUYER IS THE FIRST IN LINE.");
        _;
    }

    modifier notTheOnlyBuyer()
    {
        require(queue.qsize() > 1,
            "WAITING FOR MORE BUYERS");
        _;
    }

    modifier buyerInQueue()
    {
        require(queue.checkPlace(msg.sender) != 0,
            "BUYER NOT IN QUEUE, CANT BUY");
        _;
    }



    /*##############################################################
    #######         C  O  N  S  T  R  U  C  T  O  R          #######
    ################################################################*/


    constructor 
    (
        uint256 _saleEndTime,
        uint256 _initialSupply,
        uint256 _ratio,
        uint8  _queueSize
    )
    ratioGreaterThanZero(_ratio)
    ratioLowerThan1Gwei(_ratio)
    saleEndTimeInFuture(_saleEndTime)
    {
        owner = msg.sender;
        saleStartTime = block.timestamp;
        saleEndTime = _saleEndTime;
        ratio = _ratio;

        // We MUST pass the owner to the Token. 
        // doing that, we 'break' direct access to all functions
        // of the Token that are marked with the modifier `ownerOnly`.
        // Thus, these functions should be implemented in this contract
        // since they only can be called from this contract.
        token = new Token(_initialSupply);

        // We MUST pass the owner to the queue.
        // If we don't, anyone can call the queue.dequeue() function.
        // So we disallow access to this function and only allow it to be 
        // called from this contract.
        queue = new Queue(_queueSize);
    }


    /*##############################################################
    #######         F  U  N  C  T  I  O  N  S                #######
    ################################################################*/
    

    function mint(uint256 _tokens)
    ownerOnly
    public
    {
        token.mint(_tokens);
    }

    /**
     *  @notice Function to burn tokens not sold yet.
     *  @dev    Since only this contract can track the number of tokens sold,
     *          we have implemented the burn() function in the Token contract 
     *          such that it can only be called through this contract. These 
     *          requirements also state that the _tokens to be burned should 
     *          not have been sold yet and that only the deployer of this 
     *          contract can call this function.
     *  PS In the Token.sol contract there is another function for users that may 
     *  want to burn their acquired tokens.
     */
    function burn(uint256 _tokens)
    ownerOnly
    public
    {
        require(_tokens <= token.getTotalSupply() - tokensSold);
        token.burn(_tokens);
    }

    /**
     *  @notice Purchase _tokens tokens
     *  @return tokens The number of _tokens that were bought if successful or 0.
     */
    function buyTokens(uint256 _tokens)
    saleActive
    notTheOnlyBuyer
    buyerInQueue
    firstInLine
    enoughFunds(_tokens)
    public
    payable
    returns (uint256 tokens)
    {
        require(_tokens>0, "YOU CANT BUY 0 TOKENS");
        
        if (msg.sender == queue.getFirst()) {

            // transfer _tokens from this contract to msg.sender.
            // if successful, then kick the buyer from the queue, emit the 
            // event Purchase and return how many tokens were bought.
            if (token.transfer(msg.sender, _tokens)==true) {
                tokensSold += _tokens;
                queue.dequeue();
                emit Purchase(msg.sender, _tokens);
                return _tokens;
            }
        }
        return 0;
    }

    /**
     *  @notice Refunds a buyer. The buyer MUST first approve this contract
     *          though the Token.approve() function.
     *  @dev    To get back our tokens the buyer must give us approval first.
     *          For more on how to do that, see the 'hand-testing' file or the
     *          Token contract's relative function. Then, we refund the Buyer.
     */
    function refundTokens(uint256 _tokens)
    saleActive
    notFirstInLine
    senderHasEnoughTokens(_tokens)
    senderHasApproved(_tokens)
    public
    {
        if (token.transferFrom(msg.sender, address(this), _tokens)==true)
        {
            payable(msg.sender).transfer(_tokens*ratio);
            tokensSold -= _tokens;
            emit Refund(msg.sender, _tokens*ratio);
        }
    }

    /// @notice Effectively reset and/or start a new sell
    function extendTimeout(uint _seconds)
    ownerOnly
    public
    {
        saleEndTime += _seconds;
    } 

    /**
     *  @notice Transfers all balance from this account to the owner account.
     *  @dev    Only the owner can call this, and the sale must be over before 
     *          calling this function.
     */
    function collect()
    public
    ownerOnly
    saleOver
    {
        // In the case that only 1 buyer is in the queue, and
        // the sale has ended, he is trapped there. This for loop
        // would also cover that case. 
        //for (uint8 i=0; i<queue.qsize(); i++)
        //    queue.dequeue();
        payable(owner).transfer(address(this).balance);
    }

    /** 
     *  @notice Puts msg.sender into the queue of buyers.
     *  
     *  There are 2 ways that we are able to enqueue a buyer in the queue.
     *  1. Provide this function in this contract.
     *  2. Do not provide such a function in this contract and instead
     *     let the buyers directly call the queue.enqueue function.
     *  Using way No 2, any buyer can call the queue.enqueue function and 
     *  can subscribe himself or any other buyer. Originally, I had build 
     *  the contracts to work with No 2 and did not provide this function.
     *  On second throught, this is the contract that should decide who goes 
     *  on the queue and who not, so it's better to change the implementation
     *  to No 1. To achieve that, these were the changes I had to do:
     *  a) provide this function
     *  b) make the queue.enqueue function RESTRICTED TO OWNER ONLY.
     *  The 2nd step ensures that only this contract will be able to enqueue
     *  a new buyer.
     * 
     *  Also, the Queue contract can get the msg.sender through the global tx.origin
     *  variable and that is why there are no arguments in the below function.
     * 
     *  Last but not least, another restriction we could have is that the owner 
     *  only can call the below function, effectively making him the decision 
     *  maker on who gets to join the queue and who not.
     * 
     */
    function getInLine()
    saleActive
    public
    {
        queue.enqueue(msg.sender);
    }


    //######################################################################
    //     F U N C T I O N S   F O R   E A S I E R    D E B U G G I N G    #
    //######################################################################

    // These functions were used while in development.
    // They are not maintened, neither guaranteed to work.

    /** 
     *  @notice Gives the owner the right to dequeue an account from the queue
     *  @dev    This function should not be used in a real Crowdsale contract.
     *          It's only implemented to showcase something that is referenced
     *          in the `hand-testing` file.
     */
     /*function kickFirst()
     public
     ownerOnly
     {
        queue.dequeue();
     }*/

    /* For debugging.
    function getNextBuyer() saleActive view public returns (address addr) {
        address first = queue.getFirst();
        return first;
    }*/

    /*  For debugging. TODO comment
    function getNumberOfBuyersInQueue() saleActive view public returns (uint256 filledPositions) {
        uint256 filled = queue.qsize();
        return filled;
    }*/

    /*  For debugging.
    function getMaxQueueSize() view public returns (uint256 queueSize)
    {
        uint256 size = queue.size();
        return size;
    }*/

    /*  For debugging TODO comment 
    function getTokensBought(address _address) ownerOnly view public returns (uint256 tokensBought)
    {
        uint256 tokens = token.balanceOf(_address);
        return tokens;
    }*/

    /*  For debugging.
    function getOwner() view public returns (address addr) {
        return owner;
    }*/

    /* for debugging
    function kickAllBuyers() public ownerOnly {
        queue.dequeueAll();
    }*/
}