//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./MyERC721.sol";
import "./Context.sol";
import "./Ownable.sol";

contract ElefantVonHinten is MyERC721, Context, Ownable {
  uint256 public maxTokens; // Maximum of tokens to be minted
  uint256 public maxMints; // Maximum of tokens to be minted at a time
  uint256 public tokenPrice;
  uint256 public totalSupply;

  string public baseTokenURI;

  /**
   * @dev Only name and symbol of the collection will be initialized in the constructor
   * All other state variables will be defined by the owner in the initialize function
   * to be able to upload collection assets to ipfs first and pass the returned CID to baseTokenURI
   */
  constructor(
    string memory name,
    string memory symbol
  ) MyERC721(name, symbol) {}

  /* SETTERS */
  function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function setMaxTokens(uint256 _maxTokens) public onlyOwner {
    maxTokens = _maxTokens;
  }

  function setMaxMints(uint256 _maxMints) public onlyOwner {
    maxMints = _maxMints;
  }

  function setTokenPrice(uint256 _tokenPrice) public onlyOwner {
    tokenPrice = _tokenPrice;
  }


  /* GETTERS */
  /**
   * @dev Overrides the corresponding internal function in MyERC721
   * the resulting URI for each token will be the concatenation of the `baseTokenURI` and the `tokenId`.
   */
  function _baseURI() internal view override returns (string memory) {
    return baseTokenURI;
  }

  /**
   * @dev Minting and token sale
   * @param numberOfTokens - number of tokens to be minted
   * Requirements
   * - numberOfTokens must be inferior or equal to maxMints
   * - totalSupply must stay inferior or equal to maxTokens
   * - must send enough ether to pay all token minted
   */
  function mintElefants(uint256 numberOfTokens) external payable {
    require(numberOfTokens <= maxMints, "ERROR: only up to maxMints token allowed to be minted");
    require(totalSupply + numberOfTokens <= maxTokens, "ERROR: maximum amount of tokens has already be minted");
    require(tokenPrice * numberOfTokens <= msg.value , "ERROR: not enough ether sent to mint all tokens");

    for(uint i=0; i < numberOfTokens; i++) {
      if(totalSupply < maxTokens) {
        _safeMint(_msgSender(), totalSupply);
        totalSupply++;
      }
    }

  }




}
