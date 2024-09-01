// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract WNSMultichainResolver is Initializable, OwnableUpgradeable, PausableUpgradeable {
    struct Resolution {
        mapping(uint256 => string) addresses; // chainId => address
        string contentHash;
        mapping(string => string) texts;
    }

    mapping(bytes32 => Resolution) private resolutions;
    mapping(bytes32 => uint256) public updateTime;
    uint256 public cacheTTL;

    event AddressChanged(bytes32 indexed node, uint256 chainId, string newAddress);
    event ContentHashChanged(bytes32 indexed node, string newContentHash);
    event TextChanged(bytes32 indexed node, string indexed key, string value);

    function initialize(uint256 _cacheTTL) public initializer {
        __Ownable_init();
        __Pausable_init();
        cacheTTL = _cacheTTL;
    }

    function setAddress(bytes32 _node, uint256 _chainId, string calldata _address) external onlyOwner whenNotPaused {
        resolutions[_node].addresses[_chainId] = _address;
        updateTime[_node] = block.timestamp;
        emit AddressChanged(_node, _chainId, _address);
    }

    function setContentHash(bytes32 _node, string calldata _contentHash) external onlyOwner whenNotPaused {
        resolutions[_node].contentHash = _contentHash;
        updateTime[_node] = block.timestamp;
        emit ContentHashChanged(_node, _contentHash);
    }

    function setText(bytes32 _node, string calldata _key, string calldata _value) external onlyOwner whenNotPaused {
        resolutions[_node].texts[_key] = _value;
        updateTime[_node] = block.timestamp;
        emit TextChanged(_node, _key, _value);
    }

    function getAddress(bytes32 _node, uint256 _chainId) public view returns (string memory) {
        require(block.timestamp - updateTime[_node] <= cacheTTL, "Resolution cache expired");
        return resolutions[_node].addresses[_chainId];
    }

    function getContentHash(bytes32 _node) public view returns (string memory) {
        require(block.timestamp - updateTime[_node] <= cacheTTL, "Resolution cache expired");
        return resolutions[_node].contentHash;
    }

    function getText(bytes32 _node, string calldata _key) public view returns (string memory) {
        require(block.timestamp - updateTime[_node] <= cacheTTL, "Resolution cache expired");
        return resolutions[_node].texts[_key];
    }

    function setCacheTTL(uint256 _newCacheTTL) external onlyOwner {
        cacheTTL = _newCacheTTL;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}