// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract WNSAccessControl is Initializable, AccessControlUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    CountersUpgradeable.Counter private _roleRequestId;

    struct RoleRequest {
        address account;
        bytes32 role;
        bool approved;
        uint256 approvalCount;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => RoleRequest) public roleRequests;
    uint256 public roleRequestThreshold;

    event RoleRequested(uint256 indexed requestId, address indexed account, bytes32 indexed role);
    event RoleRequestApproved(uint256 indexed requestId, address indexed account, bytes32 indexed role);
    event RoleRequestRejected(uint256 indexed requestId, address indexed account, bytes32 indexed role);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialAdmin) public initializer {
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _setupRole(ADMIN_ROLE, initialAdmin);
        _setupRole(UPGRADER_ROLE, initialAdmin);

        roleRequestThreshold = 3; // Default threshold, can be changed by admin
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function requestRole(bytes32 role) public {
        require(role != DEFAULT_ADMIN_ROLE, "Cannot request DEFAULT_ADMIN_ROLE");
        require(!hasRole(role, msg.sender), "Account already has this role");

        _roleRequestId.increment();
        uint256 newRequestId = _roleRequestId.current();

        RoleRequest storage request = roleRequests[newRequestId];
        request.account = msg.sender;
        request.role = role;
        request.approved = false;
        request.approvalCount = 0;

        emit RoleRequested(newRequestId, msg.sender, role);
    }

    function approveRoleRequest(uint256 requestId) public onlyRole(ADMIN_ROLE) {
        RoleRequest storage request = roleRequests[requestId];
        require(!request.approved, "Request already approved");
        require(!request.hasVoted[msg.sender], "Admin has already voted");

        request.approvalCount += 1;
        request.hasVoted[msg.sender] = true;

        if (request.approvalCount >= roleRequestThreshold) {
            request.approved = true;
            _grantRole(request.role, request.account);
            emit RoleRequestApproved(requestId, request.account, request.role);
        }
    }

    function rejectRoleRequest(uint256 requestId) public onlyRole(ADMIN_ROLE) {
        RoleRequest storage request = roleRequests[requestId];
        require(!request.approved, "Request already approved");

        delete roleRequests[requestId];
        emit RoleRequestRejected(requestId, request.account, request.role);
    }

    function setRoleRequestThreshold(uint256 newThreshold) public onlyRole(ADMIN_ROLE) {
        require(newThreshold > 0, "Threshold must be greater than 0");
        roleRequestThreshold = newThreshold;
    }

    function revokeRole(bytes32 role, address account) public override onlyRole(ADMIN_ROLE) {
        super.revokeRole(role, account);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}
}