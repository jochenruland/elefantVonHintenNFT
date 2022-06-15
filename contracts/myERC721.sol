pragma solidity ^0.8.10;

// Intro
/* Non fungible tokens
 * Standard can represent virtual collectables but also pysical protoerty or "negative value assets" like loans f.ex.
 * Every ERC-721 compliant contract must implement (inherit from) the ERC721 interface and teh ERC165 interface
 * Ex. of ERC-721 -> Crypto Kitties : Kitten A -> tokenID 1, Kitten B -> tokenID 2 ; Do not necessarily be incremental ; Therfore tokenID !== token index
 * To address a specific nft you need the address of the ERC721 smart contract (like with ERC20) and the tokenID
 */

import "./ERC721Interface.sol";
import "./ERC721IReceiver.sol";
import "./addressUtils.sol";

contract myERC721 is ERC721Interface {
  using AddressUtils for address;

  // Magic Value equal to "bytes4(keccak256('onERC721Received(address,address,uint256,bytes)'))"
  bytes4 internal constant MAGIC_VAL_ERC721_RECEIVED = 0x150b7a02;

  mapping(address => uint) private _balances;
  mapping(uint256 => address) private _owners;
  mapping(uint256 => address) private _tokenApprovals;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  // cf. interface description
  /* If there balance of an owner address is 10 f.ex. it means that this owner has 10 nfts but they are all different
   * -> different tokenIDs
   * -> each token can have any kind of different properties (on Chain and off chain)
  */
  function balanceOf(address owner) external view returns(uint256) {
    require(owner != address(0), "Error: owner must be a valid address");
    return _balances[owner];
  }

  // cf. interface description
  // If I know the tokenId I can request the owner address of that tokenId
  function ownerOf(uint256 tokenId) external view returns (address owner) {
    address owner = _owners[tokenId];
    require(owner != address(0), "Error: it seems like this tokenId does not exist");
    return owner;
  }

  // cf. interface description
  /* possible to transfer a token from one address to another address (means attributing a new "owner" to the tokenId in the ERC721 contract)
   * trasferFrom does not check if the receipient is a smart contract which has implemented the IERC721Receiver function - this is implemented in safeTransferFrom 1&2 (just different signatures)
   * con be called by the owner, the operator and any address approved for the specific tokenId
   * The payable keyword is optional as you can decide in your implementation if you want the ERC721 contract to be able to receive ether or not (might be better to handle the money in a seperate contract)
   * Why specifying the from address when there is a mapping which knows the actual address of a tokenId -> the standard wants to be explicit about the combination of from and tokenId to make the transfer secure / otherwise throw an error
   */
  function transferFrom(address from, address to, uint256 tokenId) external payable {
    _transfer(from, to, tokenId);
  }

  // cf. interface description
  /* in case the receipient is a smart contract this function checks if it is able to handle ERC721 token; otherwise they will be blocked forever in the receipient contract
   * The handling smart contract must inherit from the ERC721TokenReceiver interface which allows to access the function onERC721Received(...)
   * The safeTransferFrom() function will call the onERC721Received(...) which returns function indentifer/magic value created by 'bytes4(keccak256('onERC721Received(address,address,uint256,bytes)'))'
   * If the safeTransferFrom recieves this magic value it continuous to processes the transfer; otherwise the transfer will be reverted
   * bytes data can be some arbitrary bytes which can be used to identify the transaction in the receipient contract; if you do not need that you can use the simplified version
   */
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external payable {
    _safeTransferFrom(from, to, tokenId, data);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) external payable {
    _safeTransferFrom(from, to, tokenId, "");
  }

  // cf. interface description
  /* allows the owner to approve someone else to be able to transfer the specific tokenId (needed for exchanges f.ex.)
   * this function can also be called the the operator
   */
  function approve(address to, uint256 tokenId) external {
    // check if the address to is allowed to approve someoneelse
    address owner = myERC721.ownerOf(tokenId);

    require(to != owner, "Error: to address is the current owner");
    require(msg.sender == owner, "Error: msg.sender not allowed to approve this tokenId");

    _tokenApprovals[tokenId] = to;

    emit Approval(owner, to, tokenId);

  }


  // cf. interface description
  /* the owner can define an operator which is an address generally approved for all tokens
   * the operator is also entitled to approve other addresses
   * An operator does not work per tokenId but per token owner
   */
  function setApprovalForAll(address operator, bool _approved) external {
    _operatorApprovals[msg.sender][operator] = _approved;

    emit ApprovalForAll(msg.sender, operator, _approved);
  }


  // cf. interface description
  function getApproved(uint256 tokenId) external view returns(address) {
    return _tokenApprovals[tokenId];
  }

  // cf. interface description
  // You can have multiple Operators for a single token owner
  function isApprovedForAll(address owner, address operator) external view returns(bool) {
    return _operatorApprovals[owner][operator];
  }

  // internal functions
  function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) internal {
    _transfer(_from, _to, _tokenId);

    if(_to.isContract()) {
      // call the smart contract functions
      bytes4 check = IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      // compare that with a predefined magic value
      require(check == MAGIC_VAL_ERC721_RECEIVED, "_to address cannot handle ERC721 token");
    }
  }


  // Important: this internal function does not have to be payable as the external function is going to receive the money
  function _transfer(address _from, address _to, uint256 _tokenId) internal allowedToTransfer(_tokenId) {

    _balances[_from] -= 1;
    _balances[_to] += 1;
    _owners[_tokenId] = to;

    emit Transfer(from, to, tokenId);
  }

  modifier allowedToTransfer(uint256 tokenId) {
    address owner = myERC721.ownerOf(tokenId);
    require(owner == msg.sender || _tokenApprovals[tokenId] == msg.sender || _operatorApprovals[owner][msg.sender] == true, "Error: msg.sender not allowed to transfer this token");
    _;
  }

}
