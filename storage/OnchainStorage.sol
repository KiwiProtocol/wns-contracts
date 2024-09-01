// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract WNSOnChainStorage is Initializable, OwnableUpgradeable, PausableUpgradeable {
    struct NameRecord {
        address owner;
        uint256 expires;
        bytes32 resolver;
        uint256 ttl;
    }

    mapping(bytes32 => NameRecord) private records;
    mapping(address => mapping(bytes32 => bool)) private operators;

    event NameUpdated(bytes32 indexed node, address owner, uint256 expires, bytes32 resolver, uint256 ttl);
    event OperatorUpdated(address indexed owner, bytes32 indexed node, address indexed operator, bool approved);

    function initialize() public initializer {
        __Ownable_init();
        __Pausable_init();
    }

    function setRecord(bytes32 _node, address _owner, uint256 _expires, bytes32 _resolver, uint256 _ttl) external whenNotPaused {
        require(msg.sender == records[_node].owner || operators[records[_node].owner][_node], "Not authorized");
        records[_node] = NameRecord(_owner, _expires, _resolver, _ttl);
        emit NameUpdated(_node, _owner, _expires, _resolver, _ttl);
    }

    function getRecord(bytes32 _node) public view returns (address, uint256, bytes32, uint256) {
        NameRecord memory record = records[_node];
        return (record.owner, record.expires, record.resolver, record.ttl);
    }

    function setOperator(bytes32 _node, address _operator, bool _approved) external whenNotPaused {
        require(msg.sender == records[_node].owner, "Not the owner");
        operators[msg.sender][_node] = _approved;
        emit OperatorUpdated(msg.sender, _node, _operator, _approved);
    }

    function isOperator(address _owner, bytes32 _node, address _operator) public view returns (bool) {
        return operators[_owner][_node];
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}