// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Trumpd} from "../src/Trumpd.sol";
import {GetTrumpdAirdrop} from "../src/GetTrumpdAirdrop.sol";
import {Test, console2} from "forge-std/Test.sol";
import {DeployGetTrumpdAirdrop} from "../script/DeployGetTrumpdAirdrop.s.sol";
import {DeployTrumpd} from "../script/DeployTrumpd.s.sol";

// import {ZkSyncChainChecker} from "Foundry-DevOps/src/ZkSyncChainChecker.sol";

contract TestGetTrumpdAirdrop is Test {
    Trumpd nft;
    GetTrumpdAirdrop airdrop;
    DeployTrumpd nftDeployer;

    bytes32 ROOT = 0x3f601979af393229b8a4df5331ee52d2774f84a3f830bef3c53bff161bec36b9;

    // ---- Proofs ---- //
    bytes32 proofB1 = 0xecfda6de7d57c0b4353df3846e3108d16ddf0b6ea0e91239096e83dc42a4d938;
    bytes32 proofB2 = 0x41385233c913ceb6f9d73ccb9862d5ff6b8d7e70f091ff703a51304a0f6a0e8f;
    bytes32[] bykeProof = [proofB1, proofB2];

    bytes32 proofI1 = 0xa4f94ef3322839d7c7e90e4d3e9d7a50c5b423d9d55a6a87c18602d977272709;
    bytes32 proofI2 = 0x41385233c913ceb6f9d73ccb9862d5ff6b8d7e70f091ff703a51304a0f6a0e8f;
    bytes32[] ifyProof = [proofI1, proofI2];

    bytes32 proofD1 = 0xa299000c17f67fa34ed241ddddd3fb9101d7b4bc11c7352c8c4193b5ccddcaf5;
    bytes32 proofD2 = 0x6d10680864762c1b878a7d27038bdffa2c65cf1aa81e80dfef5f1ca2794de275;
    bytes32[] daluProof = [proofD1, proofD2];

    bytes32 proofV1 = 0x83e03e23606faeb683b4ed0fc625fed0f6321a8d6abe5a3ceb0dfeeb5132c44e;
    bytes32 proofV2 = 0x6d10680864762c1b878a7d27038bdffa2c65cf1aa81e80dfef5f1ca2794de275;
    bytes32[] victoryProof = [proofV1, proofV2];

    uint256 constant CLAIM_AMOUNT = 1;
    uint256 constant SEND_AMOUNT = 10;

    address owner;
    address gasPayer;

    // multi users
    address Byke;
    uint256 bykePrvKey;
    address Ify;
    uint256 ifyPrvKey;
    address Dalu;
    uint256 daluPrvKey;
    address Victory;
    uint256 victoryPrvKey;

    function setUp() public {
        nftDeployer = new DeployTrumpd();
        nft = nftDeployer.run();
        airdrop = new GetTrumpdAirdrop(ROOT, nft);

        owner = nft.owner();

        vm.startPrank(owner);

        nft.mintTrumpd(owner, SEND_AMOUNT);
        nft.setApprovalForAll(address(airdrop), true);

        for (uint256 i = 0; i < SEND_AMOUNT; i++) {
            nft.transferFrom(owner, address(airdrop), i);
        }

        vm.stopPrank();

        (Byke, bykePrvKey) = makeAddrAndKey("Byke");
        (Ify, ifyPrvKey) = makeAddrAndKey("Ify");
        (Dalu, daluPrvKey) = makeAddrAndKey("Dalu");
        (Victory, victoryPrvKey) = makeAddrAndKey("Victory");

        gasPayer = makeAddr("gasPayer");
    }

    function testCanClaim() public {
        uint256 initBykeBal = nft.getAmountOfTrumpdOwned(Byke);
        uint256 nftInAirdrop = nft.getAmountOfTrumpdOwned(address(airdrop));

        bytes32 digest = airdrop.getMessageHash(Byke, CLAIM_AMOUNT);

        //  sign a message with Byke private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bykePrvKey, digest);

        vm.prank(gasPayer); // gasPayer calls the getTrumpd function using signed message
        airdrop.getTrumpd(Byke, CLAIM_AMOUNT, bykeProof, v, r, s);

        uint256 currentBykeBal = nft.getAmountOfTrumpdOwned(Byke);
        uint256 remNftInAirdrop = nft.getAmountOfTrumpdOwned(address(airdrop));

        assertEq(currentBykeBal - initBykeBal, CLAIM_AMOUNT);
        assertEq(remNftInAirdrop, nftInAirdrop - currentBykeBal);
        assert(airdrop.getClaimStatus(Byke) == true);
    }

    function testClaimFailWithInvalidSignature() public {
        uint8 v;
        bytes32 r;
        bytes32 s;

        vm.prank(gasPayer);
        vm.expectRevert(GetTrumpdAirdrop.GTA__SignatureInvalid.selector);
        airdrop.getTrumpd(Byke, CLAIM_AMOUNT, bykeProof, v, r, s);

        assert(airdrop.getClaimStatus(Byke) == false);
    }

    function testMultipleClaim() public {
        uint256 initIfyBal = nft.getAmountOfTrumpdOwned(Ify);
        uint256 initDaluBal = nft.getAmountOfTrumpdOwned(Dalu);
        uint256 initVictoryBal = nft.getAmountOfTrumpdOwned(Victory);
        uint256 initAirdropBal = nft.getAmountOfTrumpdOwned(address(airdrop));

        assert(initIfyBal == 0);
        assert(initDaluBal == 0);
        assert(initVictoryBal == 0);
        assert(initAirdropBal == SEND_AMOUNT);

        bytes32 ifyDigest = airdrop.getMessageHash(Ify, CLAIM_AMOUNT);
        bytes32 daluDigest = airdrop.getMessageHash(Dalu, CLAIM_AMOUNT);
        bytes32 victoryDigest = airdrop.getMessageHash(Victory, CLAIM_AMOUNT);

        // sign messages with respective user key
        (uint8 a, bytes32 b, bytes32 c) = vm.sign(ifyPrvKey, ifyDigest);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(daluPrvKey, daluDigest);
        (uint8 x, bytes32 y, bytes32 z) = vm.sign(victoryPrvKey, victoryDigest);

        // claim
        vm.startPrank(gasPayer);

        // Ify
        airdrop.getTrumpd(Ify, CLAIM_AMOUNT, ifyProof, a, b, c);
        uint256 finalIfyBal = nft.getAmountOfTrumpdOwned(Ify);
        uint256 currentAirdropBalAfterIfyClaim = nft.getAmountOfTrumpdOwned(address(airdrop));
        assert(finalIfyBal == CLAIM_AMOUNT);
        assert(finalIfyBal > initIfyBal);
        assert(initAirdropBal > currentAirdropBalAfterIfyClaim);
        assert(airdrop.getClaimStatus(Ify) == true);

        // Dalu
        airdrop.getTrumpd(Dalu, CLAIM_AMOUNT, daluProof, v, r, s);
        uint256 finalDaluBal = nft.getAmountOfTrumpdOwned(Dalu);
        uint256 currentAirdropBalAfterDaluClaim = nft.getAmountOfTrumpdOwned(address(airdrop));
        assert(finalDaluBal == CLAIM_AMOUNT);
        assert(finalDaluBal > initDaluBal);
        assert(currentAirdropBalAfterIfyClaim > currentAirdropBalAfterDaluClaim);
        assert(airdrop.getClaimStatus(Dalu) == true);

        // Victory
        airdrop.getTrumpd(Victory, CLAIM_AMOUNT, victoryProof, x, y, z);
        uint256 finalVictoryBal = nft.getAmountOfTrumpdOwned(Victory);
        uint256 finalAirdropBalAfterVictoryClaim = nft.getAmountOfTrumpdOwned(address(airdrop));
        assert(finalVictoryBal == CLAIM_AMOUNT);
        assert(finalVictoryBal > initVictoryBal);
        assert(currentAirdropBalAfterDaluClaim > finalAirdropBalAfterVictoryClaim);
        assert(airdrop.getClaimStatus(Victory) == true);

        vm.stopPrank();
    }

    function testRepeatClaimWillFail() public {
        uint256 initBykeBal = nft.balanceOf(Byke);
        uint256 airdropBalBeforeFirstClaim = nft.balanceOf(address(airdrop));

        assert(initBykeBal == 0);
        assert(airdropBalBeforeFirstClaim == SEND_AMOUNT);

        bytes32 digest = airdrop.getMessageHash(Byke, CLAIM_AMOUNT);
        (uint8 x, bytes32 y, bytes32 z) = vm.sign(bykePrvKey, digest);

        vm.prank(gasPayer);
        airdrop.getTrumpd(Byke, CLAIM_AMOUNT, bykeProof, x, y, z);
        uint256 finalBykeBal = nft.balanceOf(Byke);
        uint256 airdropBalAfterFirstClaim = nft.balanceOf(address(airdrop));

        assert(finalBykeBal == CLAIM_AMOUNT);
        assert(finalBykeBal > initBykeBal);
        assert(airdropBalBeforeFirstClaim > airdropBalAfterFirstClaim);

        // Try to claim again
        vm.prank(gasPayer);
        vm.expectRevert(GetTrumpdAirdrop.GTA__AlreadyGotTrumpd.selector);
        airdrop.getTrumpd(Byke, CLAIM_AMOUNT, bykeProof, x, y, z);
        uint256 bykeBalAfterFailclaim = nft.balanceOf(Byke);
        uint256 airdropBalAfterFailClaim = nft.balanceOf(address(airdrop));

        assert(finalBykeBal == bykeBalAfterFailclaim);
        assert(airdropBalAfterFirstClaim == airdropBalAfterFailClaim);
    }
}
