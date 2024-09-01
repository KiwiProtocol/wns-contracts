// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract WNSWildcardResolver is Initializable, OwnableUpgradeable, PausableUpgradeable {
    struct WildcardResolution {
        string pattern;
        string resolution;
    }

    mapping(bytes32 => WildcardResolution[]) private wildcardResolutions;

    event WildcardAdded(bytes32 indexed node, string pattern, string resolution);
    event WildcardRemoved(bytes32 indexed node, string pattern);

    function initialize() public initializer {
        __Ownable_init();
        __Pausable_init();
    }

    function addWildcard(bytes32 _node, string calldata _pattern, string calldata _resolution) external onlyOwner whenNotPaused {
        wildcardResolutions[_node].push(WildcardResolution(_pattern, _resolution));
        emit WildcardAdded(_node, _pattern, _resolution);
    }

    function removeWildcard(bytes32 _node, string calldata _pattern) external onlyOwner whenNotPaused {
        WildcardResolution[] storage resolutions = wildcardResolutions[_node];
        for (uint i = 0; i < resolutions.length; i++) {
            if (keccak256(bytes(resolutions[i].pattern)) == keccak256(bytes(_pattern))) {
                resolutions[i] = resolutions[resolutions.length - 1];
                resolutions.pop();
                emit WildcardRemoved(_node, _pattern);
                break;
            }
        }
    }

    function resolveWildcard(bytes32 _node, string calldata _name) public view returns (string memory) {
        WildcardResolution[] memory resolutions = wildcardResolutions[_node];
        for (uint i = 0; i < resolutions.length; i++) {
            if (matchWildcard(resolutions[i].pattern, _name)) {
                return resolutions[i].resolution;
            }
        }
        return "";
    }

    function matchWildcard(string memory _pattern, string memory _name) private pure returns (bool) {
        bytes memory pattern = bytes(_pattern);
        bytes memory name = bytes(_name);
        
        if (pattern.length == 0) return name.length == 0;
        
        bool[256] memory dp = [true];
        
        for (uint j = 1; j <= pattern.length; j++) {
            if (pattern[j-1] == '*') 
                dp[j] = dp[j-1];
        }
        
        for (uint i = 1; i <= name.length; i++) {
            bool[] memory temp = new bool[](pattern.length + 1);
            for (uint j = 1; j <= pattern.length; j++) {
                if (pattern[j-1] == '*') {
                    temp[j] = dp[j-1] || temp[j-1] || (j > 1 && dp[j]);
                } else if (pattern[j-1] == '?' || pattern[j-1] == name[i-1]) {
                    temp[j] = dp[j-1];
                }
            }
            dp = temp;
        }
        
        return dp[pattern.length];
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}