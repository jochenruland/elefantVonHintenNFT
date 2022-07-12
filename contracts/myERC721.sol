pragma solidity ^0.8.10;

// Inspired and some parts copied from openzeppelin implementation of ERC721 - MIT licence
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol

/* Non fungible tokens
 * Standard can represent virtual collectables but also pysical protoerty or "negative value assets" like loans f.ex.
 * Every ERC-721 compliant contract must implement (inherit from) the ERC721 interface and teh ERC165 interface
 * Ex. of ERC-721 -> Crypto Kitties : Kitten A -> tokenID 1, Kitten B -> tokenID 2 ; Do not necessarily be incremental ; Therfore tokenID !== token index
 * To address a specific nft you need the address of the ERC721 smart contract (like with ERC20) and the tokenID
 */

import "./ERC165.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";

/**
 * @dev IERC721Receiver will not be implemented in this contract; it will only serve to call onERC721Received() of other contracts
 */
import "./IERC721Receiver.sol";
import "./addressUtils.sol";
import "./Strings.sol";

contract MyERC721 is ERC165, IERC721, IERC721Metadata {
  using AddressUtils for address;
  using Strings for uint256;

  // Magic Value equal to "bytes4(keccak256('onERC721Received(address,address,uint256,bytes)'))"
  bytes4 internal constant MAGIC_VAL_ERC721_RECEIVED = 0x150b7a02;

  string private _name;
  string private _symbol;

  mapping(address => uint) private _balances;
  mapping(uint256 => address) private _owners;
  mapping(uint256 => address) private _tokenApprovals;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

 /**
 * @dev Event definition see {IERC721}
 */

 constructor(string memory name_, string memory symbol_)  {
   _name = name_;
   _symbol = symbol_;
 }

 /**
  * @dev See {ERC165-supportsInterface}.
  * Extends supportsInterface(bytes4 interfaceId) of ERC165 with Interfaces of this contract
  */
 function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
   return interfaceId == type(IERC721).interfaceId ||
     interfaceId == type(IERC721Metadata).interfaceId ||
     super.supportsInterface(interfaceId);
 }

 /**
 * @dev Returns the token collection name.
 */

 function name() public view override returns (string memory) {
   return _name;
  }

 /**
  * @dev Returns the token collection symbol.
  */
  function symbol() public view override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    string memory baseURI = _baseURI();

    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default. Has to be filled in before deployment.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  /**
   * @dev cf. description in interface {IERC721}
   * If the balance of an owner address is 10 f.ex. it means that this owner has 10 nfts but they are all different
   * -> different tokenIDs
   * -> each token can have any kind of different properties (on Chain and off chain)
  */
  function balanceOf(address owner) external view returns(uint256) {
    require(owner != address(0), "Error: owner must be a valid address");
    return _balances[owner];
  }

  /**
   * @dev cf. description in interface {IERC721}
   * Knowing the tokenId one can request the owner address of that tokenId
   */
  function ownerOf(uint256 tokenId) external view returns (address owner) {
    address owner = _owners[tokenId];
    require(owner != address(0), "Error: it seems like this tokenId does not exist");
    return owner;
  }

  /**
   * @dev cf. description in interface {IERC721}
   * It is possible to transfer a token from one address to another address (means attributing a new "owner" to the tokenId in the ERC721 contract)
   * trasferFrom does not check if the receipient is a smart contract which has implemented the IERC721Receiver function - this is implemented in safeTransferFrom 1&2 (just different signatures).
   * It con be called by the owner, the operator and any address approved for the specific tokenId.
   * The payable keyword is optional as you can decide in your implementation if you want the ERC721 contract to be able to receive ether or not (might be better to handle the money in a seperate contract)
   * Why specifying the from address when there is a mapping which knows the actual address of a tokenId -> the standard wants to be explicit about the combination of from and tokenId to make the transfer secure / otherwise throw an error
   */
  function transferFrom(address from, address to, uint256 tokenId) external {
    _transfer(from, to, tokenId);
  }

  /**
   * @dev cf. description in interface {IERC721}
   * In case the receipient is a smart contract this function checks if it is able to handle ERC721 token; otherwise they will be blocked forever in the receipient contract
   * The handling smart contract must inherit from the ERC721TokenReceiver interface which allows to access the function onERC721Received(...)
   * The safeTransferFrom() function will call the onERC721Received(...) which returns function indentifer/magic value created by 'bytes4(keccak256('onERC721Received(address,address,uint256,bytes)'))'
   * If the safeTransferFrom recieves this magic value it continuous to process the transfer; otherwise the transfer will be reverted
   * bytes data can be some arbitrary bytes which can be used to identify the transaction in the receipient contract; if you do not need that you can use the simplified version
   */
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external {
    _safeTransferFrom(from, to, tokenId, data);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) external {
    _safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev cf. description in interface {IERC721}
   * Allows the owner to approve someone else to be able to transfer the specific tokenId (needed for exchanges f.ex.)
   * This function can also be called by the operator
   */
  function approve(address to, uint256 tokenId) external {
    address owner = myERC721.ownerOf(tokenId);

    require(to != owner, "Error: to address is the current owner");
    require(msg.sender == owner || msg.sender == _tokenApprovals[tokenId] || _operatorApprovals[owner][msg.sender] == true, "Error: msg.sender not allowed to approve this tokenId");

    _tokenApprovals[tokenId] = to;

    emit Approval(owner, to, tokenId);

  }

  /**
   * @dev cf. description in interface {IERC721}
   * The owner can define an operator which is an address generally approved for all tokens
   * The operator is also entitled to approve other addresses
   * An operator does not work per tokenId but per token owner
   */
  function setApprovalForAll(address operator, bool _approved) external {
    _operatorApprovals[msg.sender][operator] = _approved;

    emit ApprovalForAll(msg.sender, operator, _approved);
  }

  // @dev cf. description in interface {IERC721}
  function getApproved(uint256 tokenId) external view returns(address) {
    return _tokenApprovals[tokenId];
  }

  /**
   * @dev cf. description in interface {IERC721}
   * You can have multiple Operators for a single token owner
   */
  function isApprovedForAll(address owner, address operator) external view returns(bool) {
    return _operatorApprovals[owner][operator];
  }

  // Internal functions
  function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) internal {
    _transfer(_from, _to, _tokenId);

    if(_to.isContract()) {
      bytes4 check = IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);

      require(check == MAGIC_VAL_ERC721_RECEIVED, "_to address cannot handle ERC721 token");
    }
  }

  function _transfer(address _from, address _to, uint256 _tokenId) internal allowedToTransfer(_tokenId) {

    _balances[_from] -= 1;
    _balances[_to] += 1;
    _owners[_tokenId] = to;

    emit Transfer(from, to, tokenId);
  }

  // Modifier
  modifier allowedToTransfer(uint256 tokenId) {
    address owner = myERC721.ownerOf(tokenId);
    require(owner == msg.sender || _tokenApprovals[tokenId] == msg.sender || _operatorApprovals[owner][msg.sender] == true, "Error: msg.sender not allowed to transfer this token");
    _;
  }

}
