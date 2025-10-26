// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library RandomnessLib {
    function random(uint256 nonce) internal view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, nonce)
            )
        );
    }
}
