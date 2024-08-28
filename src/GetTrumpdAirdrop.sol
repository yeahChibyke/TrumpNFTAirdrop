// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Trumpd} from "./Trumpd.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract GetTrumpdAirdrop {
    // >---> Errors
    error GTA__InvalidProof();
    error GTA__AlreadyGotTrumpd();

    // >---> Variables
    address[] claimers;

    bytes32 private immutable i_merkleRoot;
    IERC721 private immutable i_trumpd;

    mapping(address => bool) private s_hasGotTrumpd;

    // >---> Events
    event GotTrumpd(address indexed claimer, uint256 indexed amount);

    // >---> Constructor
    constructor(bytes32 merkleRoot, IERC721 trumpd) {
        i_merkleRoot = merkleRoot;
        i_trumpd = trumpd;
    }

    // >---> External Functions
    function getTrumpd(address receiver, uint256 amount, bytes32[] calldata merkleProof) external {
        if (s_hasGotTrumpd[receiver]) {
            revert GTA__AlreadyGotTrumpd();
        }

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(receiver, amount))));

        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert GTA__InvalidProof();
        }

        s_hasGotTrumpd[receiver] = true;

        emit GotTrumpd(receiver, amount);

        i_trumpd.safeTransferFrom(address(i_trumpd), receiver, amount);
    }

    // >---> External Functions
    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getTrumpdToken() external view returns (IERC721) {
        return i_trumpd;
    }
}
