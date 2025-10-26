// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Kitty Lette - NFT Roulette Game
 * @notice Players use $FROTH tokens to spin the wheel and mint unique NFTs with varying rarities.
 * @dev Designed for hackathon MVPs with clean, modular, and secure architecture.
 */

import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC721} from "@openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {RandomnessLib} from "./libraries/RandomnessLib.sol";
import {NFTTypes} from "./types/NFTTypes.sol";

contract KittyLette is ERC721URIStorage, Ownable {
    IERC20 public frothToken;

    uint256 public nextTokenId;
    uint256 public spinCost = 10 * 1e18;
    uint256 public nonce;

    // ---- Platform fee (1%) ----
    uint256 public platformFeeBps = 100; // 1% in basis points
    address public platformFeeRecipient;

    // ---- Configurable rarity weights (sum must be 10_000) ----
    uint16 public weightCommon = 7000;     // 70.00%
    uint16 public weightRare = 2500;       // 25.00%
    uint16 public weightLegendary = 450;   // 4.50%
    uint16 public weightMythic = 50;       // 0.50%

    // ---- Default metadata URIs for each rarity ----
    mapping(NFTTypes.Rarity => string) public rarityMetadataURIs;

    struct NftData {
        NFTTypes.Rarity rarity;
    }

    mapping(uint256 => NftData) public nftDetails;

    event NFTMinted(address indexed user, uint256 tokenId, NFTTypes.Rarity rarity, string tokenUri);
    event SpinExecuted(address indexed user, uint256 cost, NFTTypes.Rarity rarity);
    event PlatformFeeUpdated(uint256 newFeeBps);
    event PlatformFeeRecipientUpdated(address newRecipient);
    event RarityWeightsUpdated(uint16 common, uint16 rare, uint16 legendary, uint16 mythic);
    event RarityMetadataUpdated(NFTTypes.Rarity indexed rarity, string newMetadata);

    constructor(address _frothToken, address _platformFeeRecipient)
        ERC721("Kitty Lette NFT", "KLETTE")
        Ownable(msg.sender)
    {
        require(_frothToken != address(0), "Invalid FROTH address");
        require(_platformFeeRecipient != address(0), "Invalid recipient address");
        frothToken = IERC20(_frothToken);
        platformFeeRecipient = _platformFeeRecipient;
        
        // Initialize default metadata URIs
        rarityMetadataURIs[NFTTypes.Rarity.Common] = "ipfs://common-cat.json";
        rarityMetadataURIs[NFTTypes.Rarity.Rare] = "ipfs://rare-cat.json";
        rarityMetadataURIs[NFTTypes.Rarity.Legendary] = "ipfs://legendary-cat.json";
        rarityMetadataURIs[NFTTypes.Rarity.Mythic] = "ipfs://mythic-cat.json";
    }

    // ---------------- Core ----------------

    /**
     * @notice Spin the roulette to mint a random rarity NFT.
     * @dev Player must have approved the contract to spend $FROTH beforehand.
     */
    function spinWheel() external {
        require(frothToken.balanceOf(msg.sender) >= spinCost, "Insufficient FROTH balance");
        require(frothToken.allowance(msg.sender, address(this)) >= spinCost, "Approve FROTH first");

        // Calculate platform fee (1%)
        uint256 platformFee = (spinCost * platformFeeBps) / 10_000;
        uint256 remaining = spinCost - platformFee;

        // Transfer cost and fee
        require(frothToken.transferFrom(msg.sender, address(this), remaining), "Transfer failed");
        require(frothToken.transferFrom(msg.sender, platformFeeRecipient, platformFee), "Fee transfer failed");

        // Generate rarity
        NFTTypes.Rarity rarity = _getRandomRarity();

        // Mint NFT
        uint256 tokenId = nextTokenId++;
        _safeMint(msg.sender, tokenId);
        nftDetails[tokenId] = NftData(rarity);

        emit SpinExecuted(msg.sender, spinCost, rarity);
        emit NFTMinted(msg.sender, tokenId, rarity, _rarityMetadata(rarity));
    }

    /**
     * @notice Weighted rarity selection using configurable weights.
     * @dev Uses cumulative distribution to map a random number to a rarity bucket.
     */
    function _getRandomRarity() internal returns (NFTTypes.Rarity) {
        uint256 rand = RandomnessLib.random(nonce++) % 10_000; // 0..9999
        uint256 c = weightCommon;
        uint256 r = c + weightRare;
        uint256 l = r + weightLegendary;
        // total = 10_000 (validated in setter)

        if (rand < c) return NFTTypes.Rarity.Common;
        if (rand < r) return NFTTypes.Rarity.Rare;
        if (rand < l) return NFTTypes.Rarity.Legendary;
        return NFTTypes.Rarity.Mythic;
    }

    /**
     * @notice Returns sample metadata URI for each rarity.
     * @dev Replace with IPFS URIs or metadata server for production.
     */
    function _rarityMetadata(NFTTypes.Rarity rarity) internal view returns (string memory) {
        return rarityMetadataURIs[rarity];
    }

    // ---------------- Admin: Spin Config ----------------

    function setSpinCost(uint256 _newCost) external onlyOwner {
        require(_newCost > 0, "Invalid cost");
        spinCost = _newCost;
    }

    // ---------------- Admin: Platform Fee ----------------

    function setPlatformFee(uint256 _newFeeBps) external onlyOwner {
        require(_newFeeBps <= 500, "Fee too high");
        platformFeeBps = _newFeeBps;
        emit PlatformFeeUpdated(_newFeeBps);
    }

    function setPlatformFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Invalid address");
        platformFeeRecipient = _newRecipient;
        emit PlatformFeeRecipientUpdated(_newRecipient);
    }

    // ---------------- Admin: Rarity Weights ----------------

    /**
     * @notice Update rarity weights (basis points). Sum must equal 10_000.
     * @dev Useful for testing or balancing game odds.
     */
    function setRarityWeights(
        uint16 _common,
        uint16 _rare,
        uint16 _legendary,
        uint16 _mythic
    ) external onlyOwner {
        require(
            uint256(_common) + _rare + _legendary + _mythic == 10_000,
            "Weights must sum to 10_000"
        );

        weightCommon = _common;
        weightRare = _rare;
        weightLegendary = _legendary;
        weightMythic = _mythic;

        emit RarityWeightsUpdated(_common, _rare, _legendary, _mythic);
    }

    /**
     * @notice Testing preset: higher Mythic odds (10%).
     */
    function setTestingWeights() external onlyOwner {
        weightCommon = 4000;     // 40.00%
        weightRare = 3500;       // 35.00%
        weightLegendary = 1500;  // 15.00%
        weightMythic = 1000;     // 10.00%
        emit RarityWeightsUpdated(4000, 3500, 1500, 1000);
    }

    /**
     * @notice Production preset: realistic rarity odds.
     */
    function setProductionWeights() external onlyOwner {
        weightCommon = 7000;
        weightRare = 2500;
        weightLegendary = 450;
        weightMythic = 50;
        emit RarityWeightsUpdated(7000, 2500, 450, 50);
    }

    // ---------------- Admin: Rarity Metadata Management ----------------

    /**
     * @notice Update metadata URI for a specific rarity.
     * @dev All NFTs with this rarity will use the new metadata URI.
     * @param rarity The rarity type (0=Common, 1=Rare, 2=Legendary, 3=Mythic).
     * @param newMetadataUri The new metadata URI for this rarity.
     */
    function setRarityMetadata(NFTTypes.Rarity rarity, string calldata newMetadataUri) external onlyOwner {
        require(bytes(newMetadataUri).length > 0, "URI cannot be empty");
        rarityMetadataURIs[rarity] = newMetadataUri;
        emit RarityMetadataUpdated(rarity, newMetadataUri);
    }

    /**
     * @notice Batch update metadata URIs for all rarities.
     * @param commonUri Metadata URI for Common rarity.
     * @param rareUri Metadata URI for Rare rarity.
     * @param legendaryUri Metadata URI for Legendary rarity.
     * @param mythicUri Metadata URI for Mythic rarity.
     */
    function setAllRarityMetadata(
        string calldata commonUri,
        string calldata rareUri,
        string calldata legendaryUri,
        string calldata mythicUri
    ) external onlyOwner {
        require(bytes(commonUri).length > 0, "Common URI cannot be empty");
        require(bytes(rareUri).length > 0, "Rare URI cannot be empty");
        require(bytes(legendaryUri).length > 0, "Legendary URI cannot be empty");
        require(bytes(mythicUri).length > 0, "Mythic URI cannot be empty");

        rarityMetadataURIs[NFTTypes.Rarity.Common] = commonUri;
        rarityMetadataURIs[NFTTypes.Rarity.Rare] = rareUri;
        rarityMetadataURIs[NFTTypes.Rarity.Legendary] = legendaryUri;
        rarityMetadataURIs[NFTTypes.Rarity.Mythic] = mythicUri;

        emit RarityMetadataUpdated(NFTTypes.Rarity.Common, commonUri);
        emit RarityMetadataUpdated(NFTTypes.Rarity.Rare, rareUri);
        emit RarityMetadataUpdated(NFTTypes.Rarity.Legendary, legendaryUri);
        emit RarityMetadataUpdated(NFTTypes.Rarity.Mythic, mythicUri);
    }

    /**
     * @notice Get metadata URI for a specific rarity.
     * @param rarity The rarity type to query.
     * @return The metadata URI for this rarity.
     */
    function getRarityMetadata(NFTTypes.Rarity rarity) external view returns (string memory) {
        return rarityMetadataURIs[rarity];
    }

    /**
     * @notice Override tokenURI to always return rarity-based metadata.
     * @dev This ensures all NFTs of the same rarity share the same metadata.
     * @param tokenId The token ID to query.
     * @return The metadata URI based on the token's rarity.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        NFTTypes.Rarity rarity = nftDetails[tokenId].rarity;
        return rarityMetadataURIs[rarity];
    }

    // ---------------- Admin: Withdraw ----------------

    function withdrawFroth(address _to) external onlyOwner {
        uint256 balance = frothToken.balanceOf(address(this));
        require(balance > 0, "No balance to withdraw");
        require(frothToken.transfer(_to, balance), "Withdraw failed");
    }
}
