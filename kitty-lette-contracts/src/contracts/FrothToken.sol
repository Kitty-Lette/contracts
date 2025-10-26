// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FrothToken
 * @notice Mock ERC20 token for testing the Kitty Lette NFT Roulette dApp.
 * @dev This contract is for hackathon/demo purposes only.
 *      Mint function is publicly available for testing ease.
 */

import {ERC20} from "@openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";

contract FrothToken is ERC20, Ownable {
    uint8 private constant DECIMALS = 18;

    constructor() ERC20("Froth Token", "FROTH") Ownable(msg.sender) {
        // Mint initial supply to the contract deployer (1 million tokens)
        _mint(msg.sender, 1_000_000 * (10 ** DECIMALS));
    }

    /**
     * @notice Mint additional tokens for testing.
     * @param to The address receiving the newly minted tokens.
     * @param amount The amount to mint (in wei).
     */
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    /**
     * @notice Returns the number of decimals used for user representation.
     */
    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }
}
