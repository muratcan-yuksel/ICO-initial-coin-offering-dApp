// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICryptoDevs.sol";

contract CryptoDevToken is ERC20, Ownable {
    //price of one crypto dev token
    uint256 public constant tokenPrice = 0.001 ether;
    //each NFT would give the user 10 tokens
    //it needs to be represented as 10 * (10 **18) as ERC20 tokens are represented by the smallest denomination possible for the token
    //by default ERC20 tokens have the smallest denomination of 10^(-18).
    //This means, having a balance of (1) is actually equal to (10 ^ -18) tokens.
    // Owning 1 full token is equivalent to owning (10^18) tokens when you account for the decimal places.
    // More information on this can be found in the Freshman Track Cryptocurrency tutorial.
    uint256 public constant tokensPerNFT = 10 * (10**18);
    //the max total suuply is 1000 tokens for crypto dev tokens following the above equation
    uint256 public constant maxTotalSupply = 10000 * (10**18);
    //cryptodevs contract instance
    ICryptoDevs CryptoDevsNFT;
    //mapping to keep track of which tokenIds have been claimed
    mapping(uint256 => bool) public tokenIdsClaimed;

    constructor(address _cryptoDevsContract) ERC20("CryptoDevToken", "CD") {
        CryptoDevsNFT = ICryptoDevs(_cryptoDevsContract);
    }

    /**
     *  Mints `amount` number of CryptoDevTokens
     * Requirements:
     * - `msg.value` should be equal or greater than the tokenPrice * amount
     */
    function mint(uint256 amount) public payable {
        //the value of the ether that should be equal or greate thab tokenPrice * amount
        uint256 _requiredAmount = tokenPrice * amount;
        require(msg.value >= _requiredAmount, "Not enough ether sent");
        //total tokens + amount <= 10000, otherwise revert the transaction
        require(
            (totalSupply() + amountWithDecimals) <= maxTotalSupply,
            "Exceeds the max total supply available."
        );
        //call the internal function from Openzeppelin's ERC20 contract
        _mint(msg.sender, amountWithDecimals);
    }

    /**
     *  Mints tokens based on the number of NFT's held by the sender
     * Requirements:
     * balance of Crypto Dev NFT's owned by the sender should be greater than 0
     * Tokens should have not been claimed for all the NFTs owned by the sender
     */

    function claim() public {
        address sender = msg.sender;
        //get the number of cryptodev nft's held by a given sender address
        uint256 balance = CryptoDevsNFT.balanceOf(sender);
        //if the balance is zero, revert the transaction
        require(balance > 0, "You do not own any CryptoDev NFTs");
        //amount keeps track of number of unclaimed tokenIds
        uint256 amount = 0;
        //loop over the balance and get the token ID owner by 'sender' at a given 'index' of its token list
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = CryptoDevsNFT.tokenOfOwnerByIndex(sender, i);
            // if the tokenId has not been claimed, increase the amount
            if (!tokenIdsClaimed[tokenId]) {
                amount += 1;
                tokenIdsClaimed[tokenId] = true;
            }
        }
        // If all the token Ids have been claimed, revert the transaction;
        require(amount > 0, "You have already claimed all the tokens");
        // call the internal function from Openzeppelin's ERC20 contract
        // Mint (amount * 10) tokens for each NFT
        _mint(msg.sender, amount * tokensPerNFT);
    }

    /**
     *  withdraws all ETH sent to this contract
     * Requirements:
     * wallet connected must be owner's address
     */

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "No ETH to withdraw");
        //calls the internal function from Openzeppelin's Ownable contract to get the owner of this contract
        address _owner = owner();
    }
}
