// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract WNSCachingLayer is Initializable, OwnableUpgradeable, PausableUpgradeable {
    struct CachedData {
        bytes data;
        uint256 timestamp;
    }

    mapping(bytes32 => CachedData) private cache;
    uint256 public cacheTTL;

    event CacheUpdated(bytes32 indexed key, bytes data);
    event CacheTTLUpdated(uint256 newTTL);

    function initialize(uint256 _initialCacheTTL) public initializer {
        __Ownable_init();
        __Pausable_init();
        cacheTTL = _initialCacheTTL;
    }

    function setCachedData(bytes32 _key, bytes calldata _data) external onlyOwner whenNotPaused {
        cache[_key] = CachedData(_data, block.timestamp);
        emit CacheUpdated(_key, _data);
    }

    function getCachedData(bytes32 _key) public view returns (bytes memory, bool) {
        CachedData memory cachedData = cache[_key];
        if (cachedData.timestamp == 0 || block.timestamp - cachedData.timestamp > cacheTTL) {
            return (new bytes(0), false);
        }
        return (cachedData.data, true);
    }

    function setCacheTTL(uint256 _newTTL) external onlyOwner {
        cacheTTL = _newTTL;
        emit CacheTTLUpdated(_newTTL);
    }

    function clearCache(bytes32 _key) external onlyOwner {
        delete cache[_key];
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}