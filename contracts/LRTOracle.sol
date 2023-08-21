// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.12;

import "./UtilLib.sol";

import "./interfaces/ILRTConfig.sol";
import "./interfaces/ILRTOracle.sol";
import "./interfaces/ILRTDepositPool.sol";
import "./interfaces/INodeDelegator.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract LRTOracle is ILRTOracle, PausableUpgradeable {
    ILRTConfig public lrtConfig;

    mapping(address => uint256) public override assetER;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _lrtConfig) external initializer {
        UtilLib.checkNonZeroAddress(_lrtConfig);
        __Pausable_init();

        lrtConfig = ILRTConfig(_lrtConfig);
        emit UpdatedLRTConfig(_lrtConfig);
    }

    function updateAssetER(address asset, uint256 er) public {
        lrtConfig.onlyManagerRole(msg.sender);
        assetER[asset] = er;
    }

    /// @dev Uses the most recently updated asset exchange rates to compute the total ETH in reserve.
    function updateRSETHRate() external {
        address rsETHToken = lrtConfig.getRSETHToken();
        uint256 rsEthSupply = IERC20Upgradeable(rsETHToken).totalSupply();

        if (rsEthSupply == 0) {
            assetER[rsETHToken] = 1e18;
            return;
        }

        uint256 totalETHInPool;
        address lrtDepositPool = lrtConfig.getLRTDepositPool();

        address[] memory supportedAssets = lrtConfig.getSupportedAssetList();
        for (uint16 asset_idx; asset_idx < supportedAssets.length; ) {
            address asset = supportedAssets[asset_idx];
            totalETHInPool +=
                IERC20(asset).balanceOf(lrtDepositPool) *
                assetER[asset];

            unchecked {
                ++asset_idx;
            }
        }

        address[] memory ndcs = ILRTDepositPool(lrtDepositPool)
            .getNodeDelegatorQueue();
        for (uint16 ndc_idx; ndc_idx < ndcs.length; ) {
            address ndc = ndcs[ndc_idx];

            // calculate ndc eth amount
            for (uint16 asset_idx; asset_idx < supportedAssets.length; ) {
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
            for (uint16 asset_idx = 0; asset_idx < assets.length; ) {
                totalETHInPool +=
                    balances[asset_idx] *
                    assetER[assets[asset_idx]];
                unchecked {
                    ++asset_idx;
                }
            }

            unchecked {
                ++ndc_idx;
            }
        }

        assetER[rsETHToken] = totalETHInPool / rsEthSupply;
    }

    /**
     * @dev Triggers stopped state.
     * Contract must not be paused.
     */
    function pause() external {
        lrtConfig.onlyManagerRole(msg.sender);
        _pause();
    }

    /**
     * @dev Returns to normal state.
     * Contract must be paused
     */
    function unpause() external {
        lrtConfig.onlyAdminRole(msg.sender);
        _unpause();
    }
}
