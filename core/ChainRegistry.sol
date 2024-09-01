// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract WNSChainRegistry is Initializable, OwnableUpgradeable, PausableUpgradeable {
    struct Domain {
        address owner;
        uint256 expiration;
        string data;
    }

    mapping(bytes32 => Domain) public domains;
    
    uint256 public registrationFee;
    uint256 public constant REGISTRATION_PERIOD = 365 days;

    event DomainRegistered(string name, address owner, uint256 expiration);
    event DomainRenewed(string name, uint256 newExpiration);
    event DomainTransferred(string name, address newOwner);

    function initialize(uint256 _initialRegistrationFee) public initializer {
        __Ownable_init();
        __Pausable_init();
        registrationFee = _initialRegistrationFee;
    }

    function register(string memory _name) external payable whenNotPaused {
        bytes32 nameHash = keccak256(bytes(_name));
        require(domains[nameHash].owner == address(0), "Domain already registered");
        require(msg.value >= registrationFee, "Insufficient registration fee");

        domains[nameHash] = Domain({
            owner: msg.sender,
            expiration: block.timestamp + REGISTRATION_PERIOD,
            data: ""
        });

        emit DomainRegistered(_name, msg.sender, domains[nameHash].expiration);
    }

    function renew(string memory _name) external payable whenNotPaused {
        bytes32 nameHash = keccak256(bytes(_name));
        require(domains[nameHash].owner != address(0), "Domain not registered");
        require(msg.value >= registrationFee, "Insufficient renewal fee");

        domains[nameHash].expiration += REGISTRATION_PERIOD;

        emit DomainRenewed(_name, domains[nameHash].expiration);
    }

    function transfer(string memory _name, address _newOwner) external whenNotPaused {
        bytes32 nameHash = keccak256(bytes(_name));
        require(domains[nameHash].owner == msg.sender, "Not the domain owner");
        
        domains[nameHash].owner = _newOwner;

        emit DomainTransferred(_name, _newOwner);
    }

    function setData(string memory _name, string memory _data) external whenNotPaused {
        bytes32 nameHash = keccak256(bytes(_name));
        require(domains[nameHash].owner == msg.sender, "Not the domain owner");
        
        domains[nameHash].data = _data;
    }

    function getData(string memory _name) external view returns (string memory) {
        bytes32 nameHash = keccak256(bytes(_name));
        return domains[nameHash].data;
    }

    function updateRegistrationFee(uint256 _newFee) external onlyOwner {
        registrationFee = _newFee;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}