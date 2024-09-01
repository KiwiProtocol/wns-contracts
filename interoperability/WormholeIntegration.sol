// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

interface IWormhole {
    function publishMessage(uint32 nonce, bytes memory payload, uint8 consistencyLevel) external payable returns (uint64 sequence);
    function parseAndVerifyVM(bytes memory encodedVM) external view returns (IWormhole.VM memory vm, bool valid, string memory reason);

    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;
        uint32 guardianSetIndex;
        bytes signatures;
        bytes32 hash;
    }
}

contract WNSWormholeIntegration is Initializable, OwnableUpgradeable, PausableUpgradeable {
    IWormhole public wormhole;
    mapping(uint16 => bytes32) public trustedEmitters;

    event MessageSent(uint16 targetChain, bytes payload);
    event MessageReceived(uint16 sourceChain, bytes payload);

    function initialize(address _wormhole) public initializer {
        __Ownable_init();
        __Pausable_init();
        wormhole = IWormhole(_wormhole);
    }

    function sendMessage(uint16 targetChain, bytes memory payload) external payable whenNotPaused {
        require(msg.value > 0, "Must pay for message fee");
        
        uint64 sequence = wormhole.publishMessage{value: msg.value}(
            0, // nonce
            payload,
            1  // consistency level
        );

        emit MessageSent(targetChain, payload);
    }

    function receiveMessage(bytes memory encodedVM) external whenNotPaused {
        (IWormhole.VM memory vm, bool valid, string memory reason) = wormhole.parseAndVerifyVM(encodedVM);
        
        require(valid, reason);
        require(trustedEmitters[vm.emitterChainId] == vm.emitterAddress, "Not a trusted emitter");

        // Process the message payload
        emit MessageReceived(vm.emitterChainId, vm.payload);
    }

    function setTrustedEmitter(uint16 chainId, bytes32 emitterAddress) external onlyOwner {
        trustedEmitters[chainId] = emitterAddress;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}