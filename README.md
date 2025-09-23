Decentralized Exchange (DEX) on Clarity
This project implements a decentralized exchange (DEX) smart contract in Clarity, supporting SIP-010 token swaps, automated market maker (AMM) pools, and staking incentives for liquidity providers.

Features
Token Swaps: Swap between any SIP-010 compliant tokens.
Liquidity Pools: Create and manage pools for token pairs.
AMM (xy=k): Constant product formula for fair pricing.
Staking Incentives: Earn rewards by providing liquidity.
Security: Reentrancy protection and robust state management.
Main Functions
add-liquidity: Add tokens to a pool and receive LP tokens.
remove-liquidity: Withdraw tokens and burn LP tokens.
swap-tokens: Swap one SIP-010 token for another.
claim-rewards: Distribute staking rewards to liquidity providers.
Getting Started
Deploy the contract to your Stacks blockchain environment.
Interact using Clarity functions for pool management, swaps, and rewards.
Ensure SIP-010 tokens are registered before use.
Requirements
Stacks blockchain
SIP-010 token contracts
Security
Internal checks for reentrancy and pool state.
Only valid token pairs and registered pools allowed.
For details, see the contract code in contracts/den_exchange.clar.