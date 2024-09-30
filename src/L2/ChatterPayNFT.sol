// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error ChaterPayNFT__Unauthorized();

contract ChatterPayNFT is ERC721, ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;
    mapping(address => bool) public authorized;
    struct Metadata {
        string name;
        string description;
        string image;
    }

    mapping(uint256 => Metadata) private _tokenMetadata;

    event Authorized(address indexed user, bool indexed value);
    event Minted(address indexed to, uint256 indexed tokenId);

    modifier onlyOwnerOrAuthorized() {
        if (msg.sender != owner() && !authorized[msg.sender]) {
            revert ChaterPayNFT__Unauthorized();
        }
        _;
    }

    constructor(
        address initialOwner
    ) ERC721("ChatterPayNFT", "CHTP") Ownable(initialOwner) {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://chatterpay-back-ylswtey2za-uc.a.run.app/nft/";
    }

    function safeMint(
        address to,
        string memory image
    ) public onlyOwnerOrAuthorized {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _tokenMetadata[tokenId] = Metadata("chatterpay", "nft", image);
        // _setTokenURI(tokenId, uri);
        emit Minted(to, tokenId);
    }

    // Sobrescribir tokenURI para devolver metadatos en formato JSON directamente
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        Metadata memory metadata = _tokenMetadata[tokenId];
        return
            string(
                abi.encodePacked(
                    "data:application/json;utf8,",
                    '{"name":"',
                    metadata.name,
                    '", "description":"',
                    metadata.description,
                    '", "image":"',
                    metadata.image,
                    '"}'
                )
            );
    }

    function setAuthorized(address user, bool value) public onlyOwner {
        authorized[user] = value;
        emit Authorized(user, value);
    }

    // The following functions are overrides required by Solidity.

    // Función _exists para verificar si el tokenId ha sido minteado
    function _exists(uint256 tokenId) internal view returns (bool) {
        // Verificar si el token tiene un propietario
        try this.ownerOf(tokenId) returns (address owner) {
            return owner != address(0);
        } catch {
            return false;
        }
    }

    /*
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    */

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
