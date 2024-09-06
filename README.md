# wns
Wormhole Name Service (WNS) is the first ever multichain naming system designed to provide a unified, user-friendly way to interact with blockchain addresses and decentralized resources across all blockchains using the Wormhole interoperability protocol.


## Technical Description
The WNS smart contracts are designed to manage name registration, resolution, and ownership of blockchain addresses. Built with cross-chain compatibility in mind, these contracts leverage the Wormhole interoperability protocol to synchronize data across multiple blockchains.


### Key Features:
- **Cross-chain compatibility:** WNS enables seamless name resolution across multiple blockchains using Wormhole.
- **Decentralized management:** Users can register and manage names without relying on a centralized entity.
- **Security and Privacy:** The contracts implement security features such as multi-signature, time-locked operations, and optional encryption.
- **Flexible resource mapping:** Names can be associated with blockchain addresses, IPFS hashes, program IDs, and other records.


## Contract Structure

### 1. Core Contracts
- **ChainRegistry.sol**: Handles domain registration and management across different EVM-compatible blockchains.
- **CrossChainSync.sol**: Ensures synchronization of name records across chains using Wormhole.
- **RootRegistry.sol**: Manages top-level domains (TLDs) and global WNS configurations.

### 2. Economic Contracts
- **FeeDistribution.sol**: Distributes fees collected from name registrations and renewals to incentivize validators and infrastructure providers.
- **PricingOracle.sol**: Manages dynamic pricing of domain names based on factors such as demand and name length.
- **Treasury.sol**: Stores and manages funds for the WNS ecosystem.

### 3. Governance Contracts
- **Governance.sol**: Implements DAO-based governance, allowing WNS stakeholders to vote on protocol upgrades and changes.

### 4. Interoperability Contracts
- **Abstraction.sol**: Provides an abstraction layer for cross-chain interactions, simplifying integration with multiple blockchains.
- **WormholeIntegration.sol**: Interfaces with the Wormhole protocol for cross-chain messaging and synchronization.
- **ens.sol**: Compatibility module for interacting with Ethereum Name Service (ENS) and ensuring bidirectional resolution.

### 5. Resolver Contracts
- **MultichainResolvers.sol**: Resolves names to blockchain addresses and resources on supported networks.
- **ReverseResolver.sol**: Handles reverse lookups (address to name), ensuring consistency across chains.
- **WildcardResolver.sol**: Supports wildcard domain resolution and pattern matching.

### 6. Security Contracts
- **AccessControl.sol**: Manages role-based access control and permissions for critical WNS operations.
- **SecurityModule.sol**: Implements security features such as time-locked operations and multi-signature authorization for sensitive actions.

### 7. Storage Contracts
- **CachingLayer.sol**: Implements a distributed caching layer to reduce on-chain queries and enhance performance.
- **OffchainStorage.sol**: Uses decentralized storage solutions (like IPFS) for storing large datasets off-chain.
- **OnchainStorage.sol**: Manages on-chain storage for critical WNS data, optimized for speed and scalability.



## Architecture

WNS is designed as a modular, cross-chain solution that can interact with multiple blockchains through the Wormhole protocol. Here’s a high-level view of the architecture:

1. **Root Registry Contract**: Deployed on Ethereum and manages the top-level domains (TLDs).
2. **Subdomain Registrar**: Deployed on each EVM-compatible chain and manages second-level domain registrations.
3. **Resolver Contracts**: These contracts map WNS names to blockchain addresses, decentralized storage, and other resources.
4. **Cross-Chain Integration**: Through Wormhole's interoperability layer, data between chains remains synchronized, ensuring that names can be resolved across multiple networks.
5. **Governance**: Decentralized governance via a DAO, ensuring protocol upgrades and modifications are done transparently and securely.

### Architecture Diagram

```
+----------------------+      +----------------------+
|  Root Registry (ETH) | ---> | Subdomain Registrar   |
+----------------------+      +----------------------+
         |                             |
         v                             v
+----------------------+      +----------------------+
|  Cross-Chain Bridge  | ---> | Resolver Contracts   |
| (Wormhole Integration)|     +----------------------+
+----------------------+
```

## Prerequisites
To compile, deploy, and run the WNS contracts locally, you'll need:
- [Node.js](https://nodejs.org/en/download/) (v12.x or higher)
- [Hardhat](https://hardhat.org/getting-started/)
- [Wormhole SDK](https://wormhole.com/reference/sdk/)
- [Git](https://git-scm.com/)
- A local Ethereum blockchain like [Hardhat Network](https://hardhat.org/hardhat-network/)

## Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/wns-contracts.git
cd wns-contracts
```

### 2. Install Dependencies
Install Hardhat and all necessary dependencies:
```bash
npm install
```

### 3. Configure Environment Variables
Create a `.env` file in the root directory and add the following variables for network configuration:
```bash
INFURA_API_KEY=your-infura-api-key
PRIVATE_KEY=your-wallet-private-key
ETHERSCAN_API_KEY=your-etherscan-api-key
```

### 4. Compile the Contracts
To compile the contracts, use Hardhat’s compile command:
```bash
npx hardhat compile
```

### 5. Deploy Contracts Locally
You can deploy the contracts on a local Hardhat network by running the following command:
```bash
npx hardhat node
```
In a separate terminal, deploy the contracts:
```bash
npx hardhat run scripts/deploy.js --network localhost
```

### 6. Deploy to a Testnet (e.g., Goerli)
Ensure you have some test ETH on Goerli, then run:
```bash
npx hardhat run scripts/deploy.js --network goerli
```

### 7. Verify Contracts on Etherscan
Once deployed, you can verify the contracts on Etherscan:
```bash
npx hardhat verify --network goerli DEPLOYED_CONTRACT_ADDRESS "Constructor Arguments"
```

## Running Tests
You can run the test suite using Hardhat:
```bash
npx hardhat test
```




