// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract WNSChainAbstraction is Initializable, OwnableUpgradeable, PausableUpgradeable {
    struct ChainConfig {
        uint16 chainId;
        address bridgeContract;
        uint256 gasPrice;
        uint256 gasLimit;
    }

    mapping(uint16 => ChainConfig) public chainConfigs;

    event ChainConfigUpdated(uint16 chainId, address bridgeContract, uint256 gasPrice, uint256 gasLimit);

    function initialize() public initializer {
        __Ownable_init();
        __Pausable_init();
    }

    function setChainConfig(uint16 _chainId, address _bridgeContract, uint256 _gasPrice, uint256 _gasLimit) external onlyOwner {
        chainConfigs[_chainId] = ChainConfig(_chainId, _bridgeContract, _gasPrice, _gasLimit);
        emit ChainConfigUpdated(_chainId, _bridgeContract, _gasPrice, _gasLimit);
    }

    function getChainConfig(uint16 _chainId) public view returns (ChainConfig memory) {
        return chainConfigs[_chainId];
    }

    function estimateCrossChainFee(uint16 _targetChain, uint256 _dataSize) public view returns (uint256) {
        ChainConfig memory config = chainConfigs[_targetChain];
        require(config.chainId != 0, "Chain not configured");
        return config.gasPrice * config.gasLimit * _dataSize;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}