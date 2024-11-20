// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockValidator {
    uint256 public totalDelegated;

    event Delegated(address indexed from, uint256 amount);
    event Undelegated(address indexed from, uint256 amount);
    event RewardsClaimed(address indexed from, uint256 rewards);

    function delegate(uint256 amount) external {
        totalDelegated += amount;
        emit Delegated(msg.sender, amount);
    }

    function undelegate(uint256 amount) external {
        require(totalDelegated >= amount, "Insufficient delegated balance");
        totalDelegated -= amount;
        emit Undelegated(msg.sender, amount);
    }

    function claimRewards() external returns (uint256) {
        uint256 rewards = (totalDelegated * 10) / 100;
        emit RewardsClaimed(msg.sender, rewards);
        return rewards;
    }

    function getDelegatedBalance() external view returns (uint256) {
        return totalDelegated;
    }
}
