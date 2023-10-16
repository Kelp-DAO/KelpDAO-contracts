// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.21;

interface ILRTDepositPool {
    //errors
    error TokenTransferFailed();
    error InvalidAmount();
    error NotEnoughAssetToTransfer();
    error MaximumDepositLimitReached();
    error MaximumNodeDelegatorCountReached();

    //events
    event UpdatedLRTConfig(address lrtConfig);
    event MaxNodeDelegatorCountUpdated(uint256 maxNodeDelegatorCount);
    event AddedProspectiveNodeDelegatorInQueue(address prospectiveNodeDelegatorContract);
    event AssetDeposit(address asset, uint256 depositAmount, uint256 rsethMintAmount);

    function depositAsset(address asset, uint256 depositAmount) external;

    function addNodeDelegatorContractToQueue(address[] calldata _nodeDelegatorContract) external;

    function transferAssetToNodeDelegator(uint256 _ndcIndex, address _asset, uint256 _amount) external;

    function updateMaxNodeDelegatorCount(uint256 _maxNodeDelegatorCount) external;

    function updateLRTConfig(address _lrtConfig) external;

    function getNodeDelegatorQueue() external view returns (address[] memory);

    function getAssetAmountWithEigenLayer(address _asset) external view returns (uint256);
}
