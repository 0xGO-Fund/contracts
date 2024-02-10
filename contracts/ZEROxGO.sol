// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface StakingPool {
    function userBalance(
        address
    ) external view returns (uint256, uint256, uint256);
}

interface MasterChef {
    function mint(address to, uint256 amount) external returns (bool);
}

contract Communities is Ownable(msg.sender) {
    address[] private _communities;

    function communities() public view virtual returns (address[] memory) {
        return _communities;
    }

    function addCommunity(address _community_id) public onlyOwner {
        require(_community_id != address(0), "InvalidCommunity");

        for (uint8 i = 0; i < _communities.length; i++) {
            if (_communities[i] == _community_id) {
                revert("CommunityAlreadyExists");
            }
        }

        _communities.push(_community_id);
    }
}

contract ZEROxGO is Communities {
    address public masterChef;
    uint256 public lockTime = 120;

    address private _stakeToken;
    uint256 private _totalSaked;
    address private _pool;

    mapping(address c_id => mapping(address => uint256)) private _delegations;
    mapping(address c_id => uint256) private _delegations_by_community;

    constructor(address poolAddress, address tokenAddress) {
        _stakeToken = tokenAddress;
        _pool = poolAddress;
    }

    function stakingToken() public view virtual returns (address) {
        return _stakeToken;
    }

    function stakingPool() public view virtual returns (address) {
        return _pool;
    }

    function setLockTime(uint256 _lockTime) external onlyOwner {
        lockTime = _lockTime;
    }

    function getPendingStakeBalance(
        address _user
    ) public view virtual returns (uint256, uint256) {
        (uint256 balance, , uint256 depositTimestamp) = StakingPool(_pool)
            .userBalance(_user);

        return (balance, depositTimestamp);
    }

    // TODO: Add function that allows anyone to stake
    // all the pending amount in the pool and give them
    // incentives for doing so (Protocol tokens, + 0.5% of the reward pool)
    // Or first time users an NFT based on the amount staked

    function depositAndStake(address _community_id, uint256 _amount) external {
        require(_amount > 0, "InvalidAmount");
        require(_community_id != address(0), "InvalidCommunity");

        IERC20 token = IERC20(_stakeToken);
        bool communityExists = false;
        address[] memory comms = communities();

        for (uint8 i = 0; i < comms.length; i++) {
            if (comms[i] == _community_id) {
                communityExists = true;
                break;
            }
        }
        require(communityExists, "InvalidPool");

        require(
            // Transfer the amount to this contract
            token.transferFrom(msg.sender, address(this), _amount),
            "TransferFailed"
        );

        if (token.allowance(address(this), _pool) < _amount) {
            // Approve the pool to spend the amount
            // if it's less than the amount required
            require(token.approve(_pool, _amount), "ApproveFailed");
        }

        // Check for contract's pending amount to be staked
        (
            uint256 pendingToStake,
            uint256 depositTimestamp
        ) = getPendingStakeBalance(address(this));

        if (
            depositTimestamp > 0 &&
            pendingToStake > 0 &&
            block.timestamp > depositTimestamp + lockTime
        ) {
            // Stake the pending amount
            // Ty to user that executed the function
            require(
                executes(
                    _pool,
                    abi.encodeWithSignature("stake(uint256)", pendingToStake)
                ),
                "StakeFailed"
            );
        }

        // Continue with the deposit
        require(
            executes(
                _pool,
                abi.encodeWithSignature("deposit(uint256)", _amount)
            ),
            "DepositFailed"
        );

        // We are safe to assume that the calls went through, so we can update the state
        _totalSaked += _amount;
        _delegations[_community_id][msg.sender] += _amount;
        _delegations_by_community[_community_id] += _amount;
    }

    function unstake(address _community_id, uint256 _amount) external {
        // Check if the user has enough funds to unstake/withdraw
        // NOTE: Add same pending balance to be staked functionality

        if (_delegations[_community_id][msg.sender] - _amount < 0) {
            revert("InsufficientFunds");
        }

        require(
            executes(
                _pool,
                abi.encodeWithSignature("unstake(uint256)", _amount)
            ),
            "UnstakeFailed"
        );

        require(
            executes(
                _pool,
                abi.encodeWithSignature("withdraw(uint256)", _amount)
            ),
            "WithdrawFailed"
        );

        _totalSaked -= _amount;
        _delegations[_community_id][msg.sender] -= _amount;
        _delegations_by_community[_community_id] -= _amount;
    }

    function getDelegatedBalance(
        address _community_id,
        address _user
    ) public view virtual returns (uint256) {
        return _delegations[_community_id][_user];
    }

    function getDelegatedBalance(
        address community_id
    ) public view virtual returns (uint256) {
        return _delegations_by_community[community_id];
    }

    function getTotalStaked() public view virtual returns (uint256) {
        return _totalSaked;
    }

    function executes(
        address addy,
        bytes memory payload
    ) private returns (bool) {
        (bool success, ) = addy.call(payload);
        return success;
    }

    function sweepToken(address _token) public onlyOwner {
        // bytes calldata _signatures
        // TODO: Add signature verification from DAO or others

        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));

        require(token.approve(owner(), balance), "ApproveFailed");
        require(token.transfer(owner(), balance), "TransferFailed");
    }

    function setupMasterChef(address _masterChef) public onlyOwner {
        masterChef = _masterChef;
    }

    function stakeAndEarn() public {
        require(masterChef != address(0), "MasterChefNotSet");
        _mint(msg.sender, 120 ether);
    }

    function _mint(address to, uint256 amount) private {
        MasterChef(masterChef).mint(to, amount);
    }
}

/**
 *
 * NOTE: Get reward balance
 * 1. Get the total amount of tokens in the pool `
 * 2. Get the total amount of tokens staked
 * So,
 * Rewards = StakinPoolImp.sharesToAmount(StakinPoolImp.userBalance(pool)) - totalStaked
 *
 *
 * Incentives
 * 1. 0.7% of the balance pending to be staked (Taken from REWARDS Pool)
 *    Cap at 250 CTSI
 * 2. 1.3% in ZEROToken of the balance pending to be staked
 *    Cap at 420 ZERO
 *
 * Unstaking Fees
 * 1. On unstake, 2% goes to DAO (An EOA Wallet, ours)
 * 2. On unstake, 5% goes to the community (basically giving the user 93% it's total balance + earned)
 *
 * NOTE: Add function to calculate the rewards earned by `stakeAndEarn` function
 */
