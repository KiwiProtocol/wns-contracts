// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract WNSRootRegistry is Initializable, OwnableUpgradeable, PausableUpgradeable {
    mapping(string => bool) public topLevelDomains;
    mapping(uint256 => address) public chainRegistries;
    
    uint256 public constant REGISTRATION_PERIOD = 365 days;
    uint256 public registrationFee;

    event TLDRegistered(string tld, address owner);
    event ChainRegistrySet(uint256 chainId, address registry);
    event RegistrationFeeUpdated(uint256 newFee);

    function initialize(uint256 _initialRegistrationFee) public initializer {
        __Ownable_init();
        __Pausable_init();
        registrationFee = _initialRegistrationFee;
    }

    function registerTLD(string memory _tld) external payable whenNotPaused {
        require(!topLevelDomains[_tld], "TLD already registered");
        require(msg.value >= registrationFee, "Insufficient registration fee");

        topLevelDomains[_tld] = true;
        emit TLDRegistered(_tld, msg.sender);
    }

    function setChainRegistry(uint256 _chainId, address _registry) external onlyOwner {
        chainRegistries[_chainId] = _registry;
        emit ChainRegistrySet(_chainId, _registry);
    }

    function updateRegistrationFee(uint256 _newFee) external onlyOwner {
        registrationFee = _newFee;
        emit RegistrationFeeUpdated(_newFee);
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