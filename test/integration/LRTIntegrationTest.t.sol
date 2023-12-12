// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "forge-std/Test.sol";
import { LRTDepositPool, ILRTDepositPool, LRTConstants } from "contracts/LRTDepositPool.sol";
import { LRTConfig, ILRTConfig } from "contracts/LRTConfig.sol";
import { RSETH } from "contracts/RSETH.sol";
import { LRTOracle } from "contracts/LRTOracle.sol";
import { NodeDelegator } from "contracts/NodeDelegator.sol";
import { UtilLib } from "contracts/utils/UtilLib.sol";
import { getLSTs } from "script/foundry-scripts/DeployLRT.s.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LRTIntegrationTest is Test {
    uint256 public goerliFork;

    LRTDepositPool public lrtDepositPool;
    LRTConfig public lrtConfig;
    RSETH public rseth;
    LRTOracle public lrtOracle;
    NodeDelegator public nodeDelegator1;

    address public admin = 0x64c6fBb54546d7014b5f89f0db4b40D58c20b1A4;
    address public manager = 0x64c6fBb54546d7014b5f89f0db4b40D58c20b1A4;

    address public stETHAddress;
    address public ethXAddress;

    address public stWhale = 0xD5d883B90030311530620E0ABEe93189c8aAe032;
    address public ethXWhale = 0xF6349eEe20aEcD62C9891159fB714a1b5adE93Cd;

    address public chainlinkOracle = 0x33124283F0c9eef83A5bcd4bb22C23f05ABc7D1A;
    address public ethxPriceOracle = 0x4978F66c51ADd2de0d49ce8Ec0e525E4f6B1Bef7;

    address public GOERLI_EIGEN_STRATEGY_MANAGER = 0x779d1b5315df083e3F9E94cB495983500bA8E907;
    address public GOERLI_EIGEN_STETH_STRATEGY = 0xB613E78E2068d7489bb66419fB1cfa11275d14da;

    uint256 public minAmountOfRSETHToReceive;
    string public referralId = "0";

    function setUp() public virtual {
        string memory goerliRPC = vm.envString("PROVIDER_URL_TESTNET");
        goerliFork = vm.createSelectFork(goerliRPC);

        lrtDepositPool = LRTDepositPool(0x8Ece5A05C62E548944C18504AFE424d0791c1684);
        lrtConfig = LRTConfig(0x3E8b8FE30260d202b92891ab38aE8493c8a0a412);
        rseth = RSETH(0xdc862C46F67a8A7B6412D51D10E1F5e19f1bCb62);
        lrtOracle = LRTOracle(0x63F1Cff763Cf282a6CEB6Ba12dE781b79934770f);
        nodeDelegator1 = NodeDelegator(0x991837c651902661fa88B80791d58dF56FD0Dd92);

        (stETHAddress, ethXAddress) = getLSTs();
    }
}

