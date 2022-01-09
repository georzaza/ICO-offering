// SPDX-License-Identifier: UNLICENSED
/**
 * 
 * Queue.sol contract specifications : 
 *
 * 	Must have a finite size, please keep this set to 5
 * 	    - I changed that to a value that will be supplied by the deployer.
 * 	      This means that we may whatever value we want as the queue size
 * 		  when we deploy this contract (through the Crowdsale contract)
 * 		  The maximum size of the queue is capped to 2^8-1.
 *		
 * 	Must have a time limit someone can keep their spot in the front
 *	    - Satisfied.
 * 
 * 
 * 	Must have the following methods:
 * 
 *	  qsize(): Returns the number of people waiting in line
 *		- Satisfied.
 *		
 * 	  empty(): Returns whether the queue is empty or not
 *		- Satisfied.
 * 
 * 	  getFirst(): Returns the address of the person in the front of the queue
 *		- Satisfied.
 * 
 * 	  checkPlace(address): Allows msg.sender to check their position in the queue
 *		- Satisfied, with a small modification. Instead of allowing msg.sender
 *		  to check their place in their queue, it allows anyone to check anyone's 
 *		  place in the queue, by supplying the argument address
 * 
 * 	  checkTime(): Allows anyone to expel the 1st person in line if their time is up
 * 		- Satisfied.
 * 
 * 	  dequeue(): Removes the first person in line.
 *		- Satisfied. Even if the queue is empty, the function will still execute.
 * 
 * 	  enqueue(address addr): Places addr in the first empty position in the queue
 *		- Satisfied.
 * 
 * 	  The queue should only permit buyers to place an order if they are not the
 *    only ones in line, i.e. if there is at least one person waiting behind them.
 *		- Satisfied.
 * 
 * 	Events:
 * 	  Fired when someone's time limit is over and they are 
 * 	  ejected from the front of the queue
 * 		- Satisfied.
 */

pragma solidity >= 0.8.10;


/// @title The best queue in the world.
/// @author George Zazanis

