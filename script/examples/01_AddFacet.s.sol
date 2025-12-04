// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {HookDiamond} from "../../src/hook/HookDiamond.sol";
import {IDiamondCut} from "../../src/diamond/interfaces/IDiamondCut.sol";
import {SimpleCounterFacet} from "../../src/examples/SimpleCounterFacet.sol";

/// @notice Example script to add a facet to HookDiamond
/// @dev Update HOOK_ADDRESS with your deployed HookDiamond address
contract AddFacetScript is Script {
    address constant HOOK_ADDRESS = address(0); // Update with your HookDiamond address

    function run() public {
        require(HOOK_ADDRESS != address(0), "Set HOOK_ADDRESS");

        vm.startBroadcast();

        HookDiamond hook = HookDiamond(payable(HOOK_ADDRESS));
        
        // Deploy your facet
        SimpleCounterFacet facet = new SimpleCounterFacet();

        // Prepare facet cut
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = SimpleCounterFacet.beforeSwap.selector;
        selectors[1] = SimpleCounterFacet.afterSwap.selector;

        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        // Add facet to hook
        IDiamondCut(address(hook)).diamondCut(cuts, address(0), "");

        vm.stopBroadcast();

        console.log("Facet added:", address(facet));
        console.log("Selectors added:");
        console.log("  - beforeSwap");
        console.log("  - afterSwap");
    }
}

