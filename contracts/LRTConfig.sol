// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.21;

import { UtilLib } from "./UtilLib.sol";
import { ILRTConfig } from "./interfaces/ILRTConfig.sol";

import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

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
    bytes32 public constant override LRT_DEPOSIT_POOL = keccak256("LRT_DEPOSIT_POOL");
    bytes32 public constant override EIGEN_STRATEGY_MANAGER = keccak256("EIGEN_STRATEGY_MANAGER");

    //Roles
    bytes32 public constant override MANAGER = keccak256("MANAGER");

    mapping(bytes32 => address) public tokenMap;
    mapping(bytes32 => address) public contractMap;
    mapping(address => bool) public isSupportedAsset;
    mapping(address => uint256) public depositLimitByAsset;
    mapping(address => address) public override assetStrategy;

    address[] public supportedAssetList;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin, address stETH, address rETH, address cbETH) external initializer {
        UtilLib.checkNonZeroAddress(admin);
        __AccessControl_init();
        setToken(R_ETH_TOKEN, rETH);
        setToken(ST_ETH_TOKEN, stETH);
        setToken(CB_ETH_TOKEN, cbETH);
        _addNewSupportedAsset(rETH, 100_000 ether);
        _addNewSupportedAsset(stETH, 100_000 ether);
        _addNewSupportedAsset(cbETH, 100_000 ether);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function addNewSupportedAsset(address asset, uint256 depositLimit) external onlyRole(MANAGER) {
        _addNewSupportedAsset(asset, depositLimit);
    }

    function _addNewSupportedAsset(address asset, uint256 depositLimit) internal {
        UtilLib.checkNonZeroAddress(asset);
        if (isSupportedAsset[asset]) {
            revert AssetAlreadySupported();
        }
        isSupportedAsset[asset] = true;
        supportedAssetList.push(asset);
        depositLimitByAsset[asset] = depositLimit;
        emit AddedNewSupportedAsset(asset, depositLimit);
    }

    function updateAssetCapacity(
        address asset,
        uint256 depositLimit
    )
        external
        onlyRole(MANAGER)
        onlySupportedAsset(asset)
    {
        depositLimitByAsset[asset] = depositLimit;
        emit AssetDepositLimitUpdate(asset, depositLimit);
    }

    //Token setter
    function updateRSETHToken(address _rsETH) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setToken(RS_ETH_TOKEN, _rsETH);
    }

    function updateRETHToken(address _rETH) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setToken(R_ETH_TOKEN, _rETH);
    }

    function updateSTETHToken(address _stETH) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setToken(ST_ETH_TOKEN, _stETH);
    }

    function updateCBETHToken(address _cbETH) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setToken(CB_ETH_TOKEN, _cbETH);
    }

    //Contract setter
    function updateLRTOracle(address _lrtOracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setContract(LRT_ORACLE, _lrtOracle);
    }

    function updateLRTDepositPool(address _lrtDepositPool) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setContract(LRT_DEPOSIT_POOL, _lrtDepositPool);
    }

    function updateEigenStrategyManager(address _eigenStrategyManager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setContract(EIGEN_STRATEGY_MANAGER, _eigenStrategyManager);
    }

    function updateAssetStrategy(
        address asset,
        address strategy
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        onlySupportedAsset(asset)
    {
        UtilLib.checkNonZeroAddress(strategy);
        if (assetStrategy[asset] == strategy) {
            revert IndenticalValue();
        }
        assetStrategy[asset] = strategy;
    }

    //Token Getters
    function getRSETHToken() external view override returns (address) {
        return tokenMap[RS_ETH_TOKEN];
    }

    function getRETHToken() external view override returns (address) {
        return tokenMap[R_ETH_TOKEN];
    }

    function getSTETHToken() external view override returns (address) {
        return tokenMap[ST_ETH_TOKEN];
    }

    function getCBETHToken() external view override returns (address) {
        return tokenMap[CB_ETH_TOKEN];
    }

    //Contracts Getters
    function getLRTOracle() external view override returns (address) {
        return contractMap[LRT_ORACLE];
    }

    function getLRTDepositPool() external view override returns (address) {
        return contractMap[LRT_DEPOSIT_POOL];
    }

    function getEigenStrategyManager() external view override returns (address) {
        return contractMap[EIGEN_STRATEGY_MANAGER];
    }

    function getSupportedAssetList() external view override returns (address[] memory) {
        return supportedAssetList;
    }

    function setContract(bytes32 key, address val) internal {
        UtilLib.checkNonZeroAddress(val);
        if (contractMap[key] == val) {
            revert IndenticalValue();
        }
        contractMap[key] = val;
        emit SetContract(key, val);
    }

    function setToken(bytes32 key, address val) internal {
        UtilLib.checkNonZeroAddress(val);
        if (tokenMap[key] == val) {
            revert IndenticalValue();
        }
        tokenMap[key] = val;
        emit SetToken(key, val);
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