contract Queue {


	/*###############################################################
	#######       S T A T E    V A R I A B L E S             ########
	################################################################*/


	/**	@notice	Shows how many elements are in the queue.
	 * 	@dev	Points to the last non-qsize() position of the queue.
	 */
	uint8	private tail = 0;
	uint8	private head = 0;
	address[] private queue;

	/**
	 *	@notice shows how much time a buyes has to buy.
	 *	@dev 	It is only fair to initialize this value and start the 
	 *				countdown ONLY AFTER there are at least 2 buyers in the queue. 
	 *				See enqueue, dequeue, checkTime for more.
	 */
	uint256   public countdown = 0;

	/// @notice Saves the timestamp of particular changes to the queue.
	/// @dev 	Used in conjuction with the above countdown variable.
	uint256	  public latestChange = 0;

	/**
	 *	@notice The maximum amount of time in seconds that a buyer can remain in
	 * 					the queue ONLY IF he is not the only one in the queue.
	 *	@dev 		Is uint256 cause block.timestamp checks are involved.
	 * 					A uint32 would be sufficient for another ~15 years. (until 2037)
	 */
	uint256	  public TIMELIMIT = 7; // 7 seconds

	/**
	 *	@dev	We MUST set the owner. We utilize the owner so that ONLY
	 *				the contract that deployed this contract can call 
	 *				the dequeue and enqueue functions.
	 */
	address private immutable owner;


	/*###############################################################
	#######             E  V  E  N  T  S                     #######
	################################################################*/

	/// @notice Fires up whenever a buyer was kicked from the queue.
	///  		The buyers are not automatically kicked. Someone needs to kick them.
	event BuyerKickedFromQueue(address indexed _address);
	
	event NewBuyerArrived(address indexed _address);
	
	/// @notice Each buyer has a fixed amount of time to stay in the queue
	/// 		This event is fired whenever someone's clock starts ticking.
	event CountdownForPurchaseStarted(uint256 indexed _timeRemaining, uint256 indexed _countdownStartedAt);


	/*##############################################################
	#######         M  O  D  I  F  I  E  R  S                #######
	################################################################*/

	modifier ownerOnly
	{
		require (msg.sender == owner, 
			"ONLY OWNERS CAN DO THAT");
		_;
	}
	modifier notAlreadyInQueue(address addr)
	{
		require (checkPlace(addr) == 0,
			"ELEMENT ALREADY IN QUEUE");
		_;
	}
	modifier queueNotFull
	{
		require ((tail+1)%uint8(queue.length) != head,
			"QUEUE IS FULL");
		_;
	}
	modifier moreThan1BuyersInQueue()
	{
		require(qsize() > 1,
			"LESS THAN 2 ELEMENTS IN QUEUE");
		_;
	}


    /*##############################################################
    #######         C  O  N  S  T  R  U  C  T  O  R          #######
    ################################################################*/

	constructor(uint8 _capacity)
	{
		queue = new address[](_capacity);
		head = 0;
		tail = 0;
		owner = msg.sender;
	}


    /*##############################################################
    #######         F  U  N  C  T  I  O  N  S                #######
    ################################################################*/

	/**
	 * 	Returns the current number of the elements of the queue
	 */
	function qsize()
	view
	public
	returns (uint8 _occupied)
	{
		if (head == tail && queue[head] == address(0))
			return 0;
		return uint8((queue.length-head+tail) % queue.length) +1;
	}

	/**
	 * 	
	 * 	@notice Returns whether the queue is empty.
	 * 	@return isEmpty True if the queue is empty, False otherwise.
	 */
	function empty()
	view
	public
	returns (bool isEmpty)
	{
		return head == tail && queue[head] == address(0);
	}



	/**
	 * 	@notice Get the first element of the queue.
	 * 	@notice Will return the address 0x0 if the queue is empty.
	 * 	@return first The first element of the queue.
	 */
	function getFirst()
	view
	public
	returns (address first)
	{
		return queue[head];
	}

	/**
	 * 	@notice Check if msg.sender exists in queue.
	 *  @return position The position of msg.sender in the queue, otherwise 0.
	 */
	function checkPlace(address _address)
	view
	public
	returns (uint8 position)
	{

		for (uint8 i=head; (i!=tail); i=uint8((i+1)%queue.length))	{
			if (_address == queue[i])
				return uint8((queue.length-head+i) % queue.length)+1;
		}
		if (_address == queue[tail])
			return qsize();
		return 0;
		
	}	

	/**
	 * @notice Kick/dequeue the first element of the queue.
	 * @dev 	If their time is up we need to kick the first element 
	 * 			of the queue. Can we call dequeue? No, cause dequeue is 
	 * 			reserved for the owner only while this function may be
	 * 			called by anyone. So we just re-implement the dequeue function here.
	 * 			Also, maybe this function should be optimize as it allows
	 * 			ANYONE to call this function. Perhaps, only buyers already
	 * 			in the queue should be able to call this function. Finally, 
	 * 			since when there is only 1 buyer in the queue, he can not buy,
	 * 			it is only fair to have a time-limit countdown only after there 
	 * 			are at least 2 buyers in the queue.
	 */
	function checkTime()
	moreThan1BuyersInQueue
	public
	{
		if (block.timestamp < countdown + latestChange)
			return;
		
		// dequeue.
		if (head == tail)
			queue[head] = address(0);
		else 
			head = (head+1) % uint8(queue.length);
		emit BuyerKickedFromQueue(queue[head]);
		// Start the timer for the next buyer only if there are more than 1 
		// buyers in the queue left.
		if (qsize() > 1)
		{
			countdown = TIMELIMIT;
			latestChange = block.timestamp;
			emit CountdownForPurchaseStarted(countdown, latestChange);
		}
	}

	/**
	 * 	@notice 'Remove' the first element of the queue.
	 */
	function dequeue()
	ownerOnly
	public
	{
		emit BuyerKickedFromQueue(queue[head]);
		if (head == tail)
			queue[head] = address(0);
		else 
			head = (head+1) % uint8(queue.length);
		// Start the timer for the next buyer only if there are more than 1 
		// buyers in the queue left.
		if (qsize() > 1)
		{
			countdown = TIMELIMIT;
			latestChange = block.timestamp;
			emit CountdownForPurchaseStarted(countdown, latestChange);
		}
	}

	/**
	 * 	@notice Place a new element in the queue.
	 *  				Also sets the `countdown` and `latestChange` variables accordingly.
	 * 					Since when there is only 1 buyer in the queue, he can not buy,
	 * 					it is only fair to have a time-limit countdown only if there 
	 * 					are at least 2 buyers in the queue.
	 *	@param _address The address to be placed in the queue.
	 */
	function enqueue(address _address)
	ownerOnly
	queueNotFull
	notAlreadyInQueue(_address)
	public
	{
		// if the queue was initially empty, the head and tail will
		// point to the 1st place.
		if (!empty())
			tail = (tail+1) % uint8(queue.length);
		queue[tail] = _address;
		emit NewBuyerArrived(_address);
		
		// When the 2nd element is added, start the timer.
		if (qsize() == 2)
		{
			countdown = TIMELIMIT;
			latestChange = block.timestamp;
			emit CountdownForPurchaseStarted(countdown, latestChange);
		}
	}

	/**
	 * 	@notice Get the last element of the queue.
	 * 	@notice Will return the address 0x0 if the queue is empty.
	 * 	@return last The last element of the queue.
	 *  This function was added to help with the testing, it is not 
	 *  needed to the Crowdsale.
	 */
	function getLast()
	view
	public
	returns (address last)
	{
		return queue[tail];
	}

}