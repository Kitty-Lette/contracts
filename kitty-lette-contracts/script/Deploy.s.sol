// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {FrothToken} from "../src/contracts/FrothToken.sol";
import {KittyLette} from "../src/contracts/KittyLette.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying contracts with deployer:", deployer);
        console.log("Deployer balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy FrothToken first
        FrothToken frothToken = new FrothToken();
        console.log("FrothToken deployed at:", address(frothToken));
        
        // Deploy KittyLette with FrothToken address and deployer as platform fee recipient
        KittyLette kittyLette = new KittyLette(
            address(frothToken),
            deployer // Platform fee recipient
        );
        console.log("KittyLette deployed at:", address(kittyLette));
        
        // Mint some FROTH tokens for testing (10,000 tokens)
        frothToken.mint(deployer, 10_000 * 1e18);
        console.log("Minted 10,000 FROTH tokens to deployer");
        
        vm.stopBroadcast();
        
        console.log("\n=== Deployment Summary ===");
        console.log("FrothToken:", address(frothToken));
        console.log("KittyLette:", address(kittyLette));
        console.log("Deployer:", deployer);
        console.log("FROTH Balance:", frothToken.balanceOf(deployer) / 1e18, "tokens");
        console.log("Spin Cost:", kittyLette.spinCost() / 1e18, "FROTH");
    }
}