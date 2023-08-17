// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.12;

import "./UtilLib.sol";

import "./interfaces/INodeDelegator.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IEigenStrategyManager.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract NodeDelegator is INodeDelegator, PausableUpgradeable {
    ILRTConfig public lrtConfig;

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

    function depositAssetIntoStrategy(
        address asset
    ) external override onlySupportedAsset(asset) {
        lrtConfig.onlyManagerRole(msg.sender);
        address strategy = lrtConfig.assetStrategy(asset);
        UtilLib.checkNonZeroAddress(strategy);
        IERC20 token = IERC20(asset);
        IEigenStrategyManager(lrtConfig.getEigenStrategyManager())
            .depositIntoStrategy(
                IStrategy(strategy),
                token,
                token.balanceOf(address(this))
            );
    }

    function maxApproveToEigenStrategyManager(
        address asset
    ) external override onlySupportedAsset(asset) {
        lrtConfig.onlyManagerRole(msg.sender);
        address strategyManager = lrtConfig.getEigenStrategyManager();
        IERC20(asset).approve(strategyManager, type(uint256).max);
    }

    function transferBackToLRTDepositPool(
        address asset,
        uint256 amount
    ) external onlySupportedAsset(asset) {
        lrtConfig.onlyManagerRole(msg.sender);
        if (!IERC20(asset).transfer(lrtConfig.getLRTDepositPool(), amount)) {
            revert TokenTransferFailed();
        }
    }

    function getAssetBalances()
        external
        view
        override
        returns (address[] memory, uint256[] memory)
    {
        (IStrategy[] memory strategies, ) = IEigenStrategyManager(
            lrtConfig.getEigenStrategyManager()
        ).getDeposits(address(this));

        uint256 strategiesLength = strategies.length;
        address[] memory assets = new address[](strategiesLength);
        uint256[] memory assetBalances = new uint256[](strategiesLength);

        for (uint256 i = 0; i < strategiesLength; ) {
            assets[i] = address(IStrategy(strategies[i]).underlyingToken());
            assetBalances[i] = IStrategy(strategies[i]).userUnderlyingView(
                address(this)
            );
            unchecked {
                ++i;
            }
        }
        return (assets, assetBalances);
    }

    function getAssetBalance(
        address asset
    ) external view override returns (uint256) {
        address strategy = lrtConfig.assetStrategy(asset);
        return IStrategy(strategy).userUnderlyingView(strategy);
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

    modifier onlySupportedAsset(address _asset) {
        if (!lrtConfig.supportedAssetList(_asset)) {
            revert AssetNotSupported();
        }
        _;
    }
}
