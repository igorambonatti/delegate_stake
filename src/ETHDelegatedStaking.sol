// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IValidator {
    function delegate(uint256 amount) external;

    function undelegate(uint256 amount) external;

    function claimRewards() external returns (uint256);
}

contract ETHDelegatedStaking {
    address public owner;
    IValidator public validator;
    uint256 public totalStaked;
    bool private locked;

    struct Stake {
        uint256 amount;
        uint256 lastUpdatedTimestamp;
    }

    mapping(address => Stake) public stakes;
    address[] public activeUsers;
    mapping(address => uint256) private activeUserIndex;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event DelegatedToValidator(uint256 amount);
    event UndelegatedFromValidator(uint256 amount);
    event ValidatorUpdated(address oldValidator, address newValidator);
    event FundsReceived(address indexed sender, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier nonReentrant() {
        require(!locked, "Reentrant call detected!");
        locked = true;
        _;
        locked = false;
    }

    constructor() {
        owner = msg.sender;
    }

    function stake() external payable nonReentrant {
        require(msg.value > 0, "Stake amount must be greater than zero");
        require(address(validator) != address(0), "Validator not set");

        if (stakes[msg.sender].amount == 0) {
            activeUserIndex[msg.sender] = activeUsers.length;
            activeUsers.push(msg.sender);
        }

        stakes[msg.sender].amount += msg.value;
        stakes[msg.sender].lastUpdatedTimestamp = block.timestamp;
        totalStaked += msg.value;

        validator.delegate(msg.value);
        emit DelegatedToValidator(msg.value);
        emit Staked(msg.sender, msg.value);
    }

    function reinvestRewards() external onlyOwner nonReentrant {
        require(address(validator) != address(0), "Validator not set");
        uint256 claimed = validator.claimRewards();
        require(claimed > 0, "No rewards to reinvest");

        totalStaked += claimed;

        for (uint256 i = 0; i < activeUsers.length; i++) {
            address user = activeUsers[i];
            if (stakes[user].amount > 0) {
                uint256 userShare = (stakes[user].amount * claimed) /
                    (totalStaked - claimed);
                stakes[user].amount += userShare;
            }
        }

        validator.delegate(claimed);
        emit DelegatedToValidator(claimed);
    }

    function withdraw() external nonReentrant {
        uint256 stakedAmount = stakes[msg.sender].amount;
        require(stakedAmount > 0, "No stake to withdraw");

        stakes[msg.sender].amount = 0;
        totalStaked -= stakedAmount;

        uint256 index = activeUserIndex[msg.sender];
        uint256 lastIndex = activeUsers.length - 1;

        if (index != lastIndex) {
            address lastUser = activeUsers[lastIndex];
            activeUsers[index] = lastUser;
            activeUserIndex[lastUser] = index;
        }
        activeUsers.pop();
        delete activeUserIndex[msg.sender];

        if (address(validator) != address(0)) {
            validator.undelegate(stakedAmount);
            emit UndelegatedFromValidator(stakedAmount);
        }

        payable(msg.sender).transfer(stakedAmount);
        emit Withdrawn(msg.sender, stakedAmount);
    }

    function setValidator(address _newValidator) external onlyOwner {
        require(_newValidator != address(0), "Invalid validator address");
        require(isContract(_newValidator), "Validator must be a contract");

        emit ValidatorUpdated(address(validator), _newValidator);
        validator = IValidator(_newValidator);
    }

    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getStakeInfo(
        address _user
    ) external view returns (uint256, uint256) {
        Stake storage userStake = stakes[_user];
        return (userStake.amount, userStake.lastUpdatedTimestamp);
    }

    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }

    fallback() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}
