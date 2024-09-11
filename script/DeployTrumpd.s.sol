// SPDX-License-Identifier: mit
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {Trumpd} from "../src/Trumpd.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract DeployTrumpd is Script {
    function run() external returns (Trumpd) {
        string memory trumpdSvg = vm.readFile("./img/trumpd.svg");

        vm.startBroadcast();
        Trumpd trumpd = new Trumpd(svgToImageURI(trumpdSvg));
        vm.stopBroadcast();

        return trumpd;
    }

    function svgToImageURI(string memory svg) public pure returns (string memory) {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));
        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }
}
