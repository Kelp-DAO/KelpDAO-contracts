// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.21;

import { UtilLib } from "./utils/UtilLib.sol";
import { LRTConstants } from "./utils/LRTConstants.sol";

import { LRTConfigRoleChecker, ILRTConfig } from "./utils/LRTConfigRoleChecker.sol";
import { IRSETH } from "./interfaces/IRSETH.sol";
import { ILRTOracle } from "./interfaces/ILRTOracle.sol";
import { INodeDelegator } from "./interfaces/INodeDelegator.sol";
import { ILRTDepositPool } from "./interfaces/ILRTDepositPool.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/// @title LRTDepositPool - Deposit Pool Contract for LSTs
/// @notice Handles LST asset deposits
contract LRTDepositPool is ILRTDepositPool, LRTConfigRoleChecker, PausableUpgradeable, ReentrancyGuardUpgradeable {
    uint256 public maxNodeDelegatorCount;

    address[] public nodeDelegatorQueue;
    mapping(address asset => uint256 depositAmount) public totalAssetDeposits;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Initializes the contract
    /// @param lrtConfigAddr LRT config address
    function initialize(address lrtConfigAddr) external initializer {
        UtilLib.checkNonZeroAddress(lrtConfigAddr);
        __Pausable_init();
        __ReentrancyGuard_init();
        maxNodeDelegatorCount = 10;
        lrtConfig = ILRTConfig(lrtConfigAddr);
    }

    // view functions

    /// @notice gets the current limit of asset deposit
    /// @param _asset Asset address
    /// @return currentLimit Current limit of asset deposit
    function getAssetCurrentLimit(address _asset) external view override returns (uint256) {
        return lrtConfig.depositLimitByAsset(_asset) - totalAssetDeposits[_asset];
    }

    /// @dev get node delegator queue
    /// @return nodeDelegatorQueue Array of node delegator contract addresses
    function getNodeDelegatorQueue() external view override returns (address[] memory) {
        return nodeDelegatorQueue;
    }

    // write functions

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
        // checks
        if (depositAmount == 0) {
            revert InvalidAmount();
        }
        if (totalAssetDeposits[asset] + depositAmount > lrtConfig.depositLimitByAsset(asset)) {
            revert MaximumDepositLimitReached();
        }

        if (!IERC20(asset).transferFrom(msg.sender, address(this), depositAmount)) {
            revert TokenTransferFailed();
        }

        // effects
        totalAssetDeposits[asset] += depositAmount;

        // interactions
        uint256 rsethAmountMinted = _mintRsETH(asset, depositAmount);

        emit AssetDeposit(asset, depositAmount, rsethAmountMinted);
    }

    /// @dev private function to mint rseth. It calculates rseth amount to mint based on asset amount and asset exchange
    /// rates from oracle
    /// @param _asset Asset address
    /// @param _amount Asset amount to mint rseth
    /// @return rsethAmountToMint Amount of rseth minted
    function _mintRsETH(address _asset, uint256 _amount) private returns (uint256 rsethAmountToMint) {
        // setup oracle contract
        address lrtOracleAddress = lrtConfig.getContract(LRTConstants.LRT_ORACLE);
        ILRTOracle lrtOracle = ILRTOracle(lrtOracleAddress);

        // calculate rseth amount to mint based on asset amount and asset exchange rate
        address rsethToken = lrtConfig.rsETH();
        rsethAmountToMint = (_amount * lrtOracle.assetER(_asset)) / lrtOracle.assetER(address(rsethToken));

        // mint rseth for user
        IRSETH(rsethToken).mint(msg.sender, rsethAmountToMint);
    }

    /// @notice add new node delegator contract addresses
    /// @dev only callable by LRT manager
    /// @param _nodeDelegatorContract Array of NodeDelegator contract addresses
    function addNodeDelegatorContractToQueue(address[] calldata _nodeDelegatorContract) external onlyLRTAdmin {
        uint256 length = _nodeDelegatorContract.length;
        if (nodeDelegatorQueue.length + length > maxNodeDelegatorCount) {
            revert MaximumNodeDelegatorCountReached();
        }

        for (uint256 i; i < length;) {
            UtilLib.checkNonZeroAddress(_nodeDelegatorContract[i]);
            nodeDelegatorQueue.push(_nodeDelegatorContract[i]);
            emit AddedProspectiveNodeDelegatorInQueue(_nodeDelegatorContract[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice transfer asset to node delegator contract
    /// @dev only callable by LRT manager
    /// @param _ndcIndex Index of NodeDelegator contract address in nodeDelegatorQueue
    /// @param _asset Asset address
    /// @param _amount Asset amount to transfer
    function transferAssetToNodeDelegator(
        uint256 _ndcIndex,
        address _asset,
        uint256 _amount
    )
        external
        nonReentrant
        onlyLRTManager
        onlySupportedAsset(_asset)
    {
        address nodeDelegator = nodeDelegatorQueue[_ndcIndex];
        if (!IERC20(_asset).transfer(nodeDelegator, _amount)) {
            revert TokenTransferFailed();
        }
    }

    /// @notice update max node delegator count
    /// @dev only callable by LRT admin
    /// @param _maxNodeDelegatorCount Maximum count of node delegator
    function updateMaxNodeDelegatorCount(uint256 _maxNodeDelegatorCount) external onlyLRTAdmin {
        maxNodeDelegatorCount = _maxNodeDelegatorCount;
        emit MaxNodeDelegatorCountUpdated(maxNodeDelegatorCount);
    }

    /// @notice Updates the LRT config contract
    /// @dev only callable by LRT admin
    /// @param _lrtConfig the new LRT config contract
    function updateLRTConfig(address _lrtConfig) external onlyLRTAdmin {
        UtilLib.checkNonZeroAddress(_lrtConfig);
        lrtConfig = ILRTConfig(_lrtConfig);
        emit UpdatedLRTConfig(_lrtConfig);
    }

    /// @dev Triggers stopped state. Contract must not be paused.
    function pause() external onlyLRTManager {
        _pause();
    }

    /// @dev Returns to normal state. Contract must be paused
    function unpause() external onlyLRTAdmin {
        _unpause();
    }

    /// @dev Returns the total amount of an asset deposited into eigen layer
    /// @param _asset the asset to get the total amount of
    /// @return totalAssetWithEigenLayer the total amount of the asset
    function getAssetAmountWithEigenLayer(address _asset)
        external
        view
        override
        onlySupportedAsset(_asset)
        returns (uint256 totalAssetWithEigenLayer)
    {
        uint256 length = nodeDelegatorQueue.length;
        for (uint256 i; i < length;) {
            totalAssetWithEigenLayer += INodeDelegator(nodeDelegatorQueue[i]).getAssetBalance(_asset);
            unchecked {
                ++i;
            }
        }
    }
}
