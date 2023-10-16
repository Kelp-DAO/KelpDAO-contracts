// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.21;

import { UtilLib } from "./utils/UtilLib.sol";
import { LRTConstants } from "./utils/LRTConstants.sol";
import { LRTConfigRoleChecker, ILRTConfig } from "./utils/LRTConfigRoleChecker.sol";

import { IRSETH } from "./interfaces/IRSETH.sol";
import { ILRTOracle } from "./interfaces/ILRTOracle.sol";
import { ILRTDepositPool } from "./interfaces/ILRTDepositPool.sol";
import { INodeDelegator } from "./interfaces/INodeDelegator.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

/// @title LRTOracle Contract
/// @notice oracle contract that calculates the exchange rate of assets
contract LRTOracle is ILRTOracle, LRTConfigRoleChecker, PausableUpgradeable {
    mapping(address asset => uint256 er) public override assetER;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Initializes the contract
    /// @param _lrtConfig LRT config address
    function initialize(address _lrtConfig) external initializer {
        UtilLib.checkNonZeroAddress(_lrtConfig);
        __Pausable_init();

        lrtConfig = ILRTConfig(_lrtConfig);
        emit UpdatedLRTConfig(_lrtConfig);
    }

    /// @notice Updates the exchange rate of an asset
    /// @dev only callable by LRT manager
    /// @param asset the asset to update
    function updateAssetER(address asset, uint256 er) public onlyLRTManager {
        assetER[asset] = er;
    }

    /// @dev Uses the most recently updated asset exchange rates to compute the total ETH in reserve.
    function updateRSETHRate() external {
        address rsETHTokenAddress = lrtConfig.rsETH();
        uint256 rsEthSupply = IRSETH(rsETHTokenAddress).totalSupply();

        if (rsEthSupply == 0) {
            assetER[rsETHTokenAddress] = 1e18;
            return;
        }

        uint256 totalETHInPool; // totalETHInPool = eth in lrtDepositPool + eth in ndcs + eth already staked in eigen
            // layer
        address lrtDepositPool = lrtConfig.getContract(LRTConstants.LRT_DEPOSIT_POOL);

        address[] memory supportedAssets = lrtConfig.getSupportedAssetList();
        uint256 supportedAssetCount = supportedAssets.length;

        // calculate lrtDepositPool eth eqivalent balance
        for (uint16 asset_idx; asset_idx < supportedAssetCount;) {
            address asset = supportedAssets[asset_idx];
            totalETHInPool += IERC20(asset).balanceOf(lrtDepositPool) * assetER[asset];

            unchecked {
                ++asset_idx;
            }
        }
        // calculate ndcs eth eqivalent balance
        address[] memory ndcs = ILRTDepositPool(lrtDepositPool).getNodeDelegatorQueue();
        uint256 ndcCount = ndcs.length;
        for (uint16 ndc_idx; ndc_idx < ndcCount;) {
            address ndc = ndcs[ndc_idx];

            // calculate ndc eth amount
            for (uint16 asset_idx; asset_idx < supportedAssetCount;) {
                address asset = supportedAssets[asset_idx];
                totalETHInPool += IERC20(asset).balanceOf(ndc) * assetER[asset];
                unchecked {
                    ++asset_idx;
                }
            }

            // calculate eth amount in eigen layer through this ndc
            (
                address[] memory assets,
                uint256[] memory balances // wei
            ) = INodeDelegator(ndc).getAssetBalances();
            uint256 ndcAssetCount = assets.length;
            for (uint16 asset_idx = 0; asset_idx < ndcAssetCount;) {
                totalETHInPool += balances[asset_idx] * assetER[assets[asset_idx]];
                unchecked {
                    ++asset_idx;
                }
            }

            unchecked {
                ++ndc_idx;
            }
        }

        assetER[rsETHTokenAddress] = totalETHInPool / rsEthSupply;
    }

    /// @dev Triggers stopped state. Contract must not be paused.
    function pause() external onlyLRTManager {
        _pause();
    }

    /// @dev Returns to normal state. Contract must be paused
    function unpause() external onlyLRTAdmin {
        _unpause();
    }
}
