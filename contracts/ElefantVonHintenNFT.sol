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

  /**
   * @dev Minting and token sale
   * @params numberOfTokens - number of tokens to be minted
   * Requirements
   * - numberOfTokens must be inferior or equal to maxMints
   * - totalSupply must stay inferior or equal to maxTokens
   * - must send enough ether to pay all token minted
   */
  function mintElefants(uint256 numberOfTokens) external payable {
    require(numberOfTokens <= maxMints, "ERROR: only up to maxMints token allowed to be minted");
    require(totalSupply + numberOfTokens <= maxTokens, "ERROR: maximum amount of tokens has already be minted");
    require(tokenPrice * numberOfTokens <= msg.value , "ERROR: not enough ether sent to mint all tokens");

    for(uint i=0, i < numberOfTokens, i++) {
      if(totalSupply < maxTokens) {
        _safeMint(msgSender(), totalSupply);
        totalSupply++;
      }
    }

  }




}
