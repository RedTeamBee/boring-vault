# Boring Vault Architecture Documentation

## Overview

The Boring Vault architecture is a sophisticated DeFi vault system that provides flexible strategy execution while maintaining strong security guarantees through on-chain and off-chain mechanisms. The system is designed to prevent MEV attacks, provide multi-asset support, and enable complex cross-chain operations.

## Core Components

### 1. BoringVault
The core vault contract that holds assets and mints/burns shares. It's designed to be minimal and delegates complex functionality to external contracts.

**Key Features:**
- ERC20-compatible share token
- External management through `manage()` function
- Support for ERC721 and ERC1155 tokens
- Before-transfer hooks for additional logic

### 2. ManagerWithMerkleVerification
Controls what strategies the vault can execute using merkle tree verification.

**Security Model:**
- Each leaf contains: `(decoderAndSanitizer, target, valueNonZero, selector, packedAddressArguments)`
- Strategists have individual merkle trees for granular permissions
- Flash loan protection with intent verification
- Total supply must remain constant during strategy execution

### 3. TellerWithMultiAssetSupport
Handles user deposits and withdrawals with multi-asset support and MEV protection.

**MEV Protection Mechanisms:**
- Share locking period prevents flash loan arbitrage
- Permissioned withdrawals through atomic queues
- Deposit refund capability during lock period
- Deny lists for additional security

### 4. AccountantWithRateProviders
Manages exchange rates and fee calculations with manipulation resistance.

**Rate Protection:**
- Off-chain rate calculation
- Rate limiting and bound checking
- Automatic pause on suspicious rate changes
- Platform and performance fee management

## Security Features

### Merkle Tree Strategy Control
```
Leaf Structure:
keccak256(abi.encodePacked(
    decoderAndSanitizer,  // Contract to extract sensitive args
    target,               // Target contract address
    valueNonZero,         // Whether ETH can be sent
    selector,             // Function selector
    packedAddressArguments // Sensitive address arguments
))
```

### MEV Protection
1. **Share Locking**: Shares are locked to user address for configurable period
2. **Deposit Refunds**: Admins can refund deposits during lock period
3. **Permissioned Withdrawals**: Withdrawals go through atomic queues
4. **Rate Limiting**: Exchange rate updates are rate and bound limited

### Flash Loan Security
- Intent hash verification prevents replay attacks
- Only callable by vault during merkle-verified operations
- Automatic token transfer back to Balancer vault

## Cross-Chain Architecture

### Supported Chains
- Ethereum Mainnet
- Arbitrum
- Base
- Optimism
- Scroll
- Linea
- Mantle
- Zircuit

### Bridge Integrations
- Chainlink CCIP
- LayerZero
- Native bridge protocols
- Custom bridge implementations

## Integration Guide

### Adding New Protocols

1. **Create Decoder and Sanitizer Contract**
```solidity
contract YourProtocolDecoderAndSanitizer {
    function decodeAndSanitize(bytes calldata data) 
        external pure returns (bytes memory packedAddresses) {
        // Extract and validate sensitive arguments
        // Return packed address arguments
    }
}
```

2. **Add to Merkle Tree**
- Create leaf with your decoder/sanitizer address
- Include target contract address
- Specify function selector and allowed arguments

3. **Update Rate Provider** (if needed)
- Implement rate provider for new assets
- Configure in AccountantWithRateProviders

### Adding New Assets

1. **Configure in Teller**
```solidity
teller.updateAssetData(
    newAsset,
    true,  // allowDeposits
    true,  // allowWithdraws
    0      // sharePremium
);
```

2. **Set Rate Provider**
```solidity
accountant.setRateProviderData(
    newAsset,
    false,  // isPeggedToBase
    rateProviderAddress
);
```

## Gas Optimization

### Bulk Operations
- `bulkCompleteWithdraws()` for efficient batch processing
- Single transfer operations where possible
- Optimized storage access patterns

### Merkle Tree Efficiency
- Packed structs for gas efficiency
- Minimal storage operations
- Efficient proof verification

## Error Handling

### Custom Errors
All contracts use custom errors instead of require statements for gas efficiency:
```solidity
error ManagerWithMerkleVerification__InvalidManageProofLength();
error TellerWithMultiAssetSupport__SharesAreLocked();
```

### Pause Mechanisms
- Individual component pausing
- Emergency pause for critical issues
- Graceful degradation of functionality

## Monitoring and Events

### Key Events
- `WithdrawRequested(uint256 indexed nonce, address indexed account, ERC20 indexed asset, uint96 shares, uint40 maturity)`
- `BoringVaultManaged(uint256 callsMade)`
- `ExchangeRateUpdated(uint96 oldRate, uint96 newRate, uint64 currentTime)`

### Nonce System
- Sequential nonces for withdrawal requests
- Easy tracking and debugging
- Prevents replay attacks

## Best Practices

### For Integrators
1. Always verify merkle proofs before execution
2. Use appropriate share lock periods
3. Implement proper error handling
4. Monitor exchange rate updates

### For Users
1. Understand share lock periods
2. Check withdrawal delays
3. Monitor for deposit refunds
4. Use appropriate max loss settings

## Security Considerations

### Known Limitations
1. Share lock period can be reduced by admin
2. Exchange rate manipulation possible if bounds are too wide
3. Flash loan attacks possible if merkle tree is compromised

### Mitigation Strategies
1. Conservative rate bounds
2. Regular merkle tree updates
3. Multi-signature requirements for critical operations
4. Comprehensive monitoring and alerting

## Future Improvements

### Planned Features
1. Multicall support for complex operations
2. Enhanced bulk operations
3. Improved gas optimization
4. Additional bridge integrations
5. Advanced MEV protection mechanisms

### Research Areas
1. Zero-knowledge proof integration
2. Cross-chain atomic operations
3. Advanced strategy composition
4. Dynamic fee structures