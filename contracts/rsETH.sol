// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.12;

import "./UtilLib.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @title rsETH token Contract
 * @author Stader Labs
 * @notice The ERC20 contract for the rsETH token
 */

contract rsETH is
    Initializable,
    ERC20Upgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    error CallerNotAdmin();
    error CallerNotManager();
    event UpdatedStaderConfig(address indexed _staderConfig);

    IStaderConfig public staderConfig;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _staderConfig) external initializer {
        UtilLib.checkNonZeroAddress(_staderConfig);

        __ERC20_init("rsETH", "rsETH");
        __Pausable_init();
        __AccessControl_init();
        staderConfig = IStaderConfig(_staderConfig);
    }

    /**
     * @notice Mints rsETH when called by an authorized caller
     * @param to the account to mint to
     * @param amount the amount of rsETH to mint
     */
    function mint(
        address to,
        uint256 amount
    ) external onlyRole(MINTER_ROLE) whenNotPaused {
        _mint(to, amount);
    }

    /**
     * @notice Burns rsETH when called by an authorized caller
     * @param account the account to burn from
     * @param amount the amount of rsETH to burn
     */
    function burnFrom(
        address account,
        uint256 amount
    ) external onlyRole(BURNER_ROLE) whenNotPaused {
        _burn(account, amount);
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

    function updateStaderConfig(address _staderConfig) external onlyAdmin {
        UtilLib.checkNonZeroAddress(_staderConfig);
        staderConfig = IStaderConfig(_staderConfig);
        emit UpdatedStaderConfig(_staderConfig);
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
