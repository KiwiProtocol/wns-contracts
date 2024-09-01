// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

contract WNSSecurityModule is Initializable, ReentrancyGuardUpgradeable, PausableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    using ECDSAUpgradeable for bytes32;

    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint256 public constant EMERGENCY_SHUTDOWN_THRESHOLD = 3;

    mapping(address => bool) public blacklistedAddresses;
    mapping(bytes32 => bool) public usedSignatures;

    uint256 public emergencyShutdownVotes;
    mapping(address => bool) public hasVotedForShutdown;

    event AddressBlacklisted(address indexed blacklistedAddress);
    event AddressWhitelisted(address indexed whitelistedAddress);
    event EmergencyShutdownInitiated(address indexed initiator);
    event EmergencyShutdownVoteCast(address indexed voter);
    event EmergencyShutdownExecuted();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialGuardian) public initializer {
        __ReentrancyGuard_init();
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, initialGuardian);
        _setupRole(GUARDIAN_ROLE, initialGuardian);
        _setupRole(UPGRADER_ROLE, initialGuardian);
    }

    function blacklistAddress(address _address) external onlyRole(GUARDIAN_ROLE) {
        blacklistedAddresses[_address] = true;
        emit AddressBlacklisted(_address);
    }

    function whitelistAddress(address _address) external onlyRole(GUARDIAN_ROLE) {
        blacklistedAddresses[_address] = false;
        emit AddressWhitelisted(_address);
    }

    function isBlacklisted(address _address) public view returns (bool) {
        return blacklistedAddresses[_address];
    }

    function verifySignature(bytes32 _messageHash, bytes memory _signature) public view returns (bool) {
        bytes32 ethSignedMessageHash = _messageHash.toEthSignedMessageHash();
        address signer = ethSignedMessageHash.recover(_signature);
        return hasRole(GUARDIAN_ROLE, signer) && !usedSignatures[_messageHash];
    }

    function markSignatureAsUsed(bytes32 _messageHash) external onlyRole(GUARDIAN_ROLE) {
        usedSignatures[_messageHash] = true;
    }

    function initiateEmergencyShutdown() external onlyRole(GUARDIAN_ROLE) {
        require(!hasVotedForShutdown[msg.sender], "Already voted for shutdown");
        hasVotedForShutdown[msg.sender] = true;
        emergencyShutdownVotes++;
        emit EmergencyShutdownVoteCast(msg.sender);

        if (emergencyShutdownVotes >= EMERGENCY_SHUTDOWN_THRESHOLD) {
            _pause();
            emit EmergencyShutdownExecuted();
        }
    }

    function executeEmergencyAction(address target, bytes memory data) external onlyRole(GUARDIAN_ROLE) whenPaused {
        (bool success, ) = target.call(data);
        require(success, "Emergency action failed");
    }

    function resetEmergencyShutdown() external onlyRole(DEFAULT_ADMIN_ROLE) whenPaused {
        emergencyShutdownVotes = 0;
        for (uint i = 0; i < getRoleMemberCount(GUARDIAN_ROLE); i++) {
            hasVotedForShutdown[getRoleMember(GUARDIAN_ROLE, i)] = false;
        }
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}
}