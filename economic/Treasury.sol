// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract WNSTreasury is Initializable, AccessControlUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant TREASURER_ROLE = keccak256("TREASURER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint256 public constant WITHDRAWAL_DELAY = 3 days;

    struct WithdrawalRequest {
        address payable recipient;
        uint256 amount;
        uint256 unlockTime;
        bool isERC20;
        address tokenAddress;
    }

    mapping(bytes32 => WithdrawalRequest) public withdrawalRequests;
    mapping(address => bool) public whitelistedTokens;

    event WithdrawalRequested(bytes32 indexed requestId, address indexed recipient, uint256 amount, address tokenAddress);
    event WithdrawalCompleted(bytes32 indexed requestId, address indexed recipient, uint256 amount, address tokenAddress);
    event WithdrawalCancelled(bytes32 indexed requestId);
    event TokenWhitelisted(address indexed token);
    event TokenBlacklisted(address indexed token);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TREASURER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
    }

    function requestWithdrawal(address payable _recipient, uint256 _amount) external onlyRole(TREASURER_ROLE) whenNotPaused returns (bytes32) {
        require(_recipient != address(0), "Invalid recipient");
        require(_amount > 0, "Invalid amount");
        require(address(this).balance >= _amount, "Insufficient balance");

        bytes32 requestId = keccak256(abi.encodePacked(_recipient, _amount, block.timestamp));
        withdrawalRequests[requestId] = WithdrawalRequest({
            recipient: _recipient,
            amount: _amount,
            unlockTime: block.timestamp + WITHDRAWAL_DELAY,
            isERC20: false,
            tokenAddress: address(0)
        });

        emit WithdrawalRequested(requestId, _recipient, _amount, address(0));
        return requestId;
    }

    function requestERC20Withdrawal(address payable _recipient, uint256 _amount, address _token) external onlyRole(TREASURER_ROLE) whenNotPaused returns (bytes32) {
        require(_recipient != address(0), "Invalid recipient");
        require(_amount > 0, "Invalid amount");
        require(whitelistedTokens[_token], "Token not whitelisted");
        require(IERC20Upgradeable(_token).balanceOf(address(this)) >= _amount, "Insufficient token balance");

        bytes32 requestId = keccak256(abi.encodePacked(_recipient, _amount, _token, block.timestamp));
        withdrawalRequests[requestId] = WithdrawalRequest({
            recipient: _recipient,
            amount: _amount,
            unlockTime: block.timestamp + WITHDRAWAL_DELAY,
            isERC20: true,
            tokenAddress: _token
        });

        emit WithdrawalRequested(requestId, _recipient, _amount, _token);
        return requestId;
    }

 