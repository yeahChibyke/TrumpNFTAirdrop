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

    bytes32 ROOT = 0xb091e5f4c83e746fb7b261e2ca42c9f00eb1b7a6b51a00d34009c1dde3fd64a8;

    bytes32 proof_A = 0x8b2a4240244fa16f1700a049d06193952b863cf8f9f7995b98c5087db703ca9f;
    bytes32 proof_B = 0x77f9fa2b202c3292f1531c6d875a714eb429dd5bffc6640b6bbd7c9c4e79d1d5;
    bytes32[] PROOF = [proof_A, proof_B];

    address user;
    uint256 userPrvKey;
    uint256 constant CLAIM_AMOUNT = 25;
    uint256 constant SEND_AMOUNT = 100;

    address owner;

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

        (user, userPrvKey) = makeAddrAndKey("user");
    }

    function testGTASetUp() public view {
        uint256 airdropBal = nft.getAmountOfTrumpdOwned(address(airdrop));
        uint256 ownerBal = nft.getAmountOfTrumpdOwned(owner);

        console2.log(airdropBal);
        console2.log(ownerBal);

        console2.log("Th is the user: ", user);
        console2.log("This is the userPrvKey: ", userPrvKey);
    }

    function testUserCanClaim() public {
        uint256 initbalOfUser = nft.getAmountOfTrumpdOwned(user);
        uint256 nftInAirdrop = nft.getAmountOfTrumpdOwned(address(airdrop));

        vm.prank(user);
        airdrop.getTrumpd(user, CLAIM_AMOUNT, PROOF);

        uint256 currentBalOfUser = nft.getAmountOfTrumpdOwned(user);
        uint256 remNftInAirdrop = nft.getAmountOfTrumpdOwned(address(airdrop));

        console2.log("This is the initBalOfUser: ", initbalOfUser);
        console2.log("This is the nftInAirdrop: ", nftInAirdrop);
        console2.log("This is the currentBalOfUser: ", currentBalOfUser);
        console2.log("This is the remNftInAirdrop: ", remNftInAirdrop);

        // assertEq(currentBalOfUser - initbalOfUser, CLAIM_AMOUNT);
        // assertEq(remNftInAirdrop, nftInAirdrop - currentBalOfUser);
    }
}