contract LRTDepositPoolIntegrationTest is LRTIntegrationTest {
    function test_LRTDepositPoolSetup() public {
        assertEq(address(lrtConfig), address(lrtDepositPool.lrtConfig()));
        assertEq(address(nodeDelegator1), address(lrtDepositPool.nodeDelegatorQueue(0)));
    }

    function test_LRTDepositPoolIsAlreadyInitialized() public {
        // attempt to initialize LRTDepositPool again reverts
        vm.expectRevert("Initializable: contract is already initialized");
        lrtDepositPool.initialize(address(lrtConfig));
    }

    function test_RevertWhenDepositAmountIsZeroForDepositAsset() external {
        vm.expectRevert(ILRTDepositPool.InvalidAmountToDeposit.selector);

        lrtDepositPool.depositAsset(ethXAddress, 0, minAmountOfRSETHToReceive, referralId);
    }

    function test_RevertWhenAssetIsNotSupportedForDepositAsset() external {
        address randomAsset = makeAddr("randomAsset");

        vm.expectRevert(ILRTConfig.AssetNotSupported.selector);
        lrtDepositPool.depositAsset(randomAsset, 1 ether, minAmountOfRSETHToReceive, referralId);
    }

    function test_DepositAssetSTETHWorksWhenUsingTheCorrectConditions() external {
        uint256 amountToDeposit = 2 ether;

        // stWhale balance of rsETH before deposit
        uint256 stWhaleBalanceBefore = rseth.balanceOf(stWhale);
        // total asset deposits before deposit for stETH
        uint256 totalAssetDepositsBefore = lrtDepositPool.getTotalAssetDeposits(stETHAddress);
        // balance of lrtDepositPool before deposit
        uint256 lrtDepositPoolBalanceBefore = ERC20(stETHAddress).balanceOf(address(lrtDepositPool));

        uint256 whaleStETHBalBefore = ERC20(stETHAddress).balanceOf(address(stWhale));
        vm.startPrank(stWhale);
        ERC20(stETHAddress).approve(address(lrtDepositPool), amountToDeposit);
        lrtDepositPool.depositAsset(stETHAddress, amountToDeposit, minAmountOfRSETHToReceive, referralId);
        vm.stopPrank();
        uint256 whaleStETHBalAfter = ERC20(stETHAddress).balanceOf(address(stWhale));

        console.log("whale stETH amount transfer:", whaleStETHBalBefore - whaleStETHBalAfter);

        // stWhale balance of rsETH after deposit
        uint256 stWhaleBalanceAfter = rseth.balanceOf(address(stWhale));

        assertApproxEqAbs(
            lrtDepositPool.getTotalAssetDeposits(stETHAddress),
            totalAssetDepositsBefore + amountToDeposit,
            2,
            "Total asset deposits check is incorrect"
        );
        assertApproxEqAbs(
            ERC20(stETHAddress).balanceOf(address(lrtDepositPool)),
            lrtDepositPoolBalanceBefore + amountToDeposit,
            2,
            "lrtDepositPool balance is not set"
        );
        assertGt(stWhaleBalanceAfter, stWhaleBalanceBefore, "Alice balance is not set");
    }

    function test_DepositAssetETHXWorksWhenUsingTheCorrectConditions() external {
        uint256 amountToDeposit = 2 ether;

        // ethXWhale balance of rsETH before deposit
        uint256 ethXWhaleBalanceBefore = rseth.balanceOf(ethXWhale);
        // total asset deposits before deposit for ethXETH
        uint256 totalAssetDepositsBefore = lrtDepositPool.getTotalAssetDeposits(ethXAddress);
        // balance of lrtDepositPool before deposit
        uint256 lrtDepositPoolBalanceBefore = ERC20(ethXAddress).balanceOf(address(lrtDepositPool));

        uint256 whaleethXBalBefore = ERC20(ethXAddress).balanceOf(address(ethXWhale));
        vm.startPrank(ethXWhale);
        ERC20(ethXAddress).approve(address(lrtDepositPool), amountToDeposit);
        lrtDepositPool.depositAsset(ethXAddress, amountToDeposit, minAmountOfRSETHToReceive, referralId);
        vm.stopPrank();
        uint256 whaleethXBalAfter = ERC20(ethXAddress).balanceOf(address(ethXWhale));

        console.log("whale ethXETH amount transfer:", whaleethXBalBefore - whaleethXBalAfter);

        // ethXWhale balance of rsETH after deposit
        uint256 ethXWhaleBalanceAfter = rseth.balanceOf(address(ethXWhale));

        assertEq(
            lrtDepositPool.getTotalAssetDeposits(ethXAddress),
            totalAssetDepositsBefore + amountToDeposit,
            "Total asset deposits check is incorrect"
        );
        assertEq(
            ERC20(ethXAddress).balanceOf(address(lrtDepositPool)),
            lrtDepositPoolBalanceBefore + amountToDeposit,
            "lrtDepositPool balance is not set"
        );
        assertGt(ethXWhaleBalanceAfter, ethXWhaleBalanceBefore, "Alice balance is not set");
    }

    function test_GetCurrentAssetLimitAfterAssetIsDepositedInLRTDepositPool() external {
        uint256 depositAmount = 3 ether;

        uint256 stETHDepositLimitBefore = lrtDepositPool.getAssetCurrentLimit(stETHAddress);

        vm.startPrank(stWhale);
        ERC20(stETHAddress).approve(address(lrtDepositPool), depositAmount);
        lrtDepositPool.depositAsset(stETHAddress, depositAmount, minAmountOfRSETHToReceive, referralId);
        vm.stopPrank();

        uint256 stETHDepositLimitAfter = lrtDepositPool.getAssetCurrentLimit(stETHAddress);

        assertGt(stETHDepositLimitBefore, stETHDepositLimitAfter, "Deposit limit is not set");
    }

    function test_RevertWhenCallingAddNodeDelegatorByANonLRTAdmin() external {
        address randomAddress = makeAddr("randomAddress");

        address[] memory addNodeDelegatorArray = new address[](1);
        addNodeDelegatorArray[0] = randomAddress;

        vm.expectRevert(ILRTConfig.CallerNotLRTConfigAdmin.selector);
        lrtDepositPool.addNodeDelegatorContractToQueue(addNodeDelegatorArray);
    }

    function test_IsAbleToAddNodeDelegatorByLRTAdmin() external {
        address randomAddress = makeAddr("randomAddress");

        address[] memory addNodeDelegatorArray = new address[](1);
        addNodeDelegatorArray[0] = randomAddress;

        vm.prank(admin);
        lrtDepositPool.addNodeDelegatorContractToQueue(addNodeDelegatorArray);

        // 5 nodeDelegators were already added in contract at the time of deployment
        assertEq(lrtDepositPool.nodeDelegatorQueue(5), randomAddress, "Node delegator is not added");
    }

    function test_RevertWhenCallingTransferAssetToNodeDelegatorWhenNotCalledByManager() external {
        vm.expectRevert(ILRTConfig.CallerNotLRTConfigManager.selector);
        uint256 indexOfNodeDelegator = 0;
        lrtDepositPool.transferAssetToNodeDelegator(indexOfNodeDelegator, stETHAddress, 1 ether);
    }

    function test_TransferAssetSTETHToNodeDelegatorWhenCalledbyManager() external {
        uint256 amountToTransfer = 1e18;

        uint256 lrtDepositPoolBalanceBefore = ERC20(stETHAddress).balanceOf(address(lrtDepositPool));
        uint256 totalDepositsInStETHBeforeDeposit = lrtDepositPool.getTotalAssetDeposits(stETHAddress);

        vm.startPrank(stWhale);
        ERC20(stETHAddress).approve(address(lrtDepositPool), amountToTransfer);
        lrtDepositPool.depositAsset(stETHAddress, amountToTransfer, minAmountOfRSETHToReceive, referralId);
        vm.stopPrank();

        assertApproxEqAbs(
            ERC20(stETHAddress).balanceOf(address(lrtDepositPool)),
            lrtDepositPoolBalanceBefore + amountToTransfer,
            2,
            "lrtDepositPool balance is not set"
        );

        uint256 indexOfNodeDelegator;
        // find index of nodeDelegator1
        address[] memory nodeDelegatorArray = lrtDepositPool.getNodeDelegatorQueue();
        for (uint256 i = 0; i < nodeDelegatorArray.length; i++) {
            if (nodeDelegatorArray[i] == address(nodeDelegator1)) {
                indexOfNodeDelegator = i;
                break;
            }
        }

        uint256 nodeDelegator1BalanceBefore = ERC20(stETHAddress).balanceOf(address(nodeDelegator1));

        vm.prank(manager);
        lrtDepositPool.transferAssetToNodeDelegator(indexOfNodeDelegator, stETHAddress, amountToTransfer);

        uint256 nodeDelegator1BalanceAfter = ERC20(stETHAddress).balanceOf(address(nodeDelegator1));

        assertApproxEqAbs(
            lrtDepositPool.getTotalAssetDeposits(stETHAddress),
            totalDepositsInStETHBeforeDeposit + amountToTransfer,
            2,
            "Total asset deposits is not set"
        );

        // assert nodeDelegator1 balance before + 1 ether is equal to nodeDelegator1 balance after
        assertApproxEqAbs(
            nodeDelegator1BalanceAfter,
            nodeDelegator1BalanceBefore + amountToTransfer,
            2,
            "node delegator 1 balance is not set"
        );
        assertApproxEqAbs(
            ERC20(stETHAddress).balanceOf(address(nodeDelegator1)),
            amountToTransfer,
            2,
            "node delegator 1 balance is not set"
        );
    }

    function test_TransferAssetETHXToNodeDelegatorWhenCalledbyManager() external {
        uint256 amountToTransfer = 1e18;

        uint256 lrtDepositPoolBalanceBefore = ERC20(ethXAddress).balanceOf(address(lrtDepositPool));
        uint256 totalDepositsInethXBeforeDeposit = lrtDepositPool.getTotalAssetDeposits(ethXAddress);

        vm.startPrank(ethXWhale);
        ERC20(ethXAddress).approve(address(lrtDepositPool), amountToTransfer);
        lrtDepositPool.depositAsset(ethXAddress, amountToTransfer, minAmountOfRSETHToReceive, referralId);
        vm.stopPrank();

        assertEq(
            ERC20(ethXAddress).balanceOf(address(lrtDepositPool)),
            lrtDepositPoolBalanceBefore + amountToTransfer,
            "lrtDepositPool balance is not set"
        );

        uint256 indexOfNodeDelegator;
        // find index of nodeDelegator1
        address[] memory nodeDelegatorArray = lrtDepositPool.getNodeDelegatorQueue();
        for (uint256 i = 0; i < nodeDelegatorArray.length; i++) {
            if (nodeDelegatorArray[i] == address(nodeDelegator1)) {
                indexOfNodeDelegator = i;
                break;
            }
        }

        uint256 nodeDelegator1BalanceBefore = ERC20(ethXAddress).balanceOf(address(nodeDelegator1));

        vm.prank(manager);
        lrtDepositPool.transferAssetToNodeDelegator(indexOfNodeDelegator, ethXAddress, amountToTransfer);

        uint256 nodeDelegator1BalanceAfter = ERC20(ethXAddress).balanceOf(address(nodeDelegator1));

        assertEq(
            lrtDepositPool.getTotalAssetDeposits(ethXAddress),
            totalDepositsInethXBeforeDeposit + amountToTransfer,
            "Total asset deposits is not set"
        );

        // assert nodeDelegator1 balance before + 1 ether is equal to nodeDelegator1 balance after
        assertEq(
            nodeDelegator1BalanceAfter,
            nodeDelegator1BalanceBefore + amountToTransfer,
            "node delegator 1 balance is not set"
        );
        assertEq(
            ERC20(ethXAddress).balanceOf(address(nodeDelegator1)),
            amountToTransfer,
            "node delegator 1 balance is not set"
        );
    }

    function test_RevertUpdateMaxNodeDelegatorLimitWhenNotCalledByLRTConfigAdmin() external {
        vm.prank(stWhale);
        vm.expectRevert(ILRTConfig.CallerNotLRTConfigAdmin.selector);
        lrtDepositPool.updateMaxNodeDelegatorLimit(10);
    }

    function test_UpdateMaxNodeDelegatorLimitWhenCalledByAdmin() external {
        vm.startPrank(admin);
        lrtDepositPool.updateMaxNodeDelegatorLimit(100);
        vm.stopPrank();

        assertEq(lrtDepositPool.maxNodeDelegatorLimit(), 100, "Max node delegator count is not set");
    }

    function test_RevertPauseWhenNotCalledByLRTConfigManager() external {
        vm.prank(stWhale);
        vm.expectRevert(ILRTConfig.CallerNotLRTConfigManager.selector);
        lrtDepositPool.pause();
    }

    function test_PauseAndUnpauseWhenCalledByManagerAndAdmin() external {
        vm.prank(manager);
        lrtDepositPool.pause();

        assertTrue(lrtDepositPool.paused(), "LRTDepositPool is not paused");

        vm.prank(stWhale); // cannot unpause
        vm.expectRevert(ILRTConfig.CallerNotLRTConfigAdmin.selector);
        lrtDepositPool.unpause();

        vm.prank(admin);
        lrtDepositPool.unpause();

        assertFalse(lrtDepositPool.paused(), "LRTDepositPool is not unpaused");
    }
}

