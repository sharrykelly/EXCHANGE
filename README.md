# Decentralized Exchange (DEX) on Clarity

A comprehensive decentralized exchange smart contract built with Clarity for the Stacks blockchain. This DEX supports SIP-010 token swaps, automated market maker (AMM) pools, liquidity provision, and staking rewards for liquidity providers.

## ✨ What's New

### Latest Implementation (Current Release)
- ✅ **Comprehensive Test Suite**: 58 end-to-end tests covering all contract functionality (100% passing)
- ✅ **Mock SIP-010 Tokens**: Three fully functional test tokens for development and testing
- ✅ **Vitest Integration**: Modern testing framework with fast execution and clear reporting
- ✅ **Complete Test Coverage**: Initialization, pools, liquidity, swaps, rewards, queries, security, and complex scenarios
- ✅ **CI/CD Ready**: Test suite ready for continuous integration pipelines

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

## 📁 Project Structure

```
decen_exchange/
├── contracts/
│   ├── den_exchange.clar          # Main DEX smart contract
│   ├── test-token-a.clar          # Mock SIP-010 token for testing
│   ├── test-token-b.clar          # Mock SIP-010 token for testing
│   └── test-token-c.clar          # Mock SIP-010 token for testing
├── tests/
│   └── den_exchange.test.ts       # Comprehensive test suite (58 tests)
├── settings/
│   ├── Devnet.toml               # Development network configuration
│   ├── Testnet.toml              # Testnet configuration
│   └── Mainnet.toml              # Mainnet configuration
├── Clarinet.toml                 # Clarinet project configuration
├── vitest.config.js              # Vitest test configuration
├── package.json                  # Node.js dependencies
└── README.md                     # This file
```

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed (v3.0.2+)
- Node.js (v18+) and npm for testing
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

## 🛠️ Development Quick Reference

### Common Commands
```bash
# Run all tests
npm test

# Run tests in watch mode (auto-rerun on changes)
npm test -- --watch

# Run specific test suite
npm test -- -t "Pool Creation"

# Check contract syntax
clarinet check

# Start interactive console
clarinet console

# Format code
npm run format  # if configured
```

### Test File Organization
The main test file `tests/den_exchange.test.ts` is organized into logical sections:
- **Initialization**: Basic setup validation
- **Pool Creation**: Pool management functionality
- **Add Liquidity**: Liquidity provision tests
- **Remove Liquidity**: Liquidity withdrawal tests
- **Token Swaps**: Trading functionality
- **Rewards System**: Staking rewards
- **Read-Only Query Functions**: Data retrieval
- **Edge Cases and Security**: Security validations
- **Complex Scenarios**: Integration tests

### Adding New Tests
When adding new functionality:
1. Write the contract function
2. Add corresponding test(s) in the appropriate section
3. Run `npm test` to verify all tests pass
4. Ensure test names clearly describe what they validate
5. Include both success and failure cases

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

### Running Tests

Run the comprehensive test suite:
```bash
npm test
```

### Test Coverage (58/58 tests passing - 100%)

Our comprehensive test suite validates all contract functionality:

#### Initialization Tests (2 tests)
- Simnet environment validation
- Default contract state initialization

#### Pool Creation Tests (6 tests)
- ✅ Successful pool creation with token pairs
- ✅ Pool count incrementation
- ✅ Duplicate pool prevention
- ✅ Same-token pool validation
- ✅ Token order handling
- ✅ Multiple pool management

#### Liquidity Management Tests (13 tests)

**Add Liquidity (6 tests)**
- ✅ Initial liquidity provision to empty pools
- ✅ LP token calculation (product formula)
- ✅ Proportional liquidity additions
- ✅ Non-existent pool validation
- ✅ Zero amount rejection
- ✅ Slippage protection enforcement

**Remove Liquidity (7 tests)**
- ✅ Successful liquidity removal
- ✅ Proportional token returns
- ✅ Non-existent pool validation
- ✅ Zero liquidity rejection
- ✅ Slippage protection
- ✅ Insufficient balance handling
- ✅ Pool reserve updates

#### Token Swap Tests (7 tests)
- ✅ Basic token swap execution
- ✅ Fee-adjusted output calculations
- ✅ Non-existent pool validation
- ✅ Zero amount rejection
- ✅ Slippage protection
- ✅ Constant product invariant maintenance
- ✅ Bidirectional swapping
- ✅ Multiple consecutive swaps

#### Rewards System Tests (9 tests)
- ✅ Block-based reward accumulation
- ✅ Reward claiming functionality
- ✅ LP balance updates after claims
- ✅ Pending reward resets
- ✅ Proportional multi-LP distribution
- ✅ Non-existent pool validation
- ✅ Reward rate updates (owner only)
- ✅ Non-owner access prevention
- ✅ Invalid rate rejection

#### Query Function Tests (10 tests)
- ✅ Pool information retrieval
- ✅ Non-existent pool handling
- ✅ LP provider information
- ✅ Swap amount estimation (output)
- ✅ Swap amount estimation (input)
- ✅ Non-existent pool query handling
- ✅ Optimal liquidity calculations
- ✅ LP token balance queries
- ✅ Zero balance handling
- ✅ Total LP supply tracking

#### Security & Edge Case Tests (6 tests)
- ✅ Reentrancy attack prevention
- ✅ Very small amount handling
- ✅ Very large amount handling
- ✅ Unbalanced pool ratios
- ✅ Overflow prevention
- ✅ Token principal validation

#### Complex Scenario Tests (3 tests)
- ✅ Multi-user pool interactions
- ✅ Sequential add/remove operations
- ✅ Pool integrity under load

### Test Implementation Details

The test suite uses:
- **Vitest 3.2.4** - Fast and modern test framework
- **Clarinet SDK** - Stacks blockchain testing tools
- **Simnet** - Local blockchain simulation for rapid testing
- **Mock SIP-010 Tokens** - Three test tokens (test-token-a, test-token-b, test-token-c)

### Mock Token Contracts

For comprehensive testing, the project includes three SIP-010 compliant mock tokens:
- `contracts/test-token-a.clar`
- `contracts/test-token-b.clar`
- `contracts/test-token-c.clar`

These tokens support:
- Standard SIP-010 trait implementation
- Mint functionality for test setup
- Transfer operations for DEX testing

### Understanding Test Results

When you run `npm test`, you should see output like:

```
✓ tests/den_exchange.test.ts (58 tests) 4446ms

Test Files  1 passed (1)
     Tests  58 passed (58)
  Duration  8.46s
```

Each test validates specific functionality:
- ✅ **Green checkmarks** indicate passing tests
- ❌ **Red X's** indicate failing tests (investigate immediately)
- ⏱️ **Duration** shows test execution time

### Debugging Failed Tests

If tests fail:
1. Check the error message for the specific assertion that failed
2. Review the test file at the indicated line number
3. Verify contract changes haven't broken existing functionality
4. Run individual test suites: `npm test -- tests/den_exchange.test.ts -t "Pool Creation"`
5. Check Clarinet logs for contract execution details

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

