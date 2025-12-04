// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {SwapParams, ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";

/// @title IHookFacet
/// @notice Interface for hook facets that implement hook logic
/// @dev Facets implementing this interface can be added to HookDiamond to customize hook behavior
interface IHookFacet {
    /// @notice Hook function called before a swap
    /// @param sender The address initiating the swap
    /// @param key The pool key
    /// @param params Swap parameters
    /// @param hookData Additional hook data
    /// @return selector Function selector to return
    /// @return delta BeforeSwapDelta to return
    /// @return hookReturn Additional hook return value
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4 selector, BeforeSwapDelta delta, uint24 hookReturn);

    /// @notice Hook function called after a swap
    /// @param sender The address initiating the swap
    /// @param key The pool key
    /// @param params Swap parameters
    /// @param delta Balance delta from the swap
    /// @param hookData Additional hook data
    /// @return selector Function selector to return
    /// @return hookReturn Additional hook return value
    function afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external returns (bytes4 selector, int128 hookReturn);

    /// @notice Hook function called before adding liquidity
    /// @param sender The address initiating the liquidity addition
    /// @param key The pool key
    /// @param params Modify liquidity parameters
    /// @param hookData Additional hook data
    /// @return selector Function selector to return
    function beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4 selector);

    /// @notice Hook function called after adding liquidity
    /// @param sender The address initiating the liquidity addition
    /// @param key The pool key
    /// @param params Modify liquidity parameters
    /// @param delta0 Balance delta for currency0
    /// @param delta1 Balance delta for currency1
    /// @param hookData Additional hook data
    /// @return selector Function selector to return
    /// @return hookReturn BalanceDelta to return
    function afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta0,
        BalanceDelta delta1,
        bytes calldata hookData
    ) external returns (bytes4 selector, BalanceDelta hookReturn);

    /// @notice Hook function called before removing liquidity
    /// @param sender The address initiating the liquidity removal
    /// @param key The pool key
    /// @param params Modify liquidity parameters
    /// @param hookData Additional hook data
    /// @return selector Function selector to return
    function beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4 selector);

    /// @notice Hook function called after removing liquidity
    /// @param sender The address initiating the liquidity removal
    /// @param key The pool key
    /// @param params Modify liquidity parameters
    /// @param delta0 Balance delta for currency0
    /// @param delta1 Balance delta for currency1
    /// @param hookData Additional hook data
    /// @return selector Function selector to return
    /// @return hookReturn BalanceDelta to return
    function afterRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta0,
        BalanceDelta delta1,
        bytes calldata hookData
    ) external returns (bytes4 selector, BalanceDelta hookReturn);
}

