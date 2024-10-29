// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC721URIStorageUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

error ChatterPayNFT__Unauthorized();
error ChatterPayNFT__TokenAlreadyMinted(uint256);
error ChatterPayNFT__OriginalTokenNotMinted(uint256);
error ChatterPayNFT__LimitExceedsCopies();

contract ChatterPayNFT is UUPSUpgradeable, ERC721Upgradeable, ERC721URIStorageUpgradeable, OwnableUpgradeable {
    
    uint256 private s_tokenId;
    mapping (uint256 tokenId => address minter) public s_originalMinter;
    mapping(uint256 tokenId => uint256 copies) public s_copyCount;
    mapping(uint256 tokenId => uint256 copyLimit) public s_copyLimit;
    string private s_baseURI;

    function initialize(address initialOwner, string memory baseURI) public initializer {
        __ERC721_init("ChatterPayNFT", "CHTP");
        __Ownable_init(initialOwner);
        s_baseURI = baseURI;
    }

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _baseURI() internal view override returns (string memory) {
        return s_baseURI;
    }

    function mintOriginal(address to, string memory uri) public {
        s_tokenId++;
        if(s_tokenId % 10 == 0) s_tokenId++;
        uint256 tokenId = s_tokenId;
        s_copyLimit[tokenId] = 1000; // default limit
        // The msg.sender (who pays for the gas) is the original minter
        s_originalMinter[tokenId] = msg.sender;
        // The NFT goes to the recipient
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function mintCopy(address to, uint256 originalTokenId, string memory uri) public {
        if(s_originalMinter[originalTokenId] == address(0)) revert ChatterPayNFT__OriginalTokenNotMinted(originalTokenId);
        if(s_copyCount[originalTokenId] >= s_copyLimit[originalTokenId]) revert ChatterPayNFT__LimitExceedsCopies();
        s_copyCount[originalTokenId]++;
        uint256 copyTokenId = originalTokenId * 10**8 + s_copyCount[originalTokenId];
        _mint(to, copyTokenId);
        _setTokenURI(copyTokenId, uri);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        s_baseURI = _newBaseURI;
    }

    function setCopyLimit(uint256 tokenId, uint256 newLimit) public {
        if(msg.sender != s_originalMinter[tokenId]) revert ChatterPayNFT__Unauthorized();
        if(newLimit < s_copyCount[tokenId]) revert ChatterPayNFT__LimitExceedsCopies();
        s_copyLimit[tokenId] = newLimit;
    }

    // The following functions are overrides required by Solidity.
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
