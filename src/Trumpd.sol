// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract Trumpd is ERC721, Ownable {
    // >------< Errors >-----<
    error ERC721Metadata__URI_QueryFor_NonExistentToken();

    // >------< Variables >-----<
    uint256 private s_tokenCounter;
    string private s_trumpdSvgImageUri;

    // >------< Events >-----<
    event TrumpdMinted(address indexed receiver);

    // >------< Constructor >-----<
    constructor(string memory trumpdSvgImageUri) ERC721("Trumpd NFT", "TRUMPD") Ownable(msg.sender) {
        s_tokenCounter = 0;
        s_trumpdSvgImageUri = trumpdSvgImageUri;
    }

    // >------< Functions >-----<
    function mintTrumpd(address receiver, uint256 amount) external {
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(receiver, s_tokenCounter);
            s_tokenCounter++;
        }

        emit TrumpdMinted(receiver);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (ownerOf(tokenId) == address(0)) {
            revert ERC721Metadata__URI_QueryFor_NonExistentToken();
        }
        string memory imageURI = s_trumpdSvgImageUri;

        return string(
            abi.encodePacked(
                _baseURI(),
                Base64.encode(
                    bytes( // bytes casting actually unnecessary as 'abi.encodePacked()' returns a bytes
                        abi.encodePacked(
                            '{"name":"',
                            name(),
                            '", "description":"Trumpd NFT. Wanna get Trumpd!!!", ',
                            '"attributes": [{"trait_type": "personality", "value": 100}], "image":"',
                            imageURI,
                            '"}'
                        )
                    )
                )
            )
        );
    }

    // >-----< Getter Functions >-----<
    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    function getAmountOfTrumpdOwned(address _holder) public view returns (uint256) {
        return balanceOf(_holder);
    }
}
