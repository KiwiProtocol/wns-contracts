// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract WNSPricingOracle is Initializable, AccessControlUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    using SafeMathUpgradeable for uint256;

    bytes32 public constant PRICER_ROLE = keccak256("PRICER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    AggregatorV3Interface internal ethUsdPriceFeed;

    struct PriceConfig {
        uint256 basePrice;
        uint256 perCharPrice;
        uint256 premiumMultiplier;
    }

    PriceConfig public priceConfig;
    mapping(uint256 => uint256) public chainPriceMultipliers;

    event PriceConfigUpdated(uint256 basePrice, uint256 perCharPrice, uint256 premiumMultiplier);
    event ChainPriceMultiplierUpdated(uint256 chainId, uint256 multiplier);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _ethUsdPriceFeed) public initializer {
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PRICER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);

        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);

        priceConfig = PriceConfig({
            basePrice: 5 * 10**18, // 5 USD in Wei
            perCharPrice: 1 * 10**17, // 0.1 USD in Wei
            premiumMultiplier: 2
        });
    }

    function setPriceConfig(uint256 _basePrice, uint256 _perCharPrice, uint256 _premiumMultiplier) external onlyRole(PRICER_ROLE) {
        priceConfig = PriceConfig({
            basePrice: _basePrice,
            perCharPrice: _perCharPrice,
            premiumMultiplier: _premiumMultiplier
        });
        emit PriceConfigUpdated(_basePrice, _perCharPrice, _premiumMultiplier);
    }

    function setChainPriceMultiplier(uint256 _chainId, uint256 _multiplier) external onlyRole(PRICER_ROLE) {
        chainPriceMultipliers[_chainId] = _multiplier;
        emit ChainPriceMultiplierUpdated(_chainId, _multiplier);
    }

    function calculatePrice(string memory _name, uint256 _chainId, bool _isPremium) public view returns (uint256) {
        uint256 length = bytes(_name).length;
        uint256 price = priceConfig.basePrice.add(priceConfig.perCharPrice.mul(length));

        if (_isPremium) {
            price = price.mul(priceConfig.premiumMultiplier);
        }

        uint256 chainMultiplier = chainPriceMultipliers[_chainId];
        if (chainMultiplier > 0) {
            price = price.mul(chainMultiplier).div(100);
        }

        return price;
    }

    function getEthUsdPrice() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        return uint256(price);
    }

    function calculatePriceInEth(string memory _name, uint256 _chainId, bool _isPremium) public view returns (uint256) {
        uint256 priceInUsd = calculatePrice(_name, _chainId, _isPremium);
        uint256 ethUsdPrice = getEthUsdPrice();
        return priceInUsd.mul(1e8).div(ethUsdPrice);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}
}