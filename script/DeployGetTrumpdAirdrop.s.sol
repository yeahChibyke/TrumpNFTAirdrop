// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Trumpd} from "../src/Trumpd.sol";
import {GetTrumpdAirdrop} from "../src/GetTrumpdAirdrop.sol";
import {Script, console2} from "forge-std/Script.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {DeployTrumpd} from "../script/DeployTrumpd.s.sol";

contract DeployGetTrumpdAirdrop is Script {
    bytes32 private s_merkleRoot = 0xb091e5f4c83e746fb7b261e2ca42c9f00eb1b7a6b51a00d34009c1dde3fd64a8;
    uint256 constant MINT_AMOUNT = 100;

    DeployTrumpd public deployer;

    /// @dev transferFrom() is used here instead of safeTransferFrom() which is used in the GetTrumpdAirdrop contract. This is because of the ERC721InvalidReceiverError returned by safeTransferFrom in testing
    function deployGetTrumpdAirdrop() public returns (Trumpd, GetTrumpdAirdrop) {
        vm.startBroadcast();

        string memory trumpdSvg = vm.readFile("./img/trumpd.svg");
        deployer = new DeployTrumpd();
        Trumpd nft = new Trumpd(deployer.svgToImageURI(trumpdSvg));
        GetTrumpdAirdrop airdrop = new GetTrumpdAirdrop(s_merkleRoot, IERC721(address(nft)));

        nft.mintTrumpd(nft.owner(), MINT_AMOUNT);

        // Set approval for all before transferring
        // nft.setApprovalForAll(address(airdrop), true);

        for (uint256 i = 0; i < MINT_AMOUNT; i++) {
            nft.transferFrom(nft.owner(), address(airdrop), i);
        }

        vm.stopBroadcast();

        return (nft, airdrop);
    }

    function run() external returns (Trumpd, GetTrumpdAirdrop) {
        return deployGetTrumpdAirdrop();
    }
}