contract LRTConfigIntegrationTest is LRTIntegrationTest {
    function test_LRTConfigSetup() public {
        // priviledged roles
        assertTrue(lrtConfig.hasRole(LRTConstants.DEFAULT_ADMIN_ROLE, admin));
        assertTrue(lrtConfig.hasRole(LRTConstants.MANAGER, manager));

        // tokens
        assertEq(stETHAddress, lrtConfig.getLSTToken(LRTConstants.ST_ETH_TOKEN));
        assertEq(ethXAddress, lrtConfig.getLSTToken(LRTConstants.ETHX_TOKEN));
        assertEq(address(rseth), lrtConfig.rsETH());

        assertEq(lrtConfig.depositLimitByAsset(stETHAddress), 100_000 ether);
        assertEq(lrtConfig.depositLimitByAsset(ethXAddress), 100_000 ether);

        assertTrue(lrtConfig.isSupportedAsset(stETHAddress));
        assertTrue(lrtConfig.isSupportedAsset(ethXAddress));

        assertEq(GOERLI_EIGEN_STETH_STRATEGY, lrtConfig.assetStrategy(stETHAddress));
        // assertEq(vm.envAddress("ETHX_STRATEGY"), lrtConfig.assetStrategy(ethXAddress));

        assertEq(GOERLI_EIGEN_STRATEGY_MANAGER, lrtConfig.getContract(LRTConstants.EIGEN_STRATEGY_MANAGER));
        assertEq(address(lrtDepositPool), lrtConfig.getContract(LRTConstants.LRT_DEPOSIT_POOL));
        assertEq(address(lrtOracle), lrtConfig.getContract(LRTConstants.LRT_ORACLE));
    }

    function test_LRTConfigIsAlreadyInitialized() public {
        // attempt to initialize LRTConfig again reverts
        vm.expectRevert("Initializable: contract is already initialized");
        lrtConfig.initialize(admin, stETHAddress, ethXAddress, address(rseth));
    }

    function test_RevertWhenCallingAddNewAssetByANonLRTManager() external {
        address randomAssetAddress = makeAddr("randomAssetAddress");
        uint256 randomAssetDepositLimit = 100 ether;
        // Example of error message. Unfortunaly vm.expectRevert does not support the result of string casting.
        // string memory errorMessage = string(
        //     abi.encodePacked(
        //         "AccessControl: account ",
        //         Strings.toHexString(address(this)),
        //         " is missing role ",
        //         Strings.toHexString(uint256(LRTConstants.MANAGER), 32)
        //     )
        // );
        vm.expectRevert(
            "AccessControl: account 0x7fa9385be102ac3eac297483dd6233d62b3e1496 is missing role 0xaf290d8680820aad922855f39b306097b20e28774d6c1ad35a20325630c3a02c"
        );

        lrtConfig.addNewSupportedAsset(randomAssetAddress, randomAssetDepositLimit);
    }

    function test_IsAbleToAddNewAssetByManager() external {
        address randomAssetAddress = makeAddr("randomAssetAddress");
        uint256 randomAssetDepositLimit = 100 ether;

        vm.prank(manager);
        lrtConfig.addNewSupportedAsset(randomAssetAddress, randomAssetDepositLimit);

        assertEq(lrtConfig.depositLimitByAsset(randomAssetAddress), randomAssetDepositLimit);
    }

    function test_RevertUpdateAssetDepositLimitIfNotManager() external {
        vm.expectRevert(
            "AccessControl: account 0x7fa9385be102ac3eac297483dd6233d62b3e1496 is missing role 0xaf290d8680820aad922855f39b306097b20e28774d6c1ad35a20325630c3a02c"
        );

        lrtConfig.updateAssetDepositLimit(stETHAddress, 1000);
    }

    function test_UpdateAssetDepositLimit() external {
        uint256 depositLimit = 1000;

        vm.startPrank(manager);
        lrtConfig.updateAssetDepositLimit(stETHAddress, depositLimit);

        assertEq(lrtConfig.depositLimitByAsset(stETHAddress), depositLimit);
    }

    function test_RevertUpdateAssetStrategyIfNotAdmin() external {
        vm.expectRevert(
            "AccessControl: account 0x7fa9385be102ac3eac297483dd6233d62b3e1496 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
        );
        lrtConfig.updateAssetStrategy(stETHAddress, address(this));
    }

    function test_RevertWhenAssetIsNotSupported() external {
        address randomToken = makeAddr("randomToken");
        address strategy = makeAddr("strategy");

        vm.startPrank(admin);
        vm.expectRevert(ILRTConfig.AssetNotSupported.selector);
        lrtConfig.updateAssetStrategy(address(randomToken), strategy);
        vm.stopPrank();
    }

    function test_RevertWhenStrategyAddressIsZero() external {
        vm.startPrank(admin);
        vm.expectRevert(UtilLib.ZeroAddressNotAllowed.selector);
        lrtConfig.updateAssetStrategy(stETHAddress, address(0));
        vm.stopPrank();
    }

    function test_RevertWhenSameStrategyWasAlreadyAddedBeforeForAsset() external {
        address strategy = lrtConfig.assetStrategy(stETHAddress);
        vm.startPrank(admin);
        // revert when same strategy was already added before for asset
        vm.expectRevert(ILRTConfig.ValueAlreadyInUse.selector);
        lrtConfig.updateAssetStrategy(stETHAddress, strategy);
        vm.stopPrank();
    }

    function test_UpdateAssetStrategy() external {
        address strategy = makeAddr("strategy");

        vm.prank(admin);
        lrtConfig.updateAssetStrategy(stETHAddress, strategy);

        assertEq(lrtConfig.assetStrategy(stETHAddress), strategy);
    }

    function test_RevertSetRSETHIfNotAdmin() external {
        address newRSETH = makeAddr("newRSETH");

        vm.expectRevert(
            "AccessControl: account 0x7fa9385be102ac3eac297483dd6233d62b3e1496 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
        );
        lrtConfig.setRSETH(newRSETH);
    }

    function test_RevertSetRSETHIfRSETHAddressIsZero() external {
        vm.startPrank(admin);
        vm.expectRevert(UtilLib.ZeroAddressNotAllowed.selector);
        lrtConfig.setRSETH(address(0));
        vm.stopPrank();
    }

    function test_SetRSETH() external {
        address newRSETH = makeAddr("newRSETH");
        vm.prank(admin);
        lrtConfig.setRSETH(newRSETH);

        assertEq(lrtConfig.rsETH(), newRSETH);
    }

    function test_RevertSetTokenIfNotAdmin() external {
        vm.expectRevert(
            "AccessControl: account 0x7fa9385be102ac3eac297483dd6233d62b3e1496 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
        );
        lrtConfig.setToken(LRTConstants.ST_ETH_TOKEN, address(this));
    }

    function test_RevertSetTokenIfTokenAddressIsZero() external {
        vm.startPrank(admin);
        vm.expectRevert(UtilLib.ZeroAddressNotAllowed.selector);
        lrtConfig.setToken(LRTConstants.ST_ETH_TOKEN, address(0));
        vm.stopPrank();
    }

    function test_RevertSetTokenIfTokenAlreadySet() external {
        address newToken = makeAddr("newToken");
        vm.startPrank(admin);
        lrtConfig.setToken(LRTConstants.ST_ETH_TOKEN, newToken);

        // revert when same token was already set before
        vm.expectRevert(ILRTConfig.ValueAlreadyInUse.selector);
        lrtConfig.setToken(LRTConstants.ST_ETH_TOKEN, newToken);
        vm.stopPrank();
    }

    function test_SetToken() external {
        address newToken = makeAddr("newToken");

        vm.prank(admin);
        lrtConfig.setToken(LRTConstants.ST_ETH_TOKEN, newToken);

        assertEq(lrtConfig.tokenMap(LRTConstants.ST_ETH_TOKEN), newToken);
    }

    function test_RevertSetContractIfNotAdmin() external {
        vm.expectRevert(
            "AccessControl: account 0x7fa9385be102ac3eac297483dd6233d62b3e1496 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
        );
        lrtConfig.setContract(LRTConstants.LRT_ORACLE, address(this));
    }

    function test_RevertSetContractIfContractAddressIsZero() external {
        vm.startPrank(admin);
        vm.expectRevert(UtilLib.ZeroAddressNotAllowed.selector);
        lrtConfig.setContract(LRTConstants.LRT_ORACLE, address(0));
        vm.stopPrank();
    }

    function test_RevertSetContractIfContractAlreadySet() external {
        address newContract = makeAddr("newContract");
        vm.startPrank(admin);
        lrtConfig.setContract(LRTConstants.LRT_ORACLE, newContract);

        // revert when same contract was already set before
        vm.expectRevert(ILRTConfig.ValueAlreadyInUse.selector);
        lrtConfig.setContract(LRTConstants.LRT_ORACLE, newContract);
        vm.stopPrank();
    }

    function test_SetContract() external {
        address newContract = makeAddr("newContract");

        vm.prank(admin);
        lrtConfig.setContract(LRTConstants.LRT_ORACLE, newContract);

        assertEq(lrtConfig.contractMap(LRTConstants.LRT_ORACLE), newContract);
    }
}

