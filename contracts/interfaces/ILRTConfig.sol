// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.21;

interface ILRTConfig {
    // Errors
    error IndenticalValue();
    error AssetAlreadySupported();
    error AssetNotSupported();
    error CallerNotAdmin();
    error CallerNotManager();

    // Events
    event SetToken(bytes32 key, address newAddress);
    event SetContract(bytes32 key, address newAddress);
    event AddedNewSupportedAsset(address asset, uint256 depositLimit);
    event AssetMaxDepositLimitUpdated(address asset, uint256 assetMaxDepositLimit);

    //Contracts
    function R_ETH_TOKEN() external view returns (bytes32);

    function RS_ETH_TOKEN() external view returns (bytes32);

    function ST_ETH_TOKEN() external view returns (bytes32);

    function CB_ETH_TOKEN() external view returns (bytes32);

    function LRT_ORACLE() external view returns (bytes32);

    function LRT_DEPOSIT_POOL() external view returns (bytes32);

    function EIGEN_STRATEGY_MANAGER() external view returns (bytes32);

    //Roles
    function MANAGER() external view returns (bytes32);

    // Tokens
    function getRSETHToken() external view returns (address);

    function getRETHToken() external view returns (address);

    function getSTETHToken() external view returns (address);

    function getCBETHToken() external view returns (address);

    // Contracts
    function getLRTOracle() external view returns (address);

    function getLRTDepositPool() external view returns (address);

    function getEigenStrategyManager() external view returns (address);

    //checks roles
    function onlyAdminRole(address account) external view;

    function onlyManagerRole(address account) external view;

    // methods

    function assetStrategy(address asset) external view returns (address);

    function isSupportedAsset(address asset) external view returns (bool);

    function getSupportedAssetList() external view returns (address[] memory);

    function depositLimitByAsset(address asset) external view returns (uint256);
}
