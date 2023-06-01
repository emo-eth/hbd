// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721} from "solady/tokens/ERC721.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {IERC5192} from "./interfaces/IERC5192.sol";

contract HBD is ERC721, IERC5192, Ownable {
    error TokenLocked();
    error NotOwner();

    address constant DEAD = address(uint160(0xDEAD));
    string constant BUTT_POINTER = "BUTT POINTER";
    bytes32 constant BUTT_HASH = keccak256(abi.encodePacked(BUTT_POINTER));

    string public baseURI;
    string public buttURI;
    mapping(uint256 tokenId => string overrideURI) uriOverrides;

    constructor(string memory _baseURI, string memory _buttURI) {
        baseURI = _baseURI;
        buttURI = _buttURI;
    }

    function name() public pure override returns (string memory) {
        return "HBD";
    }

    function symbol() public pure override returns (string memory) {
        return "HBD";
    }

    /**
     * @notice Mint a particular token to a particular address. OnlyOwner
     * @param to - recipient of the minted token.
     * @param tokenId - the identifier for the token.
     */
    function mint(address to, uint256 tokenId) public onlyOwner {
        _mint(to, tokenId);
    }

    /**
     * @notice Mint a particular token to a particular address, with a particular URI. OnlyOwner
     * @param to - recipient of the minted token.
     * @param tokenId - the identifier for the token.
     * @param uri - the URI for the token.
     */
    function mint(address to, uint256 tokenId, string calldata uri) public onlyOwner {
        _mint(to, tokenId);
        uriOverrides[tokenId] = uri;
    }

    /**
     * @notice Set the base URI for the token. OnlyOwner
     * @param uri - the new base URI for the token.
     */
    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    /**
     * @notice Set the "butt" URI for the token. OnlyOwner
     * @param uri - the new "butt" URI for the token.
     */
    function setButtURI(string memory uri) public onlyOwner {
        buttURI = uri;
    }

    /**
     * Set a custom URI for a token. OnlyOwner
     * @param tokenId The identifier for the token.
     */
    function overrideURI(uint256 tokenId, string memory uri) public onlyOwner {
        uriOverrides[tokenId] = uri;
    }

    /**
     * "Buttify" a token. OnlyOwner
     * @param tokenId The identifier for the token.
     */
    function buttify(uint256 tokenId) external onlyOwner {
        _buttify(tokenId);
    }

    /**
     * Determine if a token has been "buttified."
     * @param tokenId The identifier for the token.
     */
    function isButtified(uint256 tokenId) public view returns (bool) {
        return keccak256(abi.encodePacked(uriOverrides[tokenId])) == BUTT_HASH;
    }

    /**
     * @notice Burn a token. OnlyOwner
     * @param tokenId The identifier for the token.
     */
    function burn(uint256 tokenId) public onlyOwner {
        delete uriOverrides[tokenId];
        _burn(tokenId);
    }

    /**
     * @notice Get the URI for a token.
     * @param tokenId The identifier for the token.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // revert if token does not exist
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist();
        }
        string memory overriddenURI = uriOverrides[tokenId];
        // check for overrides
        if (bytes(overriddenURI).length > 0) {
            // check if hash of override matches BUTT_HASH
            if (keccak256(abi.encodePacked(overriddenURI)) == BUTT_HASH) {
                // return the butt uri
                return buttURI;
            }
            // return the overridden uri
            return overriddenURI;
        }
        // return the base uri
        return baseURI;
    }

    /**
     * @notice Overridden transfer logic to always revert, with a special surprise for those who try to burn theirs.
     * @param from - the address to transfer from.
     * @param to - the address to transfer to.
     * @param tokenId - the token to transfer.
     */
    function transferFrom(address from, address to, uint256 tokenId) public payable override {
        if (msg.sender != _ownerOf(tokenId) || from != msg.sender) {
            revert NotOwnerNorApproved();
        }
        if (to == address(0) || to == DEAD) {
            _buttify(tokenId);
            return;
        }
        revert TokenLocked();
    }

    /**
     * @notice If the token exists, return true, as all tokens are locked.
     * @param tokenId The identifier for the token.
     */
    function locked(uint256 tokenId) public view override returns (bool) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist();
        }
        return true;
    }

    function _buttify(uint256 tokenId) internal {
        uriOverrides[tokenId] = BUTT_POINTER;
    }

    /**
     * @dev after mint, emit an ERC5192 Locked event to signal to marketplaces that this token is not transferrable.
     */
    function _afterTokenTransfer(address from, address, uint256 tokenId) internal override {
        if (from == address(0)) {
            emit Locked(tokenId);
        }
    }
}
