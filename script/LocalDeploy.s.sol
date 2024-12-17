// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ContractSigner, MessageBoard} from "../src/ContractSigner.sol";

contract LocalDeployScript is Script {
    
    ContractSigner public contractSigner;
    MessageBoard public board;

    address public owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        contractSigner = new ContractSigner(owner);
        board = new MessageBoard();
        vm.stopBroadcast();
    }
}
