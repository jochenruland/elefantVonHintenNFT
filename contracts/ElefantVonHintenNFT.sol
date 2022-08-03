//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./MyERC721.sol";

contract ElefantVonHinten is MyERC721 {
  uint256 public maxTokens; // Maximum of tokens to be minted
  uint256 public maxMints; // Maximum of tokens to be minted at a time
  uint256 public tokenPrice;
  uint256 public totalSupply;

  string public baseTokenURI;

  /**
  * @dev All state variables are initialized in the constructor.
  * To be more flexible one could define setter functions for each state variable and call them in the constructor.
  * We will keep it as simple as possible here.
  */
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

  /**
   * @dev Overrides the corresponding internal function in MyERC721
   * the resulting URI for each token will be the concatenation of the `baseTokenURI` and the `tokenId`.
   */
  function _baseURI() internal view override returns (string memory) {
    return baseTokenURI;
  }




}
