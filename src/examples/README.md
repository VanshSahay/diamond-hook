# Example Facets

This directory contains example facets that demonstrate how to create custom hook logic for HookDiamond.

## SimpleCounterFacet

A basic example that counts swap events. This demonstrates:
- Implementing hook functions (`beforeSwap`, `afterSwap`)
- Returning the correct function selectors
- Storing state in the diamond's storage

## Creating Your Own Facet

1. Create a new contract that implements the hook functions you need
2. Use `LibDiamond` for storage if you need persistent state
3. Return the correct function selectors (e.g., `BaseHook.beforeSwap.selector`)
4. Deploy your facet
5. Add it to your HookDiamond using `diamondCut`

### Example Structure

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseHook} from "@openzeppelin/uniswap-hooks/src/base/BaseHook.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";

contract MyCustomFacet {
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4, BeforeSwapDelta, uint24) {
        // Your custom logic here
        
        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }
    
    // Implement other hook functions as needed
}
```