contract LRTOracleIntegrationTest is LRTIntegrationTest {
    function test_LRTOracleSetup() public {
        assertLt(lrtOracle.getAssetPrice(ethXAddress), 1.2 ether);
        assertGt(lrtOracle.getAssetPrice(ethXAddress) + 1, 1 ether);

        assertLt(lrtOracle.getAssetPrice(stETHAddress), 1.2 ether);
        assertGt(lrtOracle.getAssetPrice(stETHAddress), 0.9 ether);

        assertEq(lrtOracle.assetPriceOracle(stETHAddress), chainlinkOracle);
        assertEq(lrtOracle.assetPriceOracle(ethXAddress), ethxPriceOracle);
    }

    function test_LRTOracleIsAlreadyInitialized() public {
        // attempt to initialize LRTOracle again reverts
        vm.expectRevert("Initializable: contract is already initialized");
        lrtOracle.initialize(address(lrtConfig));
    }

    function test_RevertWhenCallingUpdatePriceOracleForByANonLRTManager() external {
        address randomAssetAddress = makeAddr("randomAssetAddress");
        address randomPriceOracleAddress = makeAddr("randomPriceOracleAddress");

        vm.expectRevert(ILRTConfig.CallerNotLRTConfigManager.selector);
        lrtOracle.updatePriceOracleFor(randomAssetAddress, randomPriceOracleAddress);
    }

    function test_IsAbleToUpdatePriceOracleForAssetByLRTManager() external {
        address randomPriceOracleAddress = makeAddr("randomPriceOracleAddress");

        vm.prank(manager);
        lrtOracle.updatePriceOracleFor(stETHAddress, randomPriceOracleAddress);

        assertEq(lrtOracle.assetPriceOracle(stETHAddress), randomPriceOracleAddress);
    }
}

