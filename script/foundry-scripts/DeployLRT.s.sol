// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "forge-std/Script.sol";

import { LRTConfig } from "contracts/LRTConfig.sol";
import { RSETH } from "contracts/RSETH.sol";
import { LRTDepositPool } from "contracts/LRTDepositPool.sol";
import { LRTOracle } from "contracts/LRTOracle.sol";
import { NodeDelegator } from "contracts/NodeDelegator.sol";

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { MockToken } from "script/foundry-scripts/utils/MockToken.sol";

function deployProxy(address implementation, address proxyAdmin, bytes32 salt) returns (address) {
    TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy{salt: salt}(implementation, proxyAdmin, "");

    return address(proxy);
}

function computeProxyAddress(address implementation, address proxyAdmin, bytes32 salt) view returns (address) {
    bytes memory bytecode = type(TransparentUpgradeableProxy).creationCode;
    bytes memory initCode = abi.encodePacked(bytecode, abi.encode(implementation, proxyAdmin, ""));

    return Create2.computeAddress(salt, keccak256(initCode));
}

function getLSTs() returns (address stETH, address rETH, address cbETH) {
    uint256 chainId = block.chainid;

    if (chainId == 1) {
        // mainnet
        stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
        rETH = 0x9559Aaa82d9649C7A7b220E7c461d2E74c9a3593;
        cbETH = 0x6A023CCd1ff6F2045C3309768eAd9E68F978f6e1;
    } else {
        // testnet or test. Create MockTokens
        stETH = address(new MockToken("staked ETH", "stETH"));
        rETH = address(new MockToken("rETH", "rETH"));
        cbETH = address(new MockToken("cbETH", "cbETH"));
    }
}

contract DeployLRT is Script {
    address public proxyAdminOwner;
    ProxyAdmin public proxyAdmin;

    LRTConfig public lrtConfigProxy;
    RSETH public RSETHProxy;
    LRTDepositPool public lrtDepositPoolProxy;
    LRTOracle public lrtOracleProxy;
    NodeDelegator public nodeDelegatorProxy;

    function run() external {
        vm.startBroadcast();

        bytes32 salt = keccak256(abi.encodePacked("LRT-Stader-Labs"));
        proxyAdminOwner = msg.sender; // TODO: change to multisig when deploying to production

        // deploy implementation contracts
        address lrtConfigImplementation = address(new LRTConfig());
        address RSETHImplementation = address(new RSETH());
        address lrtDepositPoolImplementation = address(new LRTDepositPool());
        address lrtOracleImplementation = address(new LRTOracle());
        address nodeDelegatorImplementation = address(new NodeDelegator());

        console.log("LRTConfig implementation deployed at: ", lrtConfigImplementation);
        console.log("RSETH implementation deployed at: ", RSETHImplementation);
        console.log("LRTDepositPool implementation deployed at: ", lrtDepositPoolImplementation);
        console.log("LRTOracle implementation deployed at: ", lrtOracleImplementation);
        console.log("NodeDelegator implementation deployed at: ", nodeDelegatorImplementation);

        // deploy proxy contracts and initialize them
        lrtConfigProxy = LRTConfig(deployProxy(address(lrtConfigImplementation), address(proxyAdmin), salt));
        (address stETH, address rETH, address cbETH) = getLSTs();
        address predictedRSETHAddress = computeProxyAddress(RSETHImplementation, address(proxyAdmin), salt);
        // init LRTConfig
        lrtConfigProxy.initialize(proxyAdminOwner, stETH, rETH, cbETH, predictedRSETHAddress);

        RSETHProxy = RSETH(deployProxy(address(RSETHImplementation), address(proxyAdmin), salt));
        // init RSETH
        RSETHProxy.initialize(proxyAdminOwner, address(lrtConfigProxy));

        lrtDepositPoolProxy =
            LRTDepositPool(deployProxy(address(lrtDepositPoolImplementation), address(proxyAdmin), salt));
        // init LRTDepositPool
        lrtDepositPoolProxy.initialize(address(lrtConfigProxy));

        lrtOracleProxy = LRTOracle(deployProxy(address(lrtOracleImplementation), address(proxyAdmin), salt));
        // init LRTOracle
        lrtOracleProxy.initialize(address(lrtConfigProxy));

        nodeDelegatorProxy = NodeDelegator(deployProxy(address(nodeDelegatorImplementation), address(proxyAdmin), salt));
        // init NodeDelegator
        nodeDelegatorProxy.initialize(address(lrtConfigProxy));

        console.log("LRTConfig proxy deployed at: ", address(lrtConfigProxy));
        console.log("RSETH proxy deployed at: ", address(RSETHProxy));
        console.log("LRTDepositPool proxy deployed at: ", address(lrtDepositPoolProxy));
        console.log("LRTOracle proxy deployed at: ", address(lrtOracleProxy));
        console.log("NodeDelegator proxy deployed at: ", address(nodeDelegatorProxy));

        vm.stopBroadcast();
    }
}
