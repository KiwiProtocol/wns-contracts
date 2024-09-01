// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract WNSOffChainStorage is Initializable, OwnableUpgradeable, PausableUpgradeable {
    mapping(bytes32 => string) private ipfsHashes;
    mapping(bytes32 => uint256) private lastUpdated;

    event OffChainDataUpdated(bytes32 indexed node, string ipfsHash);

    function initialize() public initializer {
        __Ownable_init();
        __Pausable_init();
    }

    function setIPFSHash(bytes32 _node, string calldata _ipfsHash) external onlyOwner whenNotPaused {
        ipfsHashes[_node] = _ipfsHash;
        lastUpdated[_node] = block.timestamp;
        emit OffChainDataUpdated(_node, _ipfsHash);
    }

    function getIPFSHash(bytes32 _node) public view returns (string memory, uint256) {
        return (ipfsHashes[_node], lastUpdated[_node]);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}