// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

// Inspired and some parts copied from openzeppelin implementation of ERC721 - MIT licence
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol


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

    mapping(address => uint256) private _balances;
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

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".png")) : "";

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
     * @dev Returns the number of tokens in `owner's` account.
     */
    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "ERROR: owner must be a valid address");
        return _balances[owner];
    }


    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERROR: it seems like this tokenId does not exist");
        return owner;
    }


    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external {
        _safeTransferFrom(from, to, tokenId, data);

    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        _safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = MyERC721.ownerOf(tokenId);
        require(to != owner, "ERROR: to address is the current owner");
        require(msg.sender == owner || msg.sender == _tokenApprovals[tokenId] || _operatorApprovals[owner][msg.sender] == true, "ERROR: msg.sender not allowed to approve");
        _tokenApprovals[tokenId] = to;

        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external {
        _operatorApprovals[msg.sender][operator] = _approved;

        emit ApprovalForAll(msg.sender, operator, _approved);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator){
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev cf. {_transfer}
     *
     * Requirements:
     * - if 'to' is a contract address it must be able to handle ERC721
     */
    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) internal {
        _transfer(_from, _to, _tokenId);

        if (_to.isContract()) {
            //check tokenReciever
            bytes4 checkValue = IERC721Receiver(_to).onERC721Received(msg.sender, _to, _tokenId, _data);
            require(checkValue == MAGIC_VAL_ERC721_RECEIVED, "ERROR: to cannot handle ERC721");
        }
    }

    /**
     * @dev Executes token transfer.
     *
     * Requirements:
     * - 'from' and 'to' cannot be a '0' address
     * - 'msg.sender' must be the owner, an approved address or an operator for the tokenId
     *
     * Emits an {Transfer} event,
     */
    function _transfer(address _from, address _to, uint256 _tokenId) internal allowedToTransfer(_tokenId) {
        require(_from != address(0) && _to != address(0), "ERROR: _from && _to must be a valid address");

        _balances[_from] -= 1;
        _balances[_to] +=1;
        _owners[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);

    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address _to, uint256 _tokenId) internal virtual {
        _safeMint(_to, _tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address _to, uint256 _tokenId, bytes memory _data) internal virtual {
        _mint(_to, _tokenId);

        if (_to.isContract()) {
            //check tokenReciever
            bytes4 checkValue = IERC721Receiver(_to).onERC721Received(msg.sender, _to, _tokenId, _data);
            require(checkValue == MAGIC_VAL_ERC721_RECEIVED, "ERROR: to cannot handle ERC721");
        }
    }


    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address _to, uint256 _tokenId) internal {
        require(_owners[_tokenId] == address(0), "ERROR: _tokenId already exists");
        require(_to != address(0), "ERROR: _to must be valid address - cannot be address(0)");

        _balances[_to] += 1;
        _owners[_tokenId] = _to;

        emit Transfer(address(0), _to, _tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 _tokenId) internal virtual {
        address owner = MyERC721.ownerOf(_tokenId);

        require(_owners[_tokenId] != address(0), "ERROR: _tokenId does not exist");

        approve(address(0), _tokenId);

        _balances[owner] -= 1;
        delete _owners[_tokenId];

        emit Transfer(owner, address(0), _tokenId);
    }

    /**
     * @dev Validates if 'msg.sender' is the owner of the tokenId, an approved address or an operator
     */
    modifier allowedToTransfer(uint256 tokenId) {
        address owner = MyERC721.ownerOf(tokenId); // 'ownerOf' is a external function, therefore it has to be referred to using 'this.ownerOf()' or 'MyERC721.ownerOf()'
        require(owner == msg.sender || _tokenApprovals[tokenId] == msg.sender || _operatorApprovals[owner][msg.sender] == true, "ERROR: msg.sender not allowed to tranfer tokenId");
        _;
    }

}
