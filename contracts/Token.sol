// SPDX-License-Identifier: UNLICENSED

/**
 *  Token.sol contract specifications:
 *    Must implement ERC20Interface.sol fully
 *      - Satisfied.
 * 
 *    Must work in conjunction with Crowdsale.sol. `totalSupply` would be 
 *    set on deployment of Crowdsale.sol
 *      - Satisfied.
 * 
 *  Users:
 *    All standard functionality from ERC20Interface.sol
 *      - Satisfied.
 * 
 *    Must be able to burn their tokens. This amount would be subtracted
 *    from totalSupply.
 *      - Satisfied.
 * 
 *  Events:
 *    All standard events from ERC20Interface.sol
 *      - Satisfied.
 *    
 *    Fired on buyers burning their tokens
 *      - Satisfied.
 */

pragma solidity >= 0.8.10;


import './interfaces/ERC20Interface.sol';


/**
 * @title   A simple Token.
 * @dev     This contract s deployed by the Crowdsale.sol contract. When deployed
 *          it sets all initialSupply to be owned by the account that deployed 
 *          this contract. It also sets the owner of this contract to be the 
 *          contract address that deployed it, meaning the Crowdsale address.
 *          That way, burn() and mint() functions have restricted access. 
 */
contract Token is ERC20Interface {


    /*###############################################################
    #######       S T A T E    V A R I A B L E S             ########
    ################################################################*/

    // the initial amount of tokens.
    uint256 initialSupply;

    // keep track of who owns how many tokens.
    mapping(address => uint256) balances;

    // allowed[bob][alice] will contain a numTokens that
    // bob can spend from the account of alice.
    mapping (address => mapping (address => uint256)) private allowed;

    // needed in minting, burning. See the appropriate functions for more.
    address private immutable owner;


    /*###############################################################
    #######             E  V  E  N  T  S                     #######
    ################################################################*/

    event Burnt(address indexed _burner, uint256 indexed _tokens);


    /*##############################################################
    #######         M  O  D  I  F  I  E  R  S                #######
    ################################################################*/

    modifier ownerOnly 
    {
        require (msg.sender == owner, 
            "ONLY OWNER(S) ALLOWED TO DO THAT.");
        _;
    }


    /*##############################################################
    #######         C  O  N  S  T  R  U  C  T  O  R          #######
    ################################################################*/

    constructor(uint256 _initialSupply)
    {
        initialSupply = _initialSupply;
        totalSupply = _initialSupply;
        balances[msg.sender] = initialSupply;
        owner = msg.sender;
    }


    /*##############################################################
    #######         F  U  N  C  T  I  O  N  S                #######
    ################################################################*/

    /**
     *  @notice Returns the tokens that the _owner address owns.
     *  @return balance The amount of tokens owned by the _owner address.
     */
    function balanceOf(address _owner)
    view
    override
    public
    returns (uint256 balance)
    {
        uint256 tokensBought = balances[_owner];
        return tokensBought;
    }

    /**
     *  @notice Transfers _value tokens from the msg.sender address to the 
     *          _to address.
     *  @return success True if the transfer was successful, false otherwise.
     */
    function transfer(address _to, uint256 _value)
    override
    public
    returns (bool success)
    {
        if (balances[msg.sender] >= _value)
        {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }
    
    /**
     *  @notice Transfers _value tokens from the _from address to the _to address.
     *  @dev    Mainly used for refunding in Crowdsale. 
     *          For this function to succeed:
     *          1. the balance of the _from address should be greater than _value.
     *          2. the msg.sender should first have been allowed to spend _value 
     *             tokens from the _from address. In other words, the _from 
     *             account should first call the approve(msg.sender) function 
     *             first and then the msg.sender can call this function.
     *          The above explains how refunding steps work in the Crowdsale.
     *          A buyer must first call the approve(Crowdsale.address) function
     *          and then ask for a refund from the Crowsale contract.
     *  @return success True if the transfer was successful, false otherwise.
     */
    function transferFrom(address _from, address _to, uint256 _value)
    override
    public
    returns (bool success)
    {
        if (balances[_from]>=_value  &&  allowance(_from, msg.sender)>=_value)
        {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            return true;
        }
        return false;
    }

    /**
     *  @notice With this function, msg.sender gives the right to _spender 
     *          to spend _value tokens from the msg.sender acccount. 
     *  @dev    Used mainly for refunding in the Crowdsale contract.This function
     *          is not utilized in the Crowdsale contract. If a buyer wants to 
     *          have a refund he MUST call this function first directly.
     *  @return success True or false based on whether the approval succeded.
     */
    function approve(address _spender, uint256 _value)
    override
    public
    returns (bool success)
    {
        /// @dev this 'simple if' check tries to address the issue from
        /// https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM
        /// Although it does not much, it forces the allowed[msg.sender][_spender]
        /// value to be first set to 0.
        /// Of course, another possible way to address the issue would be to 
        /// totally change the -given to us- ERC20Interface by applying the
        /// proposal of the authors of this attack.
        if ((_value!=0) && (allowed[msg.sender][_spender] !=0))
            return false;
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     *  @notice Returns how many tokens the _spender can spend 
     *          from the _owner's account.
     *  @dev    Used mainly for refunding tokens in the Crowdsale contract.
     *  @return _allowance Number of tokens that the _spender can spend from
     *          the _owner acc.
     */ 
    function allowance(address _owner, address _spender)
    override
    view
    public
    returns (uint256 _allowance)
    {
        return allowed[_owner][_spender];
    }

    /**
     *  @notice Creates new tokens. 
     *  @dev    Only the deployer of the Crowdsale contract can call this
     *  @dev    function, and NOT directly (through a Token instance.) 
     *  @dev    He must call the mint() function of the Crowdsale contract. 
     *  @dev    No other users are allowed to mint tokens.
     */
    function mint(uint256 _tokens)
    ownerOnly
    public
    {
        totalSupply += _tokens;
        balances[owner] += _tokens;
    }
    

    /**
     *  @notice Burns tokens not sold yet. 
     *  @dev    Restricted access to this contract's father.Even the owner of
     *  @dev    the Crowdsale contract can not call this function directly and
     *  @dev    should use the Crowdsale contract to burn the tokens.
     */
    function burn(uint256 _tokens)
    ownerOnly
    public
    {   
        totalSupply -= _tokens;
        balances[msg.sender] -= _tokens;
        emit Burnt(msg.sender, _tokens);
    }

    /**
     *  @notice Gives the ability to any user to burn their acquired tokens.
     *  @dev    There is no function in the Crowdsale contract that utilizes 
     *  @dev    this function so it has to be directly called from a user if
     *  @dev    that user wants to burn their tokens.
     */ 
    function burnTokens(uint256 _tokens)
    public
    {
        require(balances[msg.sender] >= _tokens,
            "BALANCE IS LOWER THAN THE TOKENS SPECIFIED.");
        totalSupply -= _tokens;
        balances[msg.sender] -= _tokens;
        emit Burnt(msg.sender, _tokens);
    }

    /**
     *  @notice Return the total amount of tokens.
     *  @dev    since the `totalSupply` variable is inherited from the 
     *  @dev    ERC20Iface, we need to explicitly create a getter function 
     *  @dev    in the contract.
     *  @return totalSupply The total amount of tokens.
     */
    function getTotalSupply()
    view
    public
    returns (uint256)
    {
        return totalSupply;
    }
}

