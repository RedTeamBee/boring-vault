# Boring Vault Integration Guide

## Table of Contents
1. [Quick Start](#quick-start)
2. [Core Concepts](#core-concepts)
3. [Adding New Protocols](#adding-new-protocols)
4. [Adding New Assets](#adding-new-assets)
5. [Cross-Chain Integration](#cross-chain-integration)
6. [Testing Your Integration](#testing-your-integration)
7. [Deployment Guide](#deployment-guide)
8. [Best Practices](#best-practices)

## Quick Start

### Prerequisites
- Foundry installed
- Node.js 16+
- Access to RPC endpoints for target chains

### Basic Setup
```bash
# Clone the repository
git clone <repository-url>
cd boring-vault

# Install dependencies
forge install

# Copy environment file
cp sample.env .env
# Edit .env with your RPC URLs

# Run tests
forge test
```

## Core Concepts

### Architecture Overview
The Boring Vault system consists of four main components:

1. **BoringVault**: Core vault contract
2. **ManagerWithMerkleVerification**: Strategy execution control
3. **TellerWithMultiAssetSupport**: User interaction layer
4. **AccountantWithRateProviders**: Rate and fee management

### Key Principles
- **Security First**: All operations are verified through merkle trees
- **MEV Protection**: Share locking and permissioned withdrawals
- **Multi-Asset Support**: Deposit/withdraw in various assets
- **Cross-Chain Ready**: Built-in bridge integrations

## Adding New Protocols

### Step 1: Create Decoder and Sanitizer

Create a new contract that implements the decoder pattern:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {RawDataDecoderAndSanitizerInterfaces} from "src/interfaces/RawDataDecoderAndSanitizerInterfaces.sol";

contract YourProtocolDecoderAndSanitizer is RawDataDecoderAndSanitizerInterfaces {
    address public immutable target;
    
    constructor(address _target) {
        target = _target;
    }
    
    function decodeAndSanitize(bytes calldata data) 
        external pure returns (bytes memory packedAddresses) {
        // Extract function selector
        bytes4 selector = bytes4(data[0:4]);
        
        // Validate selector
        require(selector == YourProtocol.yourFunction.selector, "Invalid selector");
        
        // Extract and validate address arguments
        // Example: if function takes (address token, address recipient)
        address token = abi.decode(data[4:36], (address));
        address recipient = abi.decode(data[36:68], (address));
        
        // Validate addresses (e.g., not zero address, not contract address)
        require(token != address(0), "Invalid token address");
        require(recipient != address(0), "Invalid recipient address");
        
        // Return packed addresses
        return abi.encodePacked(token, recipient);
    }
}
```

### Step 2: Add to Merkle Tree

Create a leaf for your protocol:

```javascript
// Example leaf creation
const leaf = keccak256(abi.encodePacked(
    decoderAndSanitizerAddress,  // Your decoder contract
    targetAddress,               // Protocol contract address
    valueNonZero,                // Whether ETH can be sent
    selector,                    // Function selector
    packedAddressArguments       // Packed address arguments
));
```

### Step 3: Update Manager

```solidity
// Set the new merkle root
manager.setManageRoot(strategistAddress, newMerkleRoot);
```

### Step 4: Test Integration

```solidity
// Test the integration
function testYourProtocolIntegration() public {
    // Setup test environment
    // Create merkle proof
    // Execute strategy
    // Verify results
}
```

## Adding New Assets

### Step 1: Configure Teller

```solidity
// Enable asset for deposits and withdrawals
teller.updateAssetData(
    newAsset,           // ERC20 token address
    true,               // allowDeposits
    true,               // allowWithdraws
    0                   // sharePremium (0 = no premium)
);
```

### Step 2: Set Rate Provider

```solidity
// Configure rate provider
accountant.setRateProviderData(
    newAsset,           // ERC20 token address
    false,              // isPeggedToBase
    rateProviderAddress // Rate provider contract
);
```

### Step 3: Create Rate Provider (if needed)

```solidity
contract YourAssetRateProvider is IRateProvider {
    function getRate() external view returns (uint256) {
        // Return rate in terms of base asset
        // Must use same decimals as the asset
    }
}
```

## Cross-Chain Integration

### Supported Bridges

1. **Chainlink CCIP**
2. **LayerZero**
3. **Native Bridges** (Arbitrum, Optimism, etc.)

### Adding New Bridge

1. **Create Bridge Teller**:
```solidity
contract YourBridgeTeller is CrossChainTellerWithGenericBridge {
    constructor(
        address _owner,
        address _vault,
        address _accountant,
        address _bridge
    ) CrossChainTellerWithGenericBridge(_owner, _vault, _accountant, _bridge) {}
}
```

2. **Implement Bridge Interface**:
```solidity
interface IYourBridge {
    function sendMessage(bytes calldata message) external payable;
    function receiveMessage(bytes calldata message) external;
}
```

3. **Deploy and Configure**:
```solidity
// Deploy bridge teller
YourBridgeTeller bridgeTeller = new YourBridgeTeller(
    owner,
    vault,
    accountant,
    bridgeAddress
);

// Configure cross-chain messaging
bridgeTeller.setMessageLib(messageLibAddress);
```

## Testing Your Integration

### Unit Tests

```solidity
contract YourIntegrationTest is Test {
    function setUp() public {
        // Setup test environment
        // Deploy contracts
        // Configure roles
    }
    
    function testDeposit() public {
        // Test deposit functionality
    }
    
    function testWithdraw() public {
        // Test withdrawal functionality
    }
    
    function testStrategyExecution() public {
        // Test strategy execution
    }
}
```

### Integration Tests

```solidity
contract YourProtocolIntegrationTest is Test {
    function testFullFlow() public {
        // 1. Setup
        // 2. Deposit
        // 3. Execute strategy
        // 4. Withdraw
        // 5. Verify results
    }
}
```

### Fork Tests

```solidity
contract YourProtocolForkTest is Test {
    function setUp() public {
        // Fork mainnet at specific block
        vm.createSelectFork("mainnet", 18000000);
    }
    
    function testOnMainnet() public {
        // Test with real mainnet state
    }
}
```

## Deployment Guide

### 1. Prepare Environment

```bash
# Set up environment variables
export MAINNET_RPC_URL="your-mainnet-rpc"
export ARBITRUM_RPC_URL="your-arbitrum-rpc"
# ... other chains
```

### 2. Deploy Core Contracts

```solidity
// Deploy script
contract DeployYourVault is Script {
    function run() external {
        // Deploy BoringVault
        BoringVault vault = new BoringVault(owner, "Vault Name", "SYMBOL", 18);
        
        // Deploy Accountant
        AccountantWithRateProviders accountant = new AccountantWithRateProviders(
            owner,
            address(vault),
            payoutAddress,
            startingExchangeRate,
            baseAsset,
            upperBound,
            lowerBound,
            updateDelay,
            platformFee,
            performanceFee
        );
        
        // Deploy Teller
        TellerWithMultiAssetSupport teller = new TellerWithMultiAssetSupport(
            owner,
            address(vault),
            address(accountant),
            wethAddress
        );
        
        // Deploy Manager
        ManagerWithMerkleVerification manager = new ManagerWithMerkleVerification(
            owner,
            address(vault),
            balancerVaultAddress
        );
    }
}
```

### 3. Configure Roles

```solidity
// Set up role-based access control
RolesAuthority authority = new RolesAuthority(owner, Authority(address(0)));

// Configure vault roles
vault.setAuthority(authority);
authority.setRoleCapability(MINTER_ROLE, address(vault), vault.enter.selector, true);
authority.setRoleCapability(BURNER_ROLE, address(vault), vault.exit.selector, true);

// Configure teller roles
teller.setAuthority(authority);
authority.setRoleCapability(ADMIN_ROLE, address(teller), teller.updateAssetData.selector, true);

// Configure manager roles
manager.setAuthority(authority);
authority.setRoleCapability(STRATEGIST_ROLE, address(manager), manager.manageVaultWithMerkleVerification.selector, true);
```

### 4. Deploy to Multiple Chains

```bash
# Deploy to mainnet
forge script script/DeployYourVault.s.sol --rpc-url mainnet --broadcast

# Deploy to Arbitrum
forge script script/DeployYourVault.s.sol --rpc-url arbitrum --broadcast

# Deploy to Base
forge script script/DeployYourVault.s.sol --rpc-url base --broadcast
```

## Best Practices

### Security
1. **Always verify merkle proofs** before execution
2. **Use appropriate share lock periods** for your use case
3. **Implement comprehensive error handling**
4. **Regular security audits** and reviews
5. **Monitor for suspicious activity**

### Gas Optimization
1. **Use bulk operations** when possible
2. **Optimize storage access patterns**
3. **Minimize external calls**
4. **Use appropriate data types**

### Testing
1. **Comprehensive unit tests** for all functions
2. **Integration tests** for full workflows
3. **Fork tests** with real chain state
4. **Fuzz testing** for edge cases
5. **Invariant testing** for system properties

### Monitoring
1. **Event logging** for all important operations
2. **Rate monitoring** for exchange rate changes
3. **Volume tracking** for deposits/withdrawals
4. **Error rate monitoring** for failed transactions
5. **Gas usage tracking** for optimization

### Documentation
1. **Clear code comments** explaining complex logic
2. **Comprehensive README** files
3. **API documentation** for external interfaces
4. **Integration examples** for common use cases
5. **Troubleshooting guides** for common issues

## Common Issues and Solutions

### Issue: Merkle Proof Verification Fails
**Solution**: Ensure the leaf is constructed correctly with all required parameters.

### Issue: Exchange Rate Updates Revert
**Solution**: Check rate bounds and update delay settings.

### Issue: Share Transfers Fail
**Solution**: Verify share lock period and deny list settings.

### Issue: Cross-Chain Messages Fail
**Solution**: Check bridge configuration and message format.

## Support and Resources

### Documentation
- [Architecture Documentation](./ARCHITECTURE.md)
- [Security Considerations](./SECURITY.md)
- [API Reference](./API.md)

### Community
- Discord: [Community Server]
- GitHub: [Repository Issues]
- Twitter: [@VedaProtocol]

### Professional Support
- Email: support@veda.tech
- Consulting: consulting@veda.tech
- Security: security@veda.tech

---

*This guide is regularly updated. Last updated: [Current Date]*