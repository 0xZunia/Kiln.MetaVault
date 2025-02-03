---
title: Nlik
author: souhoc, ReyanCarlier, noegrx
date: 31/01/2025
---

Hackathon #1 2025 - Hosted by [Kiln](https://kiln.fi)

We placed 3rd in category DeFi !

## Currently Deployed Contracts

### MetaVaultFactory
- **Address**: [0x9f2aFA649C0b23661fB51D12ba6fFc552E675507](https://sepolia.etherscan.io/address/0x9f2afa649c0b23661fb51d12ba6ffc552e675507)

### MetaVault (PersonalMetaVault DEMO)
- **Address**: [0xB73E64c9668B817eDdAD358eAa6FDE43C4dCdB85](https://sepolia.etherscan.io/address/0xB73E64c9668B817eDdAD358eAa6FDE43C4dCdB85)

### Transaction History :
- **Initialize MetaVault**: TX. [0x5cc77f5c10366ffb790bebf61ea9bb76bb000632c5c7b4e0c85ffe493ce93eea](https://sepolia.etherscan.io/tx/0x5cc77f5c10366ffb790bebf61ea9bb76bb000632c5c7b4e0c85ffe493ce93eea)
- **Add Kiln Vault on DEMO MetaVault ([0xdea01fc5289af2c440ca65582e3c44767c0fcf08](https://sepolia.etherscan.io/address/0xdea01fc5289af2c440ca65582e3c44767c0fcf08))** : TX. [0x5b4443866a0a5ce08202d6ad553feba0fd8348ff3f2d1cc3a8c233f0da539a97](https://sepolia.etherscan.io/tx/0x5b4443866a0a5ce08202d6ad553feba0fd8348ff3f2d1cc3a8c233f0da539a97)


# MetaVault System

## Overview

The MetaVault System is a sophisticated DeFi solution designed to optimize asset management across multiple Kiln vaults. It enables users to efficiently manage their portfolio allocations, automate rebalancing, and maximize returns while maintaining strict security standards.

## Key Features

### Portfolio Management
- Multi-vault asset allocation
- Automated rebalancing
- Performance tracking
- Daily limits and security measures
- Optimized deposit and withdrawal strategies

### Security
- Reentrancy protection
- Daily transaction limits
- Slippage control
- Access control system
- Performance monitoring

## System Architecture

### Core Components

1. **PersonalMetaVault**
    - Manages individual user portfolios
    - Handles asset allocation across multiple vaults
    - Implements performance tracking
    - Controls deposit and withdrawal operations

2. **PersonalMetaVaultFactory**
    - Deploys new meta vaults
    - Maintains registry of user vaults
    - Implements access control

### Integration with Kiln Vaults

The system is designed to work seamlessly with Kiln's vault infrastructure:
- Direct integration with Kiln vault contracts
- Adherence to ERC4626 tokenized vault standard
- Compatible with Kiln's security measures

## Getting Started

### Prerequisites
- Ethereum development environment
- Solidity ^0.8.22
- OpenZeppelin contracts
- Access to Kiln vault system

### Deployment Process

1. Deploy the Factory:
```solidity
PersonalMetaVaultFactory factory = new PersonalMetaVaultFactory();
factory.initialize(admin, initialDelay);
```

2. Create a Personal MetaVault:
```solidity
address metaVault = factory.createMetaVault();
```

3. Configure Vault Allocations:
```solidity
PersonalMetaVault vault = PersonalMetaVault(metaVault);
vault.addVault(vaultAddress1, 5000); // 50%
vault.addVault(vaultAddress2, 5000); // 50%
```

### Usage Examples

1. Depositing Assets:
```solidity
IERC20(token).approve(metaVault, amount);
vault.deposit(token, amount);
```

2. Withdrawing Assets:
```solidity
vault.withdraw(percentage); // percentage in basis points (100 = 1%)
```

3. Rebalancing Portfolio:
```solidity
vault.rebalance();
```

## Advanced Features

### Performance Tracking
The system includes comprehensive performance tracking:
- APR calculations
- TVL monitoring
- Utilization rates
- Historical performance data

### Optimization Strategies
Implements various optimization strategies:
- Smart deposit distribution
- Efficient rebalancing
- Gas optimization
- Slippage protection

## Security Measures

### Transaction Limits
- Daily limits per user
- Volume tracking
- Time-based restrictions

### Access Control
- Owner-only functions
- Factory controls
- Role-based permissions

### Protection Mechanisms
- Slippage checks
- Reentrancy guards
- Input validation
- Emergency stops

## Technical Specifications

### Constants
```solidity
MAX_BPS = 10000          // Base points for percentage calculations
REBALANCE_THRESHOLD = 500 // 5% threshold for rebalancing
MAX_SLIPPAGE = 100       // 1% maximum slippage allowed
```

### Key Structures
```solidity
struct VaultAllocation {
    address vault;
    uint256 allocation;
    bool active;
    uint256 lastUpdateTime;
    uint256 lastBalance;
    uint256 lastPrice;
}

struct VaultPerformance {
    uint256 apr;
    uint256 tvl;
    uint256 utilizationRate;
}
```

## Best Practices

### Deployment
1. Always initialize with appropriate admin controls
2. Set reasonable initial limits
3. Verify vault compatibility before adding
4. Test with small amounts first

### Operation
1. Regular monitoring of performance metrics
2. Periodic review of allocation strategies
3. Gradual scaling of transaction limits
4. Regular security audits

## Known Limitations

1. Gas costs may be high during rebalancing
2. Performance tracking requires active management
3. Slippage impact on large transactions
4. Network congestion effects

## Future Improvements

1. Enhanced optimization algorithms
2. More sophisticated performance metrics
3. Additional security features
4. Gas optimization improvements

