// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.10;

/**
 * @title ERC20Interface
 * @dev ERC20 token standard: https://github.com/ethereum/EIPs/issues/20
 * As seen here: https://github.com/ConsenSys/Tokens/blob/master/contracts/Token.sol
 */
abstract contract ERC20Interface {
	/* This is a slight change to the ERC20 base standard.
	
    function totalSupply() view returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;

    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// returns The balance
    function balanceOf(address _owner) virtual view public returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// returns Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) virtual public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// returns Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) virtual public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// returns Whether the approval was successful or not
    function approve(address _spender, uint256 _value) virtual public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// returns Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) virtual view public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
