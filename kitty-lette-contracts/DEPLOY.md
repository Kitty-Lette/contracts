# Flow EVM Testnet Deployment Guide

## Prerequisites

1. **Install Foundry** (if not already installed):
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Get Flow testnet FLOW tokens**:
   - Visit [Flow Faucet](https://testnet-faucet.onflow.org/)
   - Connect your wallet and request testnet FLOW tokens

## Setup

1. **Clone and install dependencies**:
   ```bash
   git clone <your-repo>
   cd kitty-lette-contracts
   forge install
   ```

2. **Create environment file**:
   ```bash
   cp .env.example .env
   ```

3. **Configure your private key in `.env`**:
   ```
   PRIVATE_KEY=your_private_key_without_0x_prefix
   ```

## Deployment Commands

### 1. Test compilation
```bash
forge build
```

### 2. Deploy to Flow EVM Testnet
```bash
forge script script/Deploy.s.sol --rpc-url flow_testnet --broadcast --verify
```

### 3. Alternative deployment without verification
```bash
forge script script/Deploy.s.sol --rpc-url flow_testnet --broadcast
```

### 4. Manual contract verification (if needed)
```bash
forge verify-contract \
  --rpc-url flow_testnet \
  --etherscan-api-key $FLOW_TESTNET_API_KEY \
  <CONTRACT_ADDRESS> \
  src/contracts/FrothToken.sol:FrothToken
```

## Flow EVM Testnet Details

- **Chain ID**: 545
- **RPC URL**: https://testnet.evm.nodes.onflow.org
- **Explorer**: https://evm-testnet.flowscan.io/
- **Faucet**: https://testnet-faucet.onflow.org/

## Post-Deployment

After successful deployment, you'll see:
- FrothToken contract address
- KittyLette contract address
- Your deployer address will have 1,000,000 + 10,000 FROTH tokens
- Platform fee recipient set to deployer address

## Testing the Contracts

1. **Check FROTH balance**:
   ```bash
   cast call <FROTH_TOKEN_ADDRESS> "balanceOf(address)" <YOUR_ADDRESS> --rpc-url flow_testnet
   ```

2. **Approve FROTH for KittyLette**:
   ```bash
   cast send <FROTH_TOKEN_ADDRESS> "approve(address,uint256)" <KITTY_LETTE_ADDRESS> 100000000000000000000 --private-key $PRIVATE_KEY --rpc-url flow_testnet
   ```

3. **Spin the wheel**:
   ```bash
   cast send <KITTY_LETTE_ADDRESS> "spinWheel()" --private-key $PRIVATE_KEY --rpc-url flow_testnet
   ```

## Troubleshooting

1. **Insufficient funds**: Make sure you have enough FLOW for gas fees
2. **Nonce issues**: Add `--legacy` flag to forge commands
3. **RPC issues**: Check if Flow testnet is operational
4. **Gas estimation**: Add `--gas-estimate-multiplier 200` for conservative gas estimation

## Contract Addresses (Update after deployment)

- **FrothToken**: `<DEPLOYED_ADDRESS>`
- **KittyLette**: `<DEPLOYED_ADDRESS>`