// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.12;

import "./UtilLib.sol";

import "./interfaces/IStaderConfig.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract StaderConfig is IStaderConfig, AccessControlUpgradeable {
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
    bytes32 public constant override STADER_ORACLE = keccak256("STADER_ORACLE");
    bytes32 public constant override LRT_DEPOSIT_POOL =
        keccak256("LRT_DEPOSIT_POOL");

    //Roles
    bytes32 public constant override MANAGER = keccak256("MANAGER");

    mapping(bytes32 => address) private tokensMap;
    mapping(bytes32 => address) private contractsMap;

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
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
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
    function updateStaderOracle(
        address _staderOracle
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setContract(STADER_ORACLE, _staderOracle);
    }

    function updateLRTDepositPool(
        address _lrtDepositPool
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setContract(LRT_DEPOSIT_POOL, _lrtDepositPool);
    }

    //Token Getters
    function getRSETHToken() external view returns (address) {
        return tokensMap[RS_ETH_TOKEN];
    }

    function getRETHToken() external view returns (address) {
        return tokensMap[R_ETH_TOKEN];
    }

    function getSTETHToken() external view returns (address) {
        return tokensMap[ST_ETH_TOKEN];
    }

    function getCBETHToken() external view returns (address) {
        return tokensMap[CB_ETH_TOKEN];
    }

    //Contracts Getters
    function getStaderOracle() external view override returns (address) {
        return contractsMap[STADER_ORACLE];
    }

    function getLRTDepositPool() external view override returns (address) {
        return contractsMap[LRT_DEPOSIT_POOL];
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

    function onlyAdminRole(
        address account
    ) external view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function onlyManagerRole(
        address account
    ) external view override returns (bool) {
        return hasRole(MANAGER, account);
    }
}
