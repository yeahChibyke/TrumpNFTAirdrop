// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Trumpd} from "./Trumpd.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Get Trumpd Airdrop
 * @author Chukwubuike Victory Chime a.k.a. yeahChibyke
 * @notice This contract handles the distribution of Trumpd NFTs via a Merkle Tree-based airdrop
 */
contract GetTrumpdAirdrop is EIP712, ReentrancyGuard {
    // >---> Errors
    /// @dev thrown when the provided Merkle proof is invalid
    error GTA__InvalidProof();
    /// @dev thrown when an account wants to get Trumpd more than once
    error GTA__AlreadyGotTrumpd();
    /// @dev thrown when the provided ECDSA signature is invalid
    error GTA__SignatureInvalid();

    // >---> Type Declaration
    /**
     * @dev Contains the necessary information for validating a user's claim
     * @param receiver The address that will receive the Trumpd NFT(s)
     * @param amount The number of Trumpd NFTs being claimed
     */
    struct TrumpdClaim {
        address receiver;
        uint256 amount;
    }

    // >---> Variables
    /// @dev array to store addresses of claimers
    address[] claimers;

    /// @dev Merkle root used to validate airdrop claims
    bytes32 private immutable i_merkleRoot;
    /// @dev ERC721 token being airdropped
    IERC721 private immutable i_trumpd;

    /// @dev mapping to track which addresses have already claimed their airdrop
    mapping(address => bool) private s_hasGotTrumpd;

    /// @dev keccak256 hash of the TrumpdClaim struct's type signature, used for EIP-712 compliant message signing
    bytes32 private constant MESSAGE_TYPEHASH = keccak256("TrumpdClaim(address receiver, uint256 amount)");

    // >---> Events
    /**
     * @dev emitted when a user successfully gets Trumpd
     * @param claimer address of claimer who got Trumpd
     * @param amount amount of tokens claimed
     */
    event GotTrumpd(address indexed claimer, uint256 indexed amount);

    // >---> Constructor
    constructor(bytes32 merkleRoot, IERC721 trumpd) EIP712("TrumpdAirdrop", "1") {
        i_merkleRoot = merkleRoot;
        i_trumpd = trumpd;
    }

    // >---> External Functions
    /**
     * @notice allows eligible users to claim their Trumpd NFT(s) from the airdrop
     * @dev ensures the user has not already claimed their airdrop, verifies their Merkle proof, and checks the ECDSA signature for validity
     * @param receiver address of the account receiving the Trumpd NFT(s)
     * @param amount number of Trumpd NFTs to claim
     * @param merkleProof Merkle proof proving the eligibility of the user for the airdrop
     * @param v recovery byte of the signature
     * @param r first 32 bytes of the signature
     * @param s second 32 bytes of the signature
     * @notice emits a {GotTrumpd} event upon successful claim
     *
     * @custom:error GTA__AlreadyGotTrumpd thrown if the receiver has already claimed their Trumpd NFT(s)
     * @custom:error GTA__SignatureInvalid thrown if the provided ECDSA signature is invalid
     * @custom:error GTA__InvalidProof thrown if the provided Merkle proof is invalid
     */
    function getTrumpd(address receiver, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s)
        external
        nonReentrant
    {
        if (s_hasGotTrumpd[receiver]) {
            revert GTA__AlreadyGotTrumpd();
        }

        if (!_isValidSignature(receiver, getMessageHash(receiver, amount), v, r, s)) {
            revert GTA__SignatureInvalid();
        }

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(receiver, amount))));

        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert GTA__InvalidProof();
        }

        s_hasGotTrumpd[receiver] = true;

        emit GotTrumpd(receiver, amount);

        // for (uint256 i = 0; i < amount; i++) {
        //     i_trumpd.safeTransferFrom(address(this), receiver, i); // Assuming i is the token ID
        // }
        i_trumpd.safeTransferFrom(address(this), receiver, amount);
    }

    // >---> Internal Functions
    /**
     * @notice validates the ECDSA signature for the Trumpd claim
     * @dev verifies that the signature provided corresponds to the receiver's address and message digest
     * @param receiver address that is expected to have signed the message
     * @param digest hashed message that was signed
     * @param v recovery byte of the signature
     * @param r first 32 bytes of the signature
     * @param s second 32 bytes of the signature
     * @return bool returns true if the signature is valid and was signed by the receiver, otherwise false
     */
    function _isValidSignature(address receiver, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        (address actualSigner,,) = ECDSA.tryRecover(digest, v, r, s);
        return actualSigner == receiver;
    }

    // >---> External & Public View Functions
    /**
     * @notice generates the EIP-712 message digest for a Trumpd claim
     * @dev creates a hash of the TrumpdClaim struct using the EIP-712 standard for typed structured data
     * @param receiver address claiming the Trumpd NFT(s)
     * @param amount number of Trumpd NFTs being claimed
     * @return bytes32 the hashed message that represents the Trumpd claim
     */
    function getMessageHash(address receiver, uint256 amount) public view returns (bytes32) {
        return
            _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, TrumpdClaim({receiver: receiver, amount: amount}))));
    }

    /// @dev provides the Merkle root stored in the contract, which is used to verify the legitimacy of a claim
    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    /// @dev provides the reference to the ERC721 token contract used for the airdrop
    function getTrumpdToken() external view returns (IERC721) {
        return i_trumpd;
    }

    function getClaimStatus(address claimant) external view returns (bool) {
        if (s_hasGotTrumpd[claimant]) {
            return true;
        } else {
            return false;
        }
    }
}
