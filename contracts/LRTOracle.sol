// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.12;

import "./UtilLib.sol";

import "./interfaces/ILRTOracle.sol";
import "./interfaces/ILRTDepositPool.sol";
import "./interfaces/INodeDelegator.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract LRTOracle is ILRTOracle, PausableUpgradeable {
    ILRTConfig public lrtConfig;

    mapping(address => uint256) public override assetER;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _lrtConfig) external initializer {
        UtilLib.checkNonZeroAddress(_lrtConfig);
        __Pausable_init();

        lrtConfig = ILRTConfig(_lrtConfig);
        emit UpdatedLRTConfig(_lrtConfig);
    }

    function updateAssetER(address asset, uint256 er) public {
        lrtConfig.onlyManagerRole(msg.sender);
        assetER[asset] = er;
    }

    function updateRSETHRate() external {
        lrtConfig.onlyManagerRole(msg.sender);
        address rsETHToken = lrtConfig.getRSETHToken();
        uint256 rsEthSupply = IERC20Upgradeable(rsETHToken).totalSupply();

        if (rsEthSupply == 0) {
            assetER[rsETHToken] = 1e18;
            return;
        }

        uint256 ndcLength = ILRTDepositPool(lrtConfig.getLRTDepositPool())
            .getNDCsLength();

        uint256 totalETHInPool;
        for (uint256 i = 0; i < ndcLength; i++) {
            address ndc = ILRTDepositPool(lrtConfig.getLRTDepositPool())
                .nodeDelegatorQueue(i);
            (
                address[] memory assets,
                uint256[] memory balances // wei
            ) = INodeDelegator(ndc).getAssetBalances();
            for (uint256 j = 0; j < assets.length; j++) {
                totalETHInPool += balances[j] * assetER[assets[j]];
            }
        }
        assetER[rsETHToken] = (totalETHInPool) / rsEthSupply;
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
}
