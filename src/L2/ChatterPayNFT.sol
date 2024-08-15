// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error ChaterPayNFT__Unauthorized();

contract ChatterPayNFT is ERC721, ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;
    mapping (address => bool) public authorized;

    event Authorized(address indexed user, bool indexed value);

    modifier onlyOwnerOrAuthorized() {
        if(msg.sender != owner() && !authorized[msg.sender]) {
            revert ChaterPayNFT__Unauthorized();
        }
        _;
    }

    constructor(address initialOwner)
        ERC721("ChatterPayNFT", "CHTP")
        Ownable(initialOwner)
    {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://chatterpay-back-ylswtey2za-uc.a.run.app/nft/";
    }

    function safeMint(address to, string memory uri) public onlyOwnerOrAuthorized {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function setAuthorized(address user, bool value) public onlyOwner {
        authorized[user] = value;
        emit Authorized(user, value);
    }

    // The following functions are overrides required by Solidity.

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
