# LocManagement Workflow

Chainlink CRE workflow for monitoring Letter of Credit (LC) lifecycle events from LocManagement and individual Loc contracts.

## Overview

This workflow implements **dual-contract event monitoring** to track all LC operations:

- **LocManagement events**: Central orchestrator for LC lifecycle
- **Individual Loc contract events**: Direct operations by sellers

### Why Both Contracts?

🔴 **CRITICAL**: Sellers can call `Loc.settleLC()` directly, bypassing LocManagement. Monitoring only LocManagement would miss direct settlements.

## Project Structure

```
locmgmt-workflow/
├── abis/
│   └── locManagementAbi.ts       # LocManagement contract ABI
├── eventListeners/
│   └── lcIssuedListener.ts       # LCIssued event handler
├── utils/
│   └── evmClientFactory.ts       # EVM client configuration
├── main.ts                        # Workflow entry point
├── config.staging.json            # Staging environment config
├── config.production.json         # Production environment config
└── package.json                   # Dependencies
```

## Phase 1 Implementation ✅ (COMPLETE)

✅ Project structure setup  
✅ LocManagement ABI definitions  
✅ LCIssued event listener implementation

### Events Monitored

- [x] **LCIssued** - Track new LC creation and Loc contract addresses

### Pending (Next Phases)

- [ ] LCActivated event listener
- [ ] LCSettled event listener  
- [ ] LCExpired event listener
- [ ] LCFundsMinted event listener
- [ ] Individual Loc contract event listeners (dynamic)
- [ ] Database integration
- [ ] Notification system
- [ ] Event correlation logic

## Configuration

### Staging (`config.staging.json`)

```json
{
  "locManagementAddress": "0x...",
  "rpcUrl": "https://sepolia.infura.io/v3/YOUR_KEY",
  "chainId": 11155111,
  "treasureLedgerAddress": "0x...",
  "enableNotifications": true,
  "enableDatabaseSync": true
}
```

### Production (`config.production.json`)

```json
{
  "locManagementAddress": "0x...",
  "rpcUrl": "https://mainnet.infura.io/v3/YOUR_KEY",
  "chainId": 1,
  "treasureLedgerAddress": "0x...",
  "enableNotifications": true,
  "enableDatabaseSync": true
}
```

## Setup

1. Install dependencies:
```bash
bun install
```

2. Update configuration files with actual contract addresses and RPC URLs

3. Calculate event topic hashes in `abis/locManagementAbi.ts`:
```typescript
import { keccak256, toHex } from "viem";

const LC_ISSUED_HASH = keccak256(toHex("LCIssued(uint256,address,address,uint256,address)"));
```

## Running the Workflow

### Local Simulation

```bash
cre workflow simulate locmgmt-workflow \
  --trigger-log \
  --trigger-index 0
```

### Deploy to CRE

```bash
cre workflow deploy locmgmt-workflow \
  --config config.staging.json
```

## Event Listener: lcIssuedListener

### Purpose
Monitors `LCIssued` events from LocManagement contract to:
- Track new LC creation
- Obtain Loc contract addresses for dynamic monitoring
- Trigger downstream workflows

### Event Data
```typescript
{
  locNo: bigint;              // LC number
  buyerAcc: address;          // Buyer account
  sellerAcc: address;         // Seller/beneficiary account
  amount: bigint;             // LC amount
  locContractAddress: address; // Individual Loc contract
  txHash: string;             // Transaction hash
  blockNumber: bigint;        // Block number
}
```

### Integration Points
- Store Loc contract address for dynamic event monitoring
- Update LC database/registry
- Send notifications to buyer and seller
- Trigger compliance checks
- Update analytics dashboards

## Next Steps

See [playbook/plans/3.LocManagement-Event-Listeners-Analysis.md](../playbook/plans/3.LocManagement-Event-Listeners-Analysis.md) for complete implementation roadmap.

### Phase 2: Additional Event Listeners
- Implement remaining LocManagement event listeners
- Set up event correlation logic
- Database schema and integration

### Phase 3: Individual Loc Monitoring
- Dynamic Loc contract discovery
- Individual Loc event listeners
- Cross-contract event validation

### Phase 4: Production Deployment
- Comprehensive testing
- Performance optimization
- Monitoring and alerting setup

## Documentation

- [Event Listeners Analysis](../playbook/plans/3.LocManagement-Event-Listeners-Analysis.md)
- [LocManagement Contract](../contracts/src/letterofcredit/LocManagement.sol)
- [Loc Contract](../contracts/src/letterofcredit/Loc.sol)

## License

UNLICENSED
