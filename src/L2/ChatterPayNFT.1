// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error ChatterPayNFT__Unauthorized();
error ChatterPayNFT__TokenAlreadyMinted(uint256);
error ChatterPayNFT__OriginalTokenNotMinted(uint256);
error ChatterPayNFT__LimitExceedsCopies();

contract ChatterPayNFT is ERC721, ERC721URIStorage, Ownable {
    
    uint256 private s_tokenId;
    mapping (address => bool) public s_authorized;
    mapping (uint256 tokenId => address minter) public s_originalMinter;
    mapping(uint256 tokenId => uint256 copies) public s_copyCount;
    mapping(uint256 tokenId => uint256 copyLimit) public s_copyLimit;
    string private s_baseURI;

    event Authorized(address indexed user, bool indexed value);

    modifier onlyOwnerOrAuthorized() {
        if(msg.sender != owner() && !s_authorized[msg.sender]) {
            revert ChatterPayNFT__Unauthorized();
        }
        _;
    }

    constructor(address initialOwner, string memory baseURI)
        ERC721("ChatterPayNFT", "CHTP")
        Ownable(initialOwner)
    {
        s_baseURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return s_baseURI;
    }

    function mintOriginal(address to, string memory uri) public onlyOwnerOrAuthorized {
        s_tokenId++; // index 1
        if(s_tokenId % 10 == 0) s_tokenId++; // never ending in 0 to avoid conflicts with copies
        uint256 tokenId = s_tokenId;
        s_copyLimit[tokenId] = 1000; // default limit
        if(s_originalMinter[tokenId] != address(0)) revert ChatterPayNFT__TokenAlreadyMinted(tokenId);
        s_originalMinter[tokenId] = to;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function mintCopy(address to, uint256 originalTokenId) public onlyOwnerOrAuthorized {
        if(s_originalMinter[originalTokenId] == address(0)) revert ChatterPayNFT__OriginalTokenNotMinted(originalTokenId);
        if(s_copyCount[originalTokenId] >= s_copyLimit[originalTokenId]) revert ChatterPayNFT__LimitExceedsCopies();
        s_copyCount[originalTokenId]++;
        uint256 copyTokenId = originalTokenId * 10**8 + s_copyCount[originalTokenId];
        string memory uri = tokenURI(originalTokenId);
        _safeMint(to, copyTokenId);
        _setTokenURI(copyTokenId, uri);
    }

    function setAuthorized(address user, bool value) public onlyOwner {
        s_authorized[user] = value;
        emit Authorized(user, value);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        s_baseURI = _newBaseURI;
    }

    function setCopiesLimit(uint256 tokenId, uint256 newLimit) public {
        if(msg.sender != s_originalMinter[tokenId]) revert ChatterPayNFT__Unauthorized();
        if(newLimit < s_copyCount[tokenId]) revert ChatterPayNFT__LimitExceedsCopies();
        s_copyLimit[tokenId] = newLimit;
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
