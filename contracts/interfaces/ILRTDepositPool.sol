// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.12;

interface ILRTDepositPool {
    //errors
    error CallerNotAdmin();
    error CallerNotManager();
    error AssetNotSupported();
    error TokenTransferFailed();
    error AssetAlreadySupported();
    error NotEnoughAssetToDeposit();
    error NotEnoughAssetToTransfer();
    error MaximumDepositLimitReached();
    error MaximumCountOfNodeDelegateReached();

    //events
    event AddedNewSupportedAsset(address asset, uint256 depositLimit);
    event UpdatedStaderConfig(address staderConfig);
    event AssetMaxDepositLimitUpdated(
        address asset,
        uint256 assetMaxDepositLimit
    );
    event MaxNodeDelegateCountUpdated(uint16 maxNodeDelegateCount);
    event AddedNodeDelegate(address nodeDelegatorContract);
    event DepositedAsset(
        address asset,
        uint256 amountOfAsset,
        uint256 amountToSend
    );

    function addNewSupportedAsset(
        address _asset,
        uint256 _depositLimit
    ) external;

    function addNodeDelegatorContract(
        address[] calldata _nodeDelegatorContract
    ) external;

    function depositAsset(address _asset, uint256 _amount) external;

    function transferAssetToNodeDelegator(
        uint16 _ndcIndex,
        address _asset,
        uint256 _amount
    ) external;

    function updateMaxNodeDelegateCount(uint16 _maxNodeDelegateCount) external;

    function updateAssetMaxDepositLimit(
        address _asset,
        uint256 _assetMaxDepositLimit
    ) external;

    function updateStaderConfig(address _staderConfig) external;

    function getExchangeRate(address _asset) external;

    function getTotalAssetsWithEigenLayer(
        address _asset
    ) external view returns (uint256);
}
