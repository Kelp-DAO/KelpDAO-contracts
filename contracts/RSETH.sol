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

contract RSETH is
    Initializable,
    ERC20Upgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    event UpdatedLRTConfig(address indexed _lrtConfig);

    ILRTConfig public lrtConfig;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _lrtConfig) external initializer {
        UtilLib.checkNonZeroAddress(_lrtConfig);

        __ERC20_init("rsETH", "rsETH");
        __Pausable_init();
        __AccessControl_init();
        lrtConfig = ILRTConfig(_lrtConfig);
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

    function updateLRTConfig(address _lrtConfig) external {
        lrtConfig.onlyAdminRole(msg.sender);
        UtilLib.checkNonZeroAddress(_lrtConfig);
        lrtConfig = ILRTConfig(_lrtConfig);
        emit UpdatedLRTConfig(_lrtConfig);
    }
}