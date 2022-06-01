pragma solidity ^0.5.2;

import {
    ERC721Full
} from "openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";

import "./ChildToken.sol";
import "./misc/IParentToken.sol";

contract ChildERC721 is ChildToken, ERC721Full {
    event Deposit(address indexed token, address indexed from, uint256 tokenId);

    event Withdraw(
        address indexed token,
        address indexed from,
        uint256 tokenId
    );

    event LogTransfer(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 tokenId
    );

    constructor(
        address _owner,
        address _token,
        string memory name,
        string memory symbol
    ) public ERC721Full(name, symbol) {
        require(_token != address(0x0) && _owner != address(0x0));
        parentOwner = _owner;
        token = _token;
    }

    function transferWithSig(
        bytes calldata sig,
        uint256 tokenId,
        bytes32 data,
        uint256 expiration,
        address to
    ) external returns (address) {
        require(
            expiration == 0 || block.number <= expiration,
            "Signature is expired"
        );

        bytes32 dataHash = getTokenTransferOrderHash(
            msg.sender,
            tokenId,
            data,
            expiration
        );
        require(disabledHashes[dataHash] == false, "Sig deactivated");
        disabledHashes[dataHash] = true;

        // recover address and send tokens
        address from = ecrecovery(dataHash, sig);
        _transferFrom(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, ""),
            "_checkOnERC721Received failed"
        );
        return from;
    }

    function setParent(address _parent) public isParentOwner {
        require(_parent != address(0x0));
        parent = _parent;
    }

    function approve(address to, uint256 tokenId) public {
        revert("Disabled feature");
    }

    function getApproved(uint256 tokenId)
        public
        view
        returns (address operator)
    {
        revert("Disabled feature");
    }

    function setApprovalForAll(address operator, bool _approved) public {
        revert("Disabled feature");
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool)
    {
        revert("Disabled feature");
    }

    /**
   * @notice Deposit tokens
   * @param user address for deposit
   * @param tokenId tokenId to mint to user's account
   */
    function deposit(address user, uint256 tokenId) public onlyOwner {
        require(user != address(0x0));
        _mint(user, tokenId);
        emit Deposit(token, user, tokenId);
    }

    /**
   * @notice Withdraw tokens
   * @param tokenId tokenId of the token to be withdrawn
   */
    function withdraw(uint256 tokenId) public payable {
        require(ownerOf(tokenId) == msg.sender);
        _burn(msg.sender, tokenId);
        emit Withdraw(token, msg.sender, tokenId);
    }

    /**
   * @dev Overriding the inherited method so that it emits LogTransfer
   */
    function transferFrom(address from, address to, uint256 tokenId) public {
        if (
            parent != address(0x0) &&
            !IParentToken(parent).beforeTransfer(msg.sender, to, tokenId)
        ) {
            return;
        }
        _transferFrom(from, to, tokenId);
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);
        emit LogTransfer(token, from, to, tokenId);
    }
}