contract RSETHIntegrationTest is LRTIntegrationTest {
    function test_RSETHSetup() public {
        // check if lrtDepositPool has MINTER role
        assertTrue(lrtConfig.hasRole(LRTConstants.MINTER_ROLE, address(lrtDepositPool)));

        // check if lrtConfig is set in rsETH
        assertEq(address(rseth.lrtConfig()), address(lrtConfig));
    }

    function test_RSETHIsAlreadyInitialized() public {
        // attempt to initialize RSETH again reverts
        vm.expectRevert("Initializable: contract is already initialized");
        rseth.initialize(address(admin), address(lrtConfig));
    }

    function test_RevertWhenCallerIsNotLRTManager() external {
        vm.expectRevert(ILRTConfig.CallerNotLRTConfigManager.selector);
        rseth.pause();
    }

    function test_RevertWhenContractIsAlreadyPaused() external {
        vm.startPrank(manager);
        rseth.pause();

        vm.expectRevert("Pausable: paused");
        rseth.pause();

        vm.stopPrank();
    }

    function test_Pause() external {
        vm.startPrank(manager);
        rseth.pause();

        vm.stopPrank();

        assertTrue(rseth.paused(), "Contract is not paused");
    }

    function test_Unpause() external {
        vm.prank(manager);
        rseth.pause();

        assertTrue(rseth.paused(), "Contract is not paused");

        vm.prank(admin);
        rseth.unpause();

        assertFalse(rseth.paused(), "Contract is not unpaused");
    }

    function test_RevertWhenCallingUpdateLRTConfigAndCallerIsNotLRTAdmin() external {
        vm.expectRevert(ILRTConfig.CallerNotLRTConfigAdmin.selector);
        rseth.updateLRTConfig(address(lrtConfig));
    }

    function test_RevertWhenCallingUpdateLRTConfigAndLRTConfigIsZeroAddress() external {
        vm.startPrank(admin);
        vm.expectRevert(UtilLib.ZeroAddressNotAllowed.selector);
        rseth.updateLRTConfig(address(0));
        vm.stopPrank();
    }

    function test_UpdateLRTConfigWhenCallingUpdateLRTConfig() external {
        address newLRTConfigAddress = makeAddr("MockNewLRTConfig");
        ILRTConfig newLRTConfig = ILRTConfig(newLRTConfigAddress);

        vm.prank(admin);
        rseth.updateLRTConfig(address(newLRTConfig));

        assertEq(address(newLRTConfig), address(rseth.lrtConfig()), "LRT config address is not set");
    }
}

