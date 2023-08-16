// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.12;

import "./rsETH.sol";
import "./UtilLib.sol";
import "./interfaces/ILRTDepositPool.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract LRTDepositPool is
    ILRTDepositPool,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    IStaderConfig public staderConfig;
    uint16 public maxNodeDelegateCount;

    address[] public nodeDelegatorQueue;
    mapping(address => bool) public supportedAssetList;
    mapping(address => uint256) public totalAssetDeposits;
    mapping(address => uint256) public depositLimitByAsset;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _staderConfig) external initializer {
        UtilLib.checkNonZeroAddress(_staderConfig);
        __Pausable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        maxNodeDelegateCount = 10;
        staderConfig = IStaderConfig(_staderConfig);
        supportedAssetList[staderConfig.getCBETHToken()] = true;
        supportedAssetList[staderConfig.getRETHToken()] = true;
        supportedAssetList[staderConfig.getSTETHToken()] = true;
        depositLimitByAsset[staderConfig.getCBETHToken()] = 100_000;
        depositLimitByAsset[staderConfig.getRETHToken()] = 100_000;
        depositLimitByAsset[staderConfig.getSTETHToken()] = 100_000;
    }

    function addNewSupportedAsset(
        address _asset,
        uint256 _depositLimit
    ) external onlyManager {
        UtilLib.checkNonZeroAddress(_asset);
        if (supportedAssetList[_asset]) {
            revert AssetAlreadySupported();
        }
        supportedAssetList[_asset] = true;
        depositLimitByAsset[_asset] = _depositLimit;
        emit AddedNewSupportedAsset(_asset, _depositLimit);
    }

    function addNodeDelegatorContract(
        address[] calldata _nodeDelegatorContract
    ) external onlyAdmin {
        for (uint16 i; i < _nodeDelegatorContract.length; i++) {
            if (nodeDelegatorQueue.length >= maxNodeDelegateCount) {
                revert MaximumCountOfNodeDelegateReached();
            }
            nodeDelegatorQueue.push(_nodeDelegatorContract[i]);
            emit AddedNodeDelegate(_nodeDelegatorContract[i]);
        }
    }

    function depositAsset(
        address _asset,
        uint256 _amount
    ) external whenNotPaused nonReentrant onlySupportedAsset(_asset) {
        if (IERC20(_asset).balanceOf(msg.sender) < _amount || _amount == 0) {
            revert NotEnoughAssetToDeposit();
        }
        if (
            totalAssetDeposits[_asset] + _amount > depositLimitByAsset[_asset]
        ) {
            revert MaximumDepositLimitReached();
        }
        if (!IERC20(_asset).transferFrom(msg.sender, address(this), _amount)) {
            revert TokenTransferFailed();
        }
        totalAssetDeposits[_asset] += _amount;
        //TODO sanjay fetch from staderOracle
        uint256 amountToSend = (
            _amount /* *getAssetPrice())/getrsETHTokenPrice()*/
        );
        rsETH(staderConfig.getRSETHToken()).mint(msg.sender, amountToSend);
        emit DepositedAsset(_asset, _amount, amountToSend);
    }

    function transferAssetToNodeDelegator(
        uint16 _ndcIndex,
        address _asset,
        uint256 _amount
    ) external nonReentrant onlySupportedAsset(_asset) onlyManager {
        UtilLib.checkNonZeroAddress(_asset);
        address nodeDelegator = nodeDelegatorQueue[_ndcIndex];
        UtilLib.checkNonZeroAddress(nodeDelegator);
        if (!IERC20(_asset).transfer(nodeDelegator, _amount)) {
            revert TokenTransferFailed();
        }
    }

    function updateMaxNodeDelegateCount(
        uint16 _maxNodeDelegateCount
    ) external onlyAdmin {
        maxNodeDelegateCount = _maxNodeDelegateCount;
        emit MaxNodeDelegateCountUpdated(maxNodeDelegateCount);
    }

    function updateAssetMaxDepositLimit(
        address _asset,
        uint256 _assetMaxDepositLimit
    ) external onlyManager onlySupportedAsset(_asset) {
        depositLimitByAsset[_asset] = _assetMaxDepositLimit;
        emit AssetMaxDepositLimitUpdated(_asset, _assetMaxDepositLimit);
    }

    function updateStaderConfig(address _staderConfig) external onlyAdmin {
        UtilLib.checkNonZeroAddress(_staderConfig);
        staderConfig = IStaderConfig(_staderConfig);
        emit UpdatedStaderConfig(_staderConfig);
    }

    /**
     * @dev Triggers stopped state.
     * Contract must not be paused.
     */
    function pause() external onlyManager {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     * Contract must be paused
     */
    function unpause() external onlyAdmin {
        _unpause();
    }

    function getExchangeRate(address _asset) external {
        //TODO sanjay fetch from staderOracle
        //return getAssetPrice(_asset)/getrsETHTokenPrice()
    }

    function getTotalAssetsWithEigenLayer(
        address _asset
    ) external view onlySupportedAsset(_asset) returns (uint256) {
        uint256 totalAssetWithEigenLayer;
        for (uint16 i; i <= nodeDelegatorQueue.length; ) {
            //TODO sanjay fetch from Node Delegate contract
            //totalAssetWithEigenLayer += INodeDelegate(nodeDelegatorQueue[i]).getBalanceOfAssetInEigenLayer(_asset)
            unchecked {
                ++i;
            }
        }
        return totalAssetWithEigenLayer;
    }

    modifier onlySupportedAsset(address _asset) {
        if (!supportedAssetList[_asset]) {
            revert AssetNotSupported();
        }
        _;
    }

    //checks for Admin role in staderConfig
    modifier onlyAdmin() {
        if (!staderConfig.onlyAdminRole(msg.sender)) {
            revert CallerNotAdmin();
        }
        _;
    }

    //checks for Manager role in staderConfig
    modifier onlyManager() {
        if (!staderConfig.onlyManagerRole(msg.sender)) {
            revert CallerNotManager();
        }
        _;
    }
}
