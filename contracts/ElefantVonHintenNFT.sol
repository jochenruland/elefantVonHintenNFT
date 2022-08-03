//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./MyERC721.sol";

contract ElefantVonHinten is MyERC721 {
  uint256 public maxTokens; // Maximum of tokens to be minted
  uint256 public maxMints; // Maximum of tokens to be minted at a time
  uint256 public tokenPrice;
  uint256 public totalSupply;

  string public baseTokenURI;

  constructor(
    string memory name,
    string memory symbol,
    string memory baseTokenURI_,
    uint256 maxTokens_,
    uint256 maxMints_,
    uint256 tokenPrice_,
    uint256 totalSupply_
  ) MyERC721(name, symbol) {
    maxTokens = maxTokens_;
    maxMints = maxMints_;
    tokenPrice = tokenPrice_;
    baseTokenURI = baseTokenURI_;

  }


}
