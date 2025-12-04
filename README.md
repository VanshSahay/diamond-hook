# Diamond Hook for Uniswap v4

A Uniswap v4 hook that **IS** a diamond proxy, enabling modular hook logic through facets. Write custom hook logic as facets and add them to your hook without modifying the core hook contract.

## Features

- 🎯 **Hook IS Diamond**: The hook contract itself is the diamond proxy - no separate diamond needed
- 🔧 **Modular Facets**: Add custom hook logic via facets
- 🚀 **Upgradeable**: Add, replace, or remove facets without redeploying the hook
- 📦 **Package Ready**: Install and use in your Foundry projects
- 🎨 **Simple API**: Clean interfaces for implementing custom hooks
- ⚡ **Gas Efficient**: Facets execute via delegatecall in the hook's context

## Installation

```bash
forge install VanshSahay/diamond-hook
```

Or add to your `foundry.toml`:

```toml
[dependencies]
diamond-hook = { git = "https://github.com/VanshSahay/diamond-hook.git", tag = "v0.1.0" }
```

Add to your `remappings.txt`:

```
diamond-hook/=lib/diamond-hook/src/
```

Then add to your `remappings.txt`:

```
diamond-hook/=lib/diamond-hook/src/
```

## Quick Start

### 1. Deploy HookDiamond

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {HookDiamond} from "diamond-hook/src/hook/HookDiamond.sol";
import {DiamondCutFacet} from "diamond-hook/src/diamond/facets/DiamondCutFacet.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";

contract DeployHook {
    function deploy(
        IPoolManager poolManager,
        address owner
    ) public returns (HookDiamond hook) {
        DiamondCutFacet cutFacet = new DiamondCutFacet();
        hook = new HookDiamond(poolManager, owner, address(cutFacet));
    }
}
```

### 2. Create a Custom Facet

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {BaseHook} from "@openzeppelin/uniswap-hooks/src/base/BaseHook.sol";

contract MyCustomFacet {
    event SwapExecuted(address indexed sender, uint256 timestamp);

    function beforeSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4, BeforeSwapDelta, uint24) {
        // Your custom logic here
        emit SwapExecuted(sender, block.timestamp);
        
        // Must return the correct selector
        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external returns (bytes4, int128) {
        // Your custom logic here
        
        return (BaseHook.afterSwap.selector, 0);
    }
}
```

### 3. Add Facet to HookDiamond

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {HookDiamond} from "diamond-hook/src/hook/HookDiamond.sol";
import {IDiamondCut} from "diamond-hook/src/diamond/interfaces/IDiamondCut.sol";
import {MyCustomFacet} from "./MyCustomFacet.sol";

contract AddFacet {
    function addFacetToHook(HookDiamond hook) public {
        MyCustomFacet facet = new MyCustomFacet();
        
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = MyCustomFacet.beforeSwap.selector;
        selectors[1] = MyCustomFacet.afterSwap.selector;
        
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });
        
        // Only owner can add facets
        IDiamondCut(address(hook)).diamondCut(cuts, address(0), "");
    }
}
```

## Architecture

### HookDiamond

The main hook contract that:
- Extends `BaseHook` (satisfies `IHooks` interface)
- Implements diamond proxy pattern (fallback delegates to facets)
- Routes hook function calls (`beforeSwap`, `afterSwap`, etc.) to facets if they exist
- Falls back to default behavior if no facet is found

### Facets

Facets are contracts that implement hook logic:
- Can implement any hook function (`beforeSwap`, `afterSwap`, etc.)
- Use `LibDiamond` or custom storage libraries for persistent state
- Execute in the hook's context via `delegatecall`
- Must return the correct function selectors

### Storage

Use custom storage libraries in facets (following diamond pattern):

```solidity
import {LibDiamond} from "diamond-hook/src/diamond/libraries/LibDiamond.sol";

library LibMyStorage {
    bytes32 constant MY_STORAGE_POSITION = keccak256("my.app.storage");
    
    struct MyStorage {
        uint256 counter;
        mapping(address => uint256) balances;
    }
    
    function myStorage() internal pure returns (MyStorage storage ms) {
        bytes32 position = MY_STORAGE_POSITION;
        assembly {
            ms.slot := position
        }
    }
}

// In your facet:
contract MyFacet {
    function increment() external {
        LibMyStorage.MyStorage storage ms = LibMyStorage.myStorage();
        ms.counter++;
    }
}
```

## Supported Hook Functions

All Uniswap v4 hook functions are supported:

- `beforeSwap` - Called before a swap executes
- `afterSwap` - Called after a swap executes  
- `beforeAddLiquidity` - Called before adding liquidity
- `afterAddLiquidity` - Called after adding liquidity
- `beforeRemoveLiquidity` - Called before removing liquidity
- `afterRemoveLiquidity` - Called after removing liquidity

## Examples

See the `src/examples/` directory for example facets:
- `SimpleCounterFacet` - Basic counter example

## Deployment Scripts

Example deployment scripts are in `script/examples/`:
- `00_DeployHookDiamond.s.sol` - Deploy the hook with core facets
- `01_AddFacet.s.sol` - Add a facet to an existing hook

### Using Deployment Scripts

```bash
# Deploy HookDiamond
forge script script/examples/00_DeployHookDiamond.s.sol \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast

# Add a facet (update HOOK_ADDRESS in script first)
forge script script/examples/01_AddFacet.s.sol \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast
```

## Hook Address Mining

Uniswap v4 hooks require specific address flags. Use `HookMiner` to find a valid salt:

```solidity
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";

uint160 flags = uint160(
    Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG 
    | Hooks.BEFORE_ADD_LIQUIDITY_FLAG | Hooks.AFTER_ADD_LIQUIDITY_FLAG
    | Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG | Hooks.AFTER_REMOVE_LIQUIDITY_FLAG
);

bytes memory constructorArgs = abi.encode(poolManager, owner, cutFacet);
address create2Factory = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
(address hookAddress, bytes32 salt) = HookMiner.find(
    create2Factory,
    flags,
    type(HookDiamond).creationCode,
    constructorArgs
);

// Deploy with salt
HookDiamond hook = new HookDiamond{salt: salt}(poolManager, owner, cutFacet);
```

## Development

### Build

```bash
forge build
```

### Test

```bash
forge test
```

### Format

```bash
forge fmt
```

## Project Structure

```
src/
├── hook/
│   └── HookDiamond.sol          # Main hook-diamond contract
├── diamond/
│   ├── facets/                   # Core diamond facets
│   ├── interfaces/               # Diamond interfaces
│   └── libraries/
│       └── LibDiamond.sol        # Diamond storage library
├── interfaces/
│   └── IHookFacet.sol            # Interface for hook facets
└── examples/
    └── SimpleCounterFacet.sol    # Example facet

script/
└── examples/
    ├── 00_DeployHookDiamond.s.sol
    └── 01_AddFacet.s.sol
```

## Best Practices

1. **Storage Libraries**: Always use storage libraries with unique storage positions
2. **Function Selectors**: Always return the correct function selector from hook functions
3. **Error Handling**: Handle errors gracefully - hook failures shouldn't break pools
4. **Gas Optimization**: Keep facet logic gas-efficient
5. **Testing**: Test facets thoroughly before adding to production hooks

## License

MIT

## Contributing

Contributions welcome! Please open an issue or PR.
