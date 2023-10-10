// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.21;

import { RSETH } from "./RSETH.sol";
import { UtilLib } from "./UtilLib.sol";

import { ILRTConfig } from "./interfaces/ILRTConfig.sol";
import { ILRTOracle } from "./interfaces/ILRTOracle.sol";
import { INodeDelegator } from "./interfaces/INodeDelegator.sol";
import { ILRTDepositPool } from "./interfaces/ILRTDepositPool.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/// @title Deposit Pool Contract for LSTs
/// @notice Handles LST asset deposits
contract LRTDepositPool is
    ILRTDepositPool,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    ILRTConfig public lrtConfig;
    uint16 public maxNodeDelegatorCount;

    address[] public nodeDelegatorQueue;
    mapping(address => uint256) public totalAssetDeposits;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address lrtConfigAddr) external initializer {
        UtilLib.checkNonZeroAddress(lrtConfigAddr);
        __Pausable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        maxNodeDelegatorCount = 10;
        lrtConfig = ILRTConfig(lrtConfigAddr);
    }

    /// @notice helps user stake LST to the protocol
    /// @param asset LST asset address to stake
    /// @param depositAmount LST asset amount to stake
    function depositAsset(
        address asset,
        uint256 depositAmount
    )
        external
        whenNotPaused
        nonReentrant
        onlySupportedAsset(asset)
    {
        if (depositAmount == 0) {
            revert InvalidAmount();
        }
        if (totalAssetDeposits[asset] + depositAmount > lrtConfig.depositLimitByAsset(asset)) {
            revert MaximumDepositLimitReached();
        }
        totalAssetDeposits[asset] += depositAmount;
        ILRTOracle lrtOracle = ILRTOracle(lrtConfig.getLRTOracle());
        uint256 rsethAmountToMint =
            (depositAmount * lrtOracle.assetER(asset)) / lrtOracle.assetER(lrtConfig.getRSETHToken());

        if (!IERC20(asset).transferFrom(msg.sender, address(this), depositAmount)) {
            revert TokenTransferFailed();
        }
        RSETH(lrtConfig.getRSETHToken()).mint(msg.sender, rsethAmountToMint);
        emit AssetDeposit(asset, depositAmount, rsethAmountToMint);
    }

    function addNodeDelegatorContract(address[] calldata _nodeDelegatorContract) external {
        lrtConfig.onlyAdminRole(msg.sender);
        for (uint16 i; i < _nodeDelegatorContract.length; i++) {
            if (nodeDelegatorQueue.length >= maxNodeDelegatorCount) {
                revert MaximumCountOfNodeDelegatorReached();
            }
            nodeDelegatorQueue.push(_nodeDelegatorContract[i]);
            emit AddedNodeDelegator(_nodeDelegatorContract[i]);
        }
    }

    function transferAssetToNodeDelegator(
        uint16 _ndcIndex,
        address _asset,
        uint256 _amount
    )
        external
        nonReentrant
        onlySupportedAsset(_asset)
    {
        lrtConfig.onlyManagerRole(msg.sender);
        UtilLib.checkNonZeroAddress(_asset);
        address nodeDelegator = nodeDelegatorQueue[_ndcIndex];
        UtilLib.checkNonZeroAddress(nodeDelegator);
        if (!IERC20(_asset).transfer(nodeDelegator, _amount)) {
            revert TokenTransferFailed();
        }
    }

    function updateMaxNodeDelegatorCount(uint16 _maxNodeDelegatorCount) external {
        lrtConfig.onlyAdminRole(msg.sender);
        maxNodeDelegatorCount = _maxNodeDelegatorCount;
        emit MaxNodeDelegatorCountUpdated(maxNodeDelegatorCount);
    }

    function updateLRTConfig(address _lrtConfig) external {
        lrtConfig.onlyAdminRole(msg.sender);
        UtilLib.checkNonZeroAddress(_lrtConfig);
        lrtConfig = ILRTConfig(_lrtConfig);
        emit UpdatedLRTConfig(_lrtConfig);
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

    function getTotalAssetsWithEigenLayer(address _asset)
        external
        view
        override
        onlySupportedAsset(_asset)
        returns (uint256)
    {
        uint256 totalAssetWithEigenLayer;
        for (uint16 i; i < nodeDelegatorQueue.length;) {
            totalAssetWithEigenLayer += INodeDelegator(nodeDelegatorQueue[i]).getAssetBalance(_asset);
            unchecked {
                ++i;
            }
        }
        return totalAssetWithEigenLayer;
    }

    function getNodeDelegatorQueue() external view override returns (address[] memory) {
        return nodeDelegatorQueue;
    }

    modifier onlySupportedAsset(address _asset) {
        if (!lrtConfig.isSupportedAsset(_asset)) {
            revert AssetNotSupported();
        }
        _;
    }
}