contract NodeDelegatorIntegrationTest is LRTIntegrationTest {
    uint256 amountToTransfer;

    function setUp() public override {
        super.setUp();

        amountToTransfer = 10 ether;

        vm.startPrank(stWhale);
        ERC20(stETHAddress).approve(address(lrtDepositPool), amountToTransfer);
        lrtDepositPool.depositAsset(stETHAddress, amountToTransfer, minAmountOfRSETHToReceive, referralId);
        vm.stopPrank();

        uint256 indexOfNodeDelegator = 0;

        vm.prank(manager);
        lrtDepositPool.transferAssetToNodeDelegator(indexOfNodeDelegator, stETHAddress, amountToTransfer);
    }

    function test_NodeDelegatorIsAlreadyInitialized() public {
        // attempt to initialize NodeDelegator again reverts
        vm.expectRevert("Initializable: contract is already initialized");
        nodeDelegator1.initialize(address(lrtConfig));
    }

    function test_RevertWhenCallerIsNotLRTManager() external {
        vm.expectRevert(ILRTConfig.CallerNotLRTConfigManager.selector);
        nodeDelegator1.pause();
    }

    function test_RevertWhenContractIsAlreadyPaused() external {
        vm.startPrank(manager);
        nodeDelegator1.pause();

        vm.expectRevert("Pausable: paused");
        nodeDelegator1.pause();

        vm.stopPrank();
    }

    function test_Pause() external {
        vm.startPrank(manager);
        nodeDelegator1.pause();

        vm.stopPrank();

        assertTrue(nodeDelegator1.paused(), "Contract is not paused");
    }

    function test_Unpause() external {
        vm.prank(manager);
        nodeDelegator1.pause();

        assertTrue(nodeDelegator1.paused(), "Contract is not paused");

        vm.prank(admin);
        nodeDelegator1.unpause();

        assertFalse(nodeDelegator1.paused(), "Contract is not unpaused");
    }

    function test_RevertWhenCallingMaxApproveToEigenStrategyManagerByCallerIsNotLRTManager() external {
        vm.expectRevert(ILRTConfig.CallerNotLRTConfigManager.selector);
        nodeDelegator1.maxApproveToEigenStrategyManager(stETHAddress);
    }

    function test_RevertWhenAssetIsNotSupportedInMaxApproveToEigenStrategyFunction() external {
        address randomAddress = address(0x123);
        vm.prank(manager);
        vm.expectRevert(ILRTConfig.AssetNotSupported.selector);
        nodeDelegator1.maxApproveToEigenStrategyManager(randomAddress);
    }

    function test_MaxApproveToEigenStrategyManager() external {
        address eigenlayerStrategyManagerAddress = lrtConfig.getContract(LRTConstants.EIGEN_STRATEGY_MANAGER);

        vm.prank(manager);
        nodeDelegator1.maxApproveToEigenStrategyManager(stETHAddress);

        // check that the nodeDelegator has max approved the eigen strategy manager
        assertEq(
            ERC20(stETHAddress).allowance(address(nodeDelegator1), eigenlayerStrategyManagerAddress), type(uint256).max
        );
    }

    function test_RevertWhenCallingDepositAssetIntoStrategyAndNodeDelegatorIsPaused() external {
        vm.startPrank(manager);
        nodeDelegator1.pause();

        vm.expectRevert("Pausable: paused");
        nodeDelegator1.depositAssetIntoStrategy(stETHAddress);

        vm.stopPrank();
    }

    function test_RevertWhenAssetIsNotSupportedInDepositAssetIntoStrategyFunction() external {
        address randomAddress = address(0x123);
        vm.prank(manager);
        vm.expectRevert(ILRTConfig.AssetNotSupported.selector);
        nodeDelegator1.depositAssetIntoStrategy(randomAddress);
    }

    function test_RevertWhenCallingDepositAssetIntoStrategyAndCallerIsNotManager() external {
        vm.expectRevert(ILRTConfig.CallerNotLRTConfigManager.selector);
        nodeDelegator1.depositAssetIntoStrategy(stETHAddress);
    }

    function test_DepositAssetIntoStrategyFromNodeDelegator() external {
        console.log(
            "nodeDel stETH balance before submitting to strategy:",
            ERC20(stETHAddress).balanceOf(address(nodeDelegator1))
        );

        (uint256 assetLyingInDepositPool, uint256 assetLyingInNDCs, uint256 assetStakedInEigenLayer) =
            lrtDepositPool.getAssetDistributionData(stETHAddress);

        console.log("#######");
        console.log("getAssetDistributionData for stETH BEFORE submitting funds to strategy");
        console.log("assetLyingInDepositPool", assetLyingInDepositPool);
        console.log("assetLyingInNDCs", assetLyingInNDCs);
        console.log("assetStakedInEigenLayer", assetStakedInEigenLayer);
        console.log("#######");

        address eigenlayerSTETHStrategyAddress = lrtConfig.assetStrategy(stETHAddress);
        uint256 balanceOfStrategyBefore = ERC20(stETHAddress).balanceOf(eigenlayerSTETHStrategyAddress);
        console.log("balanceOfStrategyBefore", balanceOfStrategyBefore);

        vm.startPrank(manager);
        nodeDelegator1.maxApproveToEigenStrategyManager(stETHAddress);
        nodeDelegator1.depositAssetIntoStrategy(stETHAddress);
        vm.stopPrank();

        uint256 balanceOfStrategyAfter = ERC20(stETHAddress).balanceOf(eigenlayerSTETHStrategyAddress);
        console.log("balanceOfStrategyAfter", balanceOfStrategyAfter);

        console.log("stETH amount submitted to strategy", balanceOfStrategyAfter - balanceOfStrategyBefore);

        (assetLyingInDepositPool, assetLyingInNDCs, assetStakedInEigenLayer) =
            lrtDepositPool.getAssetDistributionData(stETHAddress);
        console.log("#######");
        console.log("getAssetDistributionData for stETH AFTER submitting funds to strategy");
        console.log("assetLyingInDepositPool", assetLyingInDepositPool);
        console.log("assetLyingInNDCs", assetLyingInNDCs);
        console.log("assetStakedInEigenLayer", assetStakedInEigenLayer);

        assertGt(
            balanceOfStrategyAfter,
            balanceOfStrategyBefore,
            "Balance of strategy after is not greater than balance of strategy before tx"
        );
    }
}
