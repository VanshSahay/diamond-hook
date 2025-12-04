// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {LibDiamond} from "../libraries/LibDiamond.sol";

contract DiamondInit {
    function init() external {
        // Set the contract owner
        LibDiamond.setContractOwner(msg.sender);
    }
}

