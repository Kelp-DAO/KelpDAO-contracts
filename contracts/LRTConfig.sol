// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.12;

import "./UtilLib.sol";
import "./interfaces/ILRTConfig.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract LRTConfig is ILRTConfig, AccessControlUpgradeable {
    //tokens
    //rETH token
    bytes32 public constant override R_ETH_TOKEN = keccak256("R_ETH_TOKEN");
    //rsETH token
    bytes32 public constant override RS_ETH_TOKEN = keccak256("RS_ETH_TOKEN");
    //stETH token
    bytes32 public constant override ST_ETH_TOKEN = keccak256("ST_ETH_TOKEN");
    //cbETH token
    bytes32 public constant override CB_ETH_TOKEN = keccak256("CB_ETH_TOKEN");

    //contracts
    bytes32 public constant override LRT_ORACLE = keccak256("LRT_ORACLE");
    bytes32 public constant override LRT_DEPOSIT_POOL =
        keccak256("LRT_DEPOSIT_POOL");
    bytes32 public constant override EIGEN_STRATEGY_MANAGER =
        keccak256("EIGEN_STRATEGY_MANAGER");

    //Roles
    bytes32 public constant override MANAGER = keccak256("MANAGER");

    mapping(bytes32 => address) public tokensMap;
    mapping(bytes32 => address) public contractsMap;
    mapping(address => bool) public isSupportedAsset;
    mapping(address => uint256) public depositLimitByAsset;
    mapping(address => address) public override assetStrategy;

    address[] public supportedAssetList;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _admin,
        address _stETH,
        address _rETH,
        address _cbETH
    ) external initializer {
        UtilLib.checkNonZeroAddress(_admin);
        __AccessControl_init();
        setToken(R_ETH_TOKEN, _rETH);
        setToken(ST_ETH_TOKEN, _stETH);
        setToken(CB_ETH_TOKEN, _cbETH);
        _addNewSupportedAsset(_rETH, 100_000 ether);
        _addNewSupportedAsset(_stETH, 100_000 ether);
        _addNewSupportedAsset(_cbETH, 100_000 ether);

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function addNewSupportedAsset(
        address _asset,
        uint256 _depositLimit
    ) external onlyRole(MANAGER) {
        _addNewSupportedAsset(_asset, _depositLimit);
    }

    function updateAssetCapacity(
        address _asset,
        uint256 _assetMaxDepositLimit
    ) external onlyRole(MANAGER) onlySupportedAsset(_asset) {
        depositLimitByAsset[_asset] = _assetMaxDepositLimit;
        emit AssetMaxDepositLimitUpdated(_asset, _assetMaxDepositLimit);
    }

    //Token setter
    function updateRSETHToken(
        address _rsETH
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setToken(RS_ETH_TOKEN, _rsETH);
    }

    function updateRETHToken(
        address _rETH
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setToken(R_ETH_TOKEN, _rETH);
    }

    function updateSTETHToken(
        address _stETH
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setToken(ST_ETH_TOKEN, _stETH);
    }

    function updateCBETHToken(
        address _cbETH
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setToken(CB_ETH_TOKEN, _cbETH);
    }

    //Contract setter
    function updateLRTOracle(
        address _lrtOracle
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setContract(LRT_ORACLE, _lrtOracle);
    }

    function updateLRTDepositPool(
        address _lrtDepositPool
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setContract(LRT_DEPOSIT_POOL, _lrtDepositPool);
    }

    function updateEigenStrategyManager(
        address _eigenStrategyManager
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setContract(EIGEN_STRATEGY_MANAGER, _eigenStrategyManager);
    }

    function updateAssetStrategy(
        address asset,
        address strategy
    ) external onlyRole(DEFAULT_ADMIN_ROLE) onlySupportedAsset(asset) {
        UtilLib.checkNonZeroAddress(strategy);
        if (assetStrategy[asset] == strategy) {
            revert IndenticalValue();
        }
        assetStrategy[asset] = strategy;
    }

    //Token Getters
    function getRSETHToken() external view override returns (address) {
        return tokensMap[RS_ETH_TOKEN];
    }

    function getRETHToken() external view override returns (address) {
        return tokensMap[R_ETH_TOKEN];
    }

    function getSTETHToken() external view override returns (address) {
        return tokensMap[ST_ETH_TOKEN];
    }

    function getCBETHToken() external view override returns (address) {
        return tokensMap[CB_ETH_TOKEN];
    }

    //Contracts Getters
    function getLRTOracle() external view override returns (address) {
        return contractsMap[LRT_ORACLE];
    }

    function getLRTDepositPool() external view override returns (address) {
        return contractsMap[LRT_DEPOSIT_POOL];
    }

    function getEigenStrategyManager()
        external
        view
        override
        returns (address)
    {
        return contractsMap[EIGEN_STRATEGY_MANAGER];
    }

    function getSupportedAssetList()
        external
        view
        override
        returns (address[] memory)
    {
        return supportedAssetList;
    }

    function setContract(bytes32 key, address val) internal {
        UtilLib.checkNonZeroAddress(val);
        if (contractsMap[key] == val) {
            revert IndenticalValue();
        }
        contractsMap[key] = val;
        emit SetContract(key, val);
    }

    function setToken(bytes32 key, address val) internal {
        UtilLib.checkNonZeroAddress(val);
        if (tokensMap[key] == val) {
            revert IndenticalValue();
        }
        tokensMap[key] = val;
        emit SetToken(key, val);
    }

    function _addNewSupportedAsset(
        address _asset,
        uint256 _depositLimit
    ) internal {
        UtilLib.checkNonZeroAddress(_asset);
        if (isSupportedAsset[_asset]) {
            revert AssetAlreadySupported();
        }
        isSupportedAsset[_asset] = true;
        supportedAssetList.push(_asset);
        depositLimitByAsset[_asset] = _depositLimit;
        emit AddedNewSupportedAsset(_asset, _depositLimit);
    }

    function onlyAdminRole(address account) external view override {
        if (!hasRole(DEFAULT_ADMIN_ROLE, account)) {
            revert CallerNotAdmin();
        }
    }

    function onlyManagerRole(address account) public view override {
        if (!hasRole(MANAGER, account)) {
            revert CallerNotManager();
        }
    }

    modifier onlySupportedAsset(address _asset) {
        if (!isSupportedAsset[_asset]) {
            revert AssetNotSupported();
        }
        _;
    }
}
