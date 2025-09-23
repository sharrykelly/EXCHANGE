# Decentralized Exchange (DEX) on Clarity

A comprehensive decentralized exchange smart contract built with Clarity for the Stacks blockchain. This DEX supports SIP-010 token swaps, automated market maker (AMM) pools, liquidity provision, and staking rewards for liquidity providers.

## 🌟 Features

### Core Trading Functions
- **Token Swaps**: Swap between any SIP-010 compliant tokens using AMM pricing
- **Liquidity Pools**: Create and manage trading pairs with automated market making
- **AMM (xy=k)**: Constant product formula ensures fair and efficient pricing
- **LP Tokens**: Receive fungible LP tokens representing pool ownership shares

### Advanced Features
- **Staking Rewards**: Earn block-based rewards for providing liquidity
- **Slippage Protection**: Built-in minimum amount guarantees for all trades
- **Fee Collection**: 0.3% trading fees distributed to liquidity providers
- **Pool Management**: Comprehensive pool creation and state tracking

### Security & Validation
- **Reentrancy Protection**: Guards against recursive call attacks
- **Input Validation**: Comprehensive bounds checking and contract validation
- **Safe Math**: Overflow protection and mathematical safety checks
- **Access Controls**: Owner-only functions for critical parameters

## 📋 Contract Functions

### Public Functions

#### Pool Management
```clarity
(define-public (create-pool (token-a <sip-010-trait>) (token-b <sip-010-trait>)))
```
Create a new trading pool for a token pair.

#### Liquidity Operations
```clarity
(define-public (add-liquidity 
  (token-a <sip-010-trait>) 
  (token-b <sip-010-trait>)
  (amount-a-desired uint)
  (amount-b-desired uint)
  (amount-a-min uint)
  (amount-b-min uint)))
```
Add liquidity to an existing pool and receive LP tokens.

```clarity
(define-public (remove-liquidity
  (token-a <sip-010-trait>)
  (token-b <sip-010-trait>)
  (liquidity uint)
  (amount-a-min uint)
  (amount-b-min uint)))
```
Remove liquidity from a pool by burning LP tokens.

#### Trading
```clarity
(define-public (swap-tokens
  (token-in <sip-010-trait>)
  (token-out <sip-010-trait>)
  (amount-in uint)
  (amount-out-min uint)))
```
Swap tokens using the automated market maker.

#### Rewards
```clarity
(define-public (claim-rewards 
  (token-a <sip-010-trait>) 
  (token-b <sip-010-trait>)))
```
Claim accumulated staking rewards for liquidity provision.

#### Admin Functions
```clarity
(define-public (set-reward-rate (new-rate uint)))
```
Update the reward rate (owner only).

### Read-Only Functions

#### Pool Information
```clarity
(define-read-only (get-pool-info (token-a principal) (token-b principal)))
(define-read-only (get-liquidity-provider-info (token-a principal) (token-b principal) (provider principal)))
(define-read-only (get-total-pools))
```

#### Price Calculations
```clarity
(define-read-only (get-swap-amount-out (token-a principal) (token-b principal) (amount-in uint)))
(define-read-only (get-swap-amount-in (token-a principal) (token-b principal) (amount-out uint)))
(define-read-only (calculate-liquidity-amounts (token-a principal) (token-b principal) (amount-a-desired uint) (amount-b-desired uint)))
```

#### Rewards & Balances
```clarity
(define-read-only (get-pending-rewards (token-a principal) (token-b principal) (provider principal)))
(define-read-only (get-lp-balance (user principal)))
(define-read-only (get-total-lp-supply))
(define-read-only (get-reward-rate))
```

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Node.js and npm for testing
- SIP-010 compliant token contracts

### Installation
```bash
# Clone the repository
git clone <repository-url>
cd decen_exchange

# Install dependencies
npm install
```

### Development
```bash
# Check contract syntax
clarinet check

# Run tests
npm test

# Start Clarinet console for interaction
clarinet console
```

### Deployment
```bash
# Deploy to devnet
clarinet deploy --devnet

# Deploy to testnet
clarinet deploy --testnet
```

## 🔧 Configuration

### Network Settings
Configuration files are located in the `settings/` directory:
- `Devnet.toml` - Development network settings
- `Testnet.toml` - Testnet configuration  
- `Mainnet.toml` - Mainnet configuration

### Contract Parameters
- **Fee Rate**: 0.3% (300/100000)
- **Minimum Liquidity**: 1000 units
- **Default Reward Rate**: 100 tokens per block

## 🧪 Testing

Run the comprehensive test suite:
```bash
npm test
```

Tests cover:
- Pool creation and management
- Liquidity addition/removal scenarios
- Token swapping with various amounts
- Reward calculation and distribution
- Security validations and edge cases

## 🔒 Security Features

### Input Validation
- All token contracts validated as SIP-010 compliant
- Numeric inputs checked for reasonable bounds
- Slippage parameters validated for consistency

### Reentrancy Protection
- Global reentrancy guard prevents recursive calls
- State changes committed before external calls
- Consistent error handling and rollback

### Access Controls
- Owner-only functions for critical parameters
- Validation of token contract authenticity
- Prevention of self-referencing attacks

## 📊 Economics

### Trading Fees
- **Swap Fee**: 0.3% of input amount
- **Fee Distribution**: Fees remain in pools to benefit LP providers
- **Fee Calculation**: Applied before AMM pricing calculation

### Liquidity Rewards
- **Block-based**: Rewards calculated per Stacks block
- **Proportional**: Distributed based on LP token ownership
- **Configurable**: Reward rate adjustable by contract owner

### AMM Pricing
- **Formula**: Constant product (x × y = k)
- **Slippage**: Automatic price impact based on trade size
- **Arbitrage**: Price discovery through arbitrage opportunities

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

For questions and support:
- Create an issue on GitHub
- Check the [Clarity documentation](https://docs.stacks.co/clarity)
- Join the [Stacks Discord](https://discord.gg/stacks)
