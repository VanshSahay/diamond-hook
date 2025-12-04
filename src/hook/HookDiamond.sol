// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseHook} from "@openzeppelin/uniswap-hooks/src/base/BaseHook.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager, SwapParams, ModifyLiquidityParams} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";

import {LibDiamond} from "../diamond/libraries/LibDiamond.sol";
import {IDiamondCut} from "../diamond/interfaces/IDiamondCut.sol";

/// @title HookDiamond
/// @notice A Uniswap v4 hook that IS a diamond proxy, allowing modular hook logic via facets
/// @dev This hook combines BaseHook functionality with diamond proxy pattern
/// Users can add facets to implement custom hook logic without modifying the hook itself
contract HookDiamond is BaseHook {
    using PoolIdLibrary for PoolKey;

    /// @notice Error thrown when trying to call a function that doesn't exist
    error FunctionNotFound(bytes4 selector);

    constructor(IPoolManager _poolManager, address _contractOwner, address _diamondCutFacet) BaseHook(_poolManager) {
        LibDiamond.setContractOwner(_contractOwner);

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        LibDiamond.diamondCut(cut, address(0), "");
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: true,
            afterAddLiquidity: true,
            beforeRemoveLiquidity: true,
            afterRemoveLiquidity: true,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    /// @notice Hook entry point - delegates to facet if exists, otherwise default behavior
    function _beforeSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookData
    ) internal override returns (bytes4, BeforeSwapDelta, uint24) {
        // Try to delegate to a facet that implements beforeSwap hook logic
        // Use the external function selector from IHooks interface
        bytes4 hookSelector = IHooks.beforeSwap.selector;
        address facet = _getFacet(hookSelector);
        
        if (facet != address(0)) {
            // Facet implements hook logic - delegatecall to it
            (bool success, bytes memory returnData) = facet.delegatecall(
                abi.encodeWithSelector(hookSelector, sender, key, params, hookData)
            );
            if (success && returnData.length > 0) {
                (bytes4 returnSelector, BeforeSwapDelta delta, uint24 hookReturn) = abi.decode(returnData, (bytes4, BeforeSwapDelta, uint24));
                return (returnSelector, delta, hookReturn);
            }
        }
        
        // Default behavior - no facet or facet returned empty
        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function _afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) internal override returns (bytes4, int128) {
        bytes4 hookSelector = IHooks.afterSwap.selector;
        address facet = _getFacet(hookSelector);
        
        if (facet != address(0)) {
            (bool success, bytes memory returnData) = facet.delegatecall(
                abi.encodeWithSelector(hookSelector, sender, key, params, delta, hookData)
            );
            if (success && returnData.length > 0) {
                (bytes4 returnSelector, int128 hookReturn) = abi.decode(returnData, (bytes4, int128));
                return (returnSelector, hookReturn);
            }
        }
        
        return (BaseHook.afterSwap.selector, 0);
    }

    function _beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) internal override returns (bytes4) {
        bytes4 hookSelector = IHooks.beforeAddLiquidity.selector;
        address facet = _getFacet(hookSelector);
        
        if (facet != address(0)) {
            (bool success, bytes memory returnData) = facet.delegatecall(
                abi.encodeWithSelector(hookSelector, sender, key, params, hookData)
            );
            if (success && returnData.length > 0) {
                return abi.decode(returnData, (bytes4));
            }
        }
        
        return BaseHook.beforeAddLiquidity.selector;
    }

    function _afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta0,
        BalanceDelta delta1,
        bytes calldata hookData
    ) internal override returns (bytes4, BalanceDelta) {
        bytes4 hookSelector = IHooks.afterAddLiquidity.selector;
        address facet = _getFacet(hookSelector);
        
        if (facet != address(0)) {
            (bool success, bytes memory returnData) = facet.delegatecall(
                abi.encodeWithSelector(hookSelector, sender, key, params, delta0, delta1, hookData)
            );
            if (success && returnData.length > 0) {
                (bytes4 returnSelector, BalanceDelta hookReturn) = abi.decode(returnData, (bytes4, BalanceDelta));
                return (returnSelector, hookReturn);
            }
        }
        
        return (BaseHook.afterAddLiquidity.selector, BalanceDelta.wrap(0));
    }

    function _beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) internal override returns (bytes4) {
        bytes4 hookSelector = IHooks.beforeRemoveLiquidity.selector;
        address facet = _getFacet(hookSelector);
        
        if (facet != address(0)) {
            (bool success, bytes memory returnData) = facet.delegatecall(
                abi.encodeWithSelector(hookSelector, sender, key, params, hookData)
            );
            if (success && returnData.length > 0) {
                return abi.decode(returnData, (bytes4));
            }
        }
        
        return BaseHook.beforeRemoveLiquidity.selector;
    }

    function _afterRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta0,
        BalanceDelta delta1,
        bytes calldata hookData
    ) internal override returns (bytes4, BalanceDelta) {
        bytes4 hookSelector = IHooks.afterRemoveLiquidity.selector;
        address facet = _getFacet(hookSelector);
        
        if (facet != address(0)) {
            (bool success, bytes memory returnData) = facet.delegatecall(
                abi.encodeWithSelector(hookSelector, sender, key, params, delta0, delta1, hookData)
            );
            if (success && returnData.length > 0) {
                (bytes4 returnSelector, BalanceDelta hookReturn) = abi.decode(returnData, (bytes4, BalanceDelta));
                return (returnSelector, hookReturn);
            }
        }
        
        return (BaseHook.afterRemoveLiquidity.selector, BalanceDelta.wrap(0));
    }

    /// @notice Get facet address for a function selector
    /// @param selector Function selector to look up
    /// @return facet Address of facet implementing this selector, or address(0) if none
    function _getFacet(bytes4 selector) internal view returns (address facet) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facet = ds.selectorToFacetAndPosition[selector].facetAddress;
    }

    /// @notice Fallback function for diamond proxy pattern
    /// @dev Routes calls to facets via delegatecall
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
        
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        if (facet == address(0)) {
            revert FunctionNotFound(msg.sig);
        }
        
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}

