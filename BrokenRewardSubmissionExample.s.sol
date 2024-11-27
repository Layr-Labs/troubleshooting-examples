// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "eigenlayer-contracts/src/contracts/interfaces/IRewardsCoordinator.sol";
import "../src/StakeRegistry.sol";
import "../src/ServiceManagerBase.sol";
import "forge-std/Script.sol";
import "forge-std/StdUtils.sol";

contract BrokenRewardSubmissionExample is Script {
    // FILL IN THESE VALUES
    uint256 AMOUNT_TO_ETH_QUORUM = 10 ether;
    uint32 START_TIMESTAMP = uint32(block.timestamp);
    uint32 DURATION = 604800
    address SERVICE_MANAGER = CORRECT_SERVICE_MANAGER_ADDRESS;
    address STAKE_REGISTRY = CORRECT_STAKE_REGISTRY_ADDRESS;
    address TOKEN = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; 

    bytes calldata_to_serviceManager;

    function run() external {
        calldata_to_serviceManager = _getCalldataToServiceManager();

        vm.startBroadcast();
        (bool success, ) = address(SERVICE_MANAGER).call(calldata_to_serviceManager);
        require(success, "rewards submission failed");
        vm.stopBroadcast();
    }

    function _getCalldataToServiceManager() public returns (bytes memory _calldata_to_serviceManager) {
        IRewardsCoordinator.RewardsSubmission[] memory rewardsSubmissions = new IRewardsCoordinator.RewardsSubmission[](2);

        // fetch ETH strategy weights
        uint256 length = StakeRegistry(STAKE_REGISTRY).strategyParamsLength(0); 
        IRewardsCoordinator.StrategyAndMultiplier[] memory ETH_strategyAndMultipliers = new IRewardsCoordinator.StrategyAndMultiplier[](length);
        for (uint256 i = 0; i < length; i++) {
            (IStrategy strategy, uint96 multiplier) = StakeRegistry(STAKE_REGISTRY).strategyParams(0, i);
            ETH_strategyAndMultipliers[i] = IRewardsCoordinator.StrategyAndMultiplier({
                strategy: strategy,
                multiplier: multiplier
            });
        }
        
        // Create ETH rewards submission
        rewardsSubmissions[0] = IRewardsCoordinator.RewardsSubmission({
            strategiesAndMultipliers: ETH_strategyAndMultipliers,
            token: IERC20(TOKEN),
            amount: AMOUNT_TO_ETH_QUORUM,
            startTimestamp: START_TIMESTAMP,
            duration: DURATION
        });


        _calldata_to_serviceManager = abi.encodeWithSelector(
            ServiceManagerBase.createAVSRewardsSubmission.selector,
            rewardsSubmissions
        );

        return _calldata_to_serviceManager;
    }
}