// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract WNSReverseResolver is Initializable, OwnableUpgradeable, PausableUpgradeable {
    mapping(uint256 => mapping(string => bytes32)) private reverseRecords; // chainId => address => node

    event ReverseClaimed(uint256 indexed chainId, string indexed addr, bytes32 indexed node);

    function initialize() public initializer {
        __Ownable_init();
        __Pausable_init();
    }

    function setReverse(uint256 _chainId, string calldata _addr, bytes32 _node) external onlyOwner whenNotPaused {
        reverseRecords[_chainId][_addr] = _node;
        emit ReverseClaimed(_chainId, _addr, _node);
    }

    function getReverse(uint256 _chainId, string calldata _addr) public view returns (bytes32) {
        return reverseRecords[_chainId][_addr];
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}