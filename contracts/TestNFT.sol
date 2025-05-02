// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title TestNFT
 * @dev 简单的测试NFT合约，用于开发测试
 */
contract TestNFT is ERC721 {
    uint256 private _tokenIdCounter;
    
    constructor() ERC721("Test NFT", "TEST") {
        _tokenIdCounter = 1;
    }
    
    function mint(address to) external returns (uint256) {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _safeMint(to, tokenId);
        return tokenId;
    }
    
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter - 1;
    }
}