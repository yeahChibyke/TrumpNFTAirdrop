// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Trumpd} from "../src/Trumpd.sol";
import {GetTrumpdAirdrop} from "../src/GetTrumpdAirdrop.sol";
import {Test, console2} from "forge-std/Test.sol";
import {DeployGetTrumpdAirdrop} from "../script/DeployGetTrumpdAirdrop.s.sol";

import {ZkSyncChainChecker} from "Foundry-DevOps/src/ZkSyncChainChecker.sol";

contract TestGetTrumpdAirdrop is ZkSyncChainChecker, Test {}
