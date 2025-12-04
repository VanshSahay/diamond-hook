# Usage Guide

This guide explains how to use the Diamond Hook package in your projects.

## Table of Contents

1. [Installation](#installation)
2. [Basic Usage](#basic-usage)
3. [Creating Facets](#creating-facets)
4. [Storage Patterns](#storage-patterns)
5. [Advanced Patterns](#advanced-patterns)

## Installation

### Foundry Project

```bash
forge install VanshSahay/diamond-hook
```

Add to `remappings.txt`:
```
diamond-hook/=lib/diamond-hook/src/
```

### Hardhat/NPM

```bash
npm install @blockc/diamond-hook
```

## Basic Usage

### Step 1: Deploy HookDiamond

```solidity
import {HookDiamond} from "diamond-hook/src/hook/HookDiamond.sol";
import {DiamondCutFacet} from "diamond-hook/src/diamond/facets/DiamondCutFacet.sol";

// Deploy facets
DiamondCutFacet cutFacet = new DiamondCutFacet();

// Deploy hook (must mine address first - see Hook Address Mining)
HookDiamond hook = new HookDiamond(poolManager, owner, address(cutFacet));
```

### Step 2: Create Your Facet

```solidity
contract MyFacet {
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4, BeforeSwapDelta, uint24) {
        // Your logic here
        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }
}
```

### Step 3: Add Facet to Hook

```solidity
import {IDiamondCut} from "diamond-hook/src/diamond/interfaces/IDiamondCut.sol";

MyFacet facet = new MyFacet();

IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
bytes4[] memory selectors = new bytes4[](1);
selectors[0] = MyFacet.beforeSwap.selector;

cuts[0] = IDiamondCut.FacetCut({
    facetAddress: address(facet),
    action: IDiamondCut.FacetCutAction.Add,
    functionSelectors: selectors
});

IDiamondCut(address(hook)).diamondCut(cuts, address(0), "");
```

## Creating Facets

### Facet Structure

A facet is a contract that implements hook functions. Each hook function must:

1. Match the exact signature from `IHooks` interface
2. Return the correct function selector
3. Handle errors gracefully

### Example: Counter Facet

```solidity
contract CounterFacet {
    using LibCounterStorage for LibCounterStorage.CounterStorage;
    
    function beforeSwap(...) external returns (bytes4, BeforeSwapDelta, uint24) {
        LibCounterStorage.CounterStorage storage cs = LibCounterStorage.counterStorage();
        cs.beforeSwapCount++;
        
        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }
}
```

### Example: Fee Facet

```solidity
contract FeeFacet {
    using LibFeeStorage for LibFeeStorage.FeeStorage;
    
    function beforeSwap(...) external returns (bytes4, BeforeSwapDelta, uint24) {
        LibFeeStorage.FeeStorage storage fs = LibFeeStorage.feeStorage();
        
        // Apply fee logic
        uint256 fee = calculateFee(params.amountSpecified, fs.feeRate);
        
        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }
}
```

## Storage Patterns

### Diamond Storage Pattern

Use unique storage positions to avoid collisions:

```solidity
library LibMyStorage {
    bytes32 constant MY_STORAGE_POSITION = keccak256("my.app.storage");
    
    struct MyStorage {
        uint256 value;
        mapping(address => uint256) balances;
    }
    
    function myStorage() internal pure returns (MyStorage storage ms) {
        bytes32 position = MY_STORAGE_POSITION;
        assembly {
            ms.slot := position
        }
    }
}
```

### Using Storage in Facets

```solidity
contract MyFacet {
    function setValue(uint256 value) external {
        LibMyStorage.MyStorage storage ms = LibMyStorage.myStorage();
        ms.value = value;
    }
    
    function getValue() external view returns (uint256) {
        LibMyStorage.MyStorage storage ms = LibMyStorage.myStorage();
        return ms.value;
    }
}
```

## Advanced Patterns

### Multi-Facet Hook

You can add multiple facets to handle different concerns:

```solidity
// Facet 1: Fee logic
FeeFacet feeFacet = new FeeFacet();

// Facet 2: Access control
AccessControlFacet accessFacet = new AccessControlFacet();

// Facet 3: Analytics
AnalyticsFacet analyticsFacet = new AnalyticsFacet();

// Add all facets
IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](3);
// ... configure cuts
IDiamondCut(address(hook)).diamondCut(cuts, address(0), "");
```

### Facet Communication

Facets can call each other through the hook:

```solidity
contract FacetA {
    function doSomething() external {
        // Call another facet
        (bool success, bytes memory data) = address(this).call(
            abi.encodeWithSelector(FacetB.doSomethingElse.selector)
        );
    }
}
```

### Replacing Facets

You can upgrade facets:

```solidity
// Deploy new version
FeeFacetV2 newFeeFacet = new FeeFacetV2();

IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
cuts[0] = IDiamondCut.FacetCut({
    facetAddress: address(newFeeFacet),
    action: IDiamondCut.FacetCutAction.Replace, // Replace, not Add
    functionSelectors: selectors
});

IDiamondCut(address(hook)).diamondCut(cuts, address(0), "");
```

### Removing Facets

```solidity
IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
cuts[0] = IDiamondCut.FacetCut({
    facetAddress: address(0), // Must be zero for Remove
    action: IDiamondCut.FacetCutAction.Remove,
    functionSelectors: selectors
});

IDiamondCut(address(hook)).diamondCut(cuts, address(0), "");
```

## Hook Address Mining

Uniswap v4 requires hooks to have specific address flags. Use `HookMiner`:

```solidity
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";

function deployHook() public returns (HookDiamond hook, bytes32 salt) {
    uint160 flags = uint160(
        Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG
    );
    
    bytes memory constructorArgs = abi.encode(poolManager, owner, cutFacet);
    address create2Factory = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    
    (address hookAddress, bytes32 salt) = HookMiner.find(
        create2Factory,
        flags,
        type(HookDiamond).creationCode,
        constructorArgs
    );
    
    hook = new HookDiamond{salt: salt}(poolManager, owner, cutFacet);
    require(address(hook) == hookAddress, "Address mismatch");
}
```

## Testing

### Testing Facets

```solidity
import {Test} from "forge-std/Test.sol";
import {HookDiamond} from "diamond-hook/src/hook/HookDiamond.sol";
import {MyFacet} from "../src/MyFacet.sol";

contract MyFacetTest is Test {
    HookDiamond hook;
    MyFacet facet;
    
    function setUp() public {
        // Deploy hook and facet
        // Add facet to hook
    }
    
    function testBeforeSwap() public {
        // Test your facet logic
    }
}
```

## Troubleshooting

### Function Not Found

If you get "Function does not exist" error:
- Check that the facet was added with the correct selector
- Verify the function signature matches exactly

### Storage Collisions

If storage values are overwritten:
- Use unique storage position constants
- Check that storage libraries use different positions

### Hook Not Executing

If hook functions aren't being called:
- Verify hook address has correct flags
- Check that pool was created with the hook
- Ensure facet was added correctly

## Best Practices

1. **Always return correct selectors** - Hook functions must return the right selector
2. **Use storage libraries** - Prevents storage collisions
3. **Handle errors gracefully** - Don't revert unless necessary
4. **Test thoroughly** - Test facets in isolation and together
5. **Document your facets** - Add NatSpec comments
6. **Gas optimization** - Keep logic efficient
7. **Access control** - Use LibDiamond.contractOwner() for admin functions

