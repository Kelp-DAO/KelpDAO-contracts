// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.21;

import "./RSETH.sol";
import "./UtilLib.sol";

import "./interfaces/ILRTOracle.sol";
import "./interfaces/INodeDelegator.sol";
import "./interfaces/ILRTDepositPool.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

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

    function initialize(address _lrtConfig) external initializer {
        UtilLib.checkNonZeroAddress(_lrtConfig);
        __Pausable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        maxNodeDelegatorCount = 10;
        lrtConfig = ILRTConfig(_lrtConfig);
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

    function depositAsset(
        address _asset,
        uint256 _amount
    )
        external
        whenNotPaused
        nonReentrant
        onlySupportedAsset(_asset)
    {
        if (IERC20(_asset).balanceOf(msg.sender) < _amount || _amount == 0) {
            revert NotEnoughAssetToDeposit();
        }
        if (totalAssetDeposits[_asset] + _amount > lrtConfig.depositLimitByAsset(_asset)) {
            revert MaximumDepositLimitReached();
        }
        if (!IERC20(_asset).transferFrom(msg.sender, address(this), _amount)) {
            revert TokenTransferFailed();
        }
        totalAssetDeposits[_asset] += _amount;
        ILRTOracle lrtOracle = ILRTOracle(lrtConfig.getLRTOracle());
        uint256 amountToSend = (_amount * lrtOracle.assetER(_asset)) / lrtOracle.assetER(lrtConfig.getRSETHToken());
        RSETH(lrtConfig.getRSETHToken()).mint(msg.sender, amountToSend);
        emit DepositedAsset(_asset, _amount, amountToSend);
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
