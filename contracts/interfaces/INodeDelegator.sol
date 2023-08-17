// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.12;

import "./IStrategy.sol";

interface INodeDelegator {
    // errros
    error TokenTransferFailed();
    error AssetNotSupported();

    // events
    event UpdatedLRTConfig(address indexed _lrtConfig);

    // methods

    function depositAssetIntoStrategy(address asset) external;

    function maxApproveToEigenStrategyManager(address asset) external;

    function getAssetBalances()
        external
        view
        returns (address[] memory, uint256[] memory);

    function getAssetBalance(address asset) external view returns (uint256);
}
