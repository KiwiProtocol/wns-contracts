// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract WNSFeeDistribution is Initializable, AccessControlUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    using SafeMathUpgradeable for uint256;

    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    struct ShareHolder {
        address payable wallet;
        uint256 share; // Out of 10000 (100%)
    }

    ShareHolder[] public shareHolders;
    uint256 public totalShares;

    event ShareHolderAdded(address indexed wallet, uint256 share);
    event ShareHolderRemoved(address indexed wallet);
    event ShareUpdated(address indexed wallet, uint256 newShare);
    event FeesDistributed(uint256 amount);
    event ERC20FeesDistributed(address indexed token, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DISTRIBUTOR_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
    }

    function addShareHolder(address payable _wallet, uint256 _share) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_wallet != address(0), "Invalid wallet address");
        require(_share > 0 && _share <= 10000, "Invalid share value");
        require(totalShares.add(_share) <= 10000, "Total shares exceed 100%");

        shareHolders.push(ShareHolder({
            wallet: _wallet,
            share: _share
        }));
        totalShares = totalShares.add(_share);

        emit ShareHolderAdded(_wallet, _share);
    }

    function removeShareHolder(uint256 _index) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_index < shareHolders.length, "Invalid index");

        totalShares = totalShares.sub(shareHolders[_index].share);
        emit ShareHolderRemoved(shareHolders[_index].wallet);

        shareHolders[_index] = shareHolders[shareHolders.length - 1];
        shareHolders.pop();
    }

    function updateShare(uint256 _index, uint256 _newShare) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_index < shareHolders.length, "Invalid index");
        require(_newShare > 0 && _newShare <= 10000, "Invalid share value");

        uint256 oldShare = shareHolders[_index].share;
        shareHolders[_index].share = _newShare;
        totalShares = totalShares.sub(oldShare).add(_newShare);

        require(totalShares <= 10000, "Total shares exceed 100%");

        emit ShareUpdated(shareHolders[_index].wallet, _newShare);
    }

    function distributeFees() external payable onlyRole(DISTRIBUTOR_ROLE) whenNotPaused {
        require(msg.value > 0, "No fees to distribute");
        require(totalShares == 10000, "Shares do not total 100%");

        for (uint256 i = 0; i < shareHolders.length; i++) {
            uint256 amount = msg.value.mul(shareHolders[i].share).div(10000);
            shareHolders[i].wallet.transfer(amount);
        }

        emit FeesDistributed(msg.value);
    }

    function distributeERC20Fees(address _token, uint256 _amount) external onlyRole(DISTRIBUTOR_ROLE) whenNotPaused {
        require(_amount > 0, "No fees to distribute");
        require(totalShares == 10000, "Shares do not total 100%");

        IERC20Upgradeable token = IERC20Upgradeable(_token);
        require(token.balanceOf(address(this)) >= _amount, "Insufficient token balance");

        for (uint256 i = 0; i < shareHolders.length; i++) {
            uint256 amount = _amount.mul(shareHolders[i].share).div(10000);
            require(token.transfer(shareHolders[i].wallet, amount), "Token transfer failed");
        }

        emit ERC20FeesDistributed(_token, _amount);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    receive() external payable {}
}