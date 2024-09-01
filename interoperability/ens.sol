// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

interface IENS {
    function resolver(bytes32 node) external view returns (address);
}

interface IENSResolver {
    function addr(bytes32 node) external view returns (address);
}

contract WNSENSCompatibility is Initializable, OwnableUpgradeable, PausableUpgradeable {
    IENS public ens;
    mapping(bytes32 => bytes32) public wnsToEnsNodes;

    event ENSNodeMapped(bytes32 wnsNode, bytes32 ensNode);

    function initialize(address _ens) public initializer {
        __Ownable_init();
        __Pausable_init();
        ens = IENS(_ens);
    }

    function mapWNSToENS(bytes32 _wnsNode, bytes32 _ensNode) external onlyOwner {
        wnsToEnsNodes[_wnsNode] = _ensNode;
        emit ENSNodeMapped(_wnsNode, _ensNode);
    }

    function resolveENS(bytes32 _wnsNode) public view returns (address) {
        bytes32 ensNode = wnsToEnsNodes[_wnsNode];
        require(ensNode != bytes32(0), "No ENS mapping for this WNS node");

        address resolver = ens.resolver(ensNode);
        require(resolver != address(0), "ENS resolver not found");

        return IENSResolver(resolver).addr(ensNode);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}