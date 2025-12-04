// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {HookDiamond} from "../../src/hook/HookDiamond.sol";
import {DiamondCutFacet} from "../../src/diamond/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../../src/diamond/facets/DiamondLoupeFacet.sol";
import {DiamondInit} from "../../src/diamond/facets/DiamondInit.sol";
import {IDiamondCut} from "../../src/diamond/interfaces/IDiamondCut.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {AddressConstants} from "hookmate/constants/AddressConstants.sol";

/// @notice Example deployment script for HookDiamond
/// @dev This script deploys HookDiamond with core facets
contract DeployHookDiamondScript is Script {
    function run() public {
        vm.startBroadcast();

        // Get PoolManager address (adjust for your network)
        IPoolManager poolManager = IPoolManager(AddressConstants.getPoolManagerAddress(block.chainid));
        
        // Deploy core facets
        DiamondCutFacet cutFacet = new DiamondCutFacet();
        DiamondLoupeFacet loupeFacet = new DiamondLoupeFacet();
        DiamondInit init = new DiamondInit();

        // Deploy HookDiamond
        HookDiamond hook = new HookDiamond(
            poolManager,
            msg.sender, // owner
            address(cutFacet)
        );

        // Add DiamondLoupeFacet
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
        bytes4[] memory loupeSelectors = new bytes4[](4);
        loupeSelectors[0] = 0x7a0ed627; // facets()
        loupeSelectors[1] = 0xadfca15e; // facetFunctionSelectors(address)
        loupeSelectors[2] = 0x52ef6b2c; // facetAddresses()
        loupeSelectors[3] = 0xcdffacc6; // facetAddress(bytes4)

        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(loupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });

        IDiamondCut(address(hook)).diamondCut(
            cuts,
            address(init),
            abi.encodeWithSelector(DiamondInit.init.selector)
        );

        vm.stopBroadcast();

        console.log("HookDiamond deployed at:", address(hook));
        console.log("DiamondCutFacet:", address(cutFacet));
        console.log("DiamondLoupeFacet:", address(loupeFacet));
    }
}

