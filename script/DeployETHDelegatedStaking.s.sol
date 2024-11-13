// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/ETHDelegatedStaking.sol";

contract DeployETHDelegatedStaking is Script {
    function run() external {
        address validator = vm.envAddress("VALIDATOR_ADDRESS");

        vm.startBroadcast();

        ETHDelegatedStaking staking = new ETHDelegatedStaking(validator);
        console.log("ETHDelegatedStaking deployed at:", address(staking));

        vm.stopBroadcast();
    }
}
