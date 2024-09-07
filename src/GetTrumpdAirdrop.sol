// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Trumpd} from "./Trumpd.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract GetTrumpdAirdrop is EIP712, ReentrancyGuard {
    // >---> Errors
    error GTA__InvalidProof();
    error GTA__AlreadyGotTrumpd();
    error GTA__SignatureInvalid();

    // >---> Type Declaration
    struct TrumpdClaim {
        address receiver;
        uint256 amount;
    }

    // >---> Variables
    address[] claimers;

    bytes32 private immutable i_merkleRoot;
    IERC721 private immutable i_trumpd;

    mapping(address => bool) private s_hasGotTrumpd;

    bytes32 private constant MESSAGE_TYPEHASH = keccak256("TrumpdClaim(address receiver, uint256 amount)");

    // >---> Events
    event GotTrumpd(address indexed claimer, uint256 indexed amount);

    // >---> Constructor
    constructor(bytes32 merkleRoot, IERC721 trumpd) EIP712("TrumpdAirdrop", "1") {
        i_merkleRoot = merkleRoot;
        i_trumpd = trumpd;
    }

    // >---> External Functions
    function getTrumpd(address receiver, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s)
        external
        nonReentrant
    {
        if (s_hasGotTrumpd[receiver]) {
            revert GTA__AlreadyGotTrumpd();
        }

        // check signature validity
        if (!_isValidSignature(receiver, getMessage(receiver, amount), v, r, s)) {
            revert GTA__SignatureInvalid();
        }

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(receiver, amount))));

        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert GTA__InvalidProof();
        }

        s_hasGotTrumpd[receiver] = true;

        emit GotTrumpd(receiver, amount);

        for (uint256 i = 0; i < amount; i++) {
            i_trumpd.safeTransferFrom(address(this), receiver, i); // Assuming i is the token ID
        }
    }

    // >---> Internal Functions
    function _isValidSignature(address receiver, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        (address actualSigner,,) = ECDSA.tryRecover(digest, v, r, s);
        return actualSigner == receiver;
    }

    // >---> External & Public View Functions
    function getMessage(address receiver, uint256 amount) public view returns (bytes32) {
        return
            _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, TrumpdClaim({receiver: receiver, amount: amount}))));
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getTrumpdToken() external view returns (IERC721) {
        return i_trumpd;
    }
}
