// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.21;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { ILRTConfig } from "../interfaces/ILRTConfig.sol";
import { LRTConstants } from "./LRTConstants.sol";

/// @title LRTConfigRoleChecker - LRT Config Role Checker Contract
/// @notice Handles LRT config role checks
abstract contract LRTConfigRoleChecker {
    ILRTConfig public lrtConfig;

    // modifiers
    modifier onlyLRTManager() {
        if (!IAccessControl(address(lrtConfig)).hasRole(LRTConstants.MANAGER, msg.sender)) {
            revert ILRTConfig.CallerNotLRTConfigManager();
        }
        _;
    }

    modifier onlyLRTAdmin() {
        bytes32 DEFAULT_ADMIN_ROLE = 0x00;
        if (!IAccessControl(address(lrtConfig)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert ILRTConfig.CallerNotLRTConfigAdmin();
        }
        _;
    }

    modifier onlySupportedAsset(address _asset) {
        if (!lrtConfig.isSupportedAsset(_asset)) {
            revert ILRTConfig.AssetNotSupported();
        }
        _;
    }
}
