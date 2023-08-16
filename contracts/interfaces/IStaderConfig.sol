// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.12;

interface IStaderConfig {
    // Errors
    error IndenticalValue();

    // Events
    event SetToken(bytes32 key, address newAddress);
    event SetContract(bytes32 key, address newAddress);

    //Contracts
    function R_ETH_TOKEN() external view returns (bytes32);

    function RS_ETH_TOKEN() external view returns (bytes32);

    function ST_ETH_TOKEN() external view returns (bytes32);

    function CB_ETH_TOKEN() external view returns (bytes32);

    function STADER_ORACLE() external view returns (bytes32);

    function LRT_DEPOSIT_POOL() external view returns (bytes32);

    //Roles
    function MANAGER() external view returns (bytes32);

    // Tokens
    function getRSETHToken() external view returns (address);

    function getRETHToken() external view returns (address);

    function getSTETHToken() external view returns (address);

    function getCBETHToken() external view returns (address);

    // Contracts
    function getStaderOracle() external view returns (address);

    function getLRTDepositPool() external view returns (address);

    //checks roles
    function onlyAdminRole(address account) external view returns (bool);

    function onlyManagerRole(address account) external view returns (bool);
}
