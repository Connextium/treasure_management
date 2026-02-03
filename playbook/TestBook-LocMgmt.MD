
# Prerequisite: gnerated ABI files for LocManagement


```bash

cd treasure_management/locmgmt-workflow


bun intsall


```

### Test: Create Loc, and LoggerTrigger on event LCIssued ( Already Done once!)

```bash

cd treasure_management

source .env.prv && source .env

cd treasure_management

cast send $LocManagement_Address \
  "issueLC(uint256,address,address,uint256,uint256,uint256)" \
  1001 \
  $BUYER_ADDRESS \
  $SELLER_ADDRESS \
  "1000000000000000000" \
  $(date -j -f "%Y-%m-%d" "2026-02-01" +%s) \
  $(date -j -f "%Y-%m-%d" "2026-05-01" +%s) \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
  --private-key $ISSUING_BANK_PRIVATE_KEY

                    
status                  1
transactionHash         0xe00e0939c0b72afe468708271f56beba48194cd1564fa939615828ae60af607c
transactionIndex        1
type                    2
to                      0xB48698F8bD0EF69d32CFf07196eb0a8A2F971a25

cast receipt 0xe00e0939c0b72afe468708271f56beba48194cd1564fa939615828ae60af607c \
 --rpc-url https://ethereum-sepolia-rpc.publicnode.com

```

### Test: Simulate the locmgmt-workflow

```bash

cre workflow simulate locmgmt-workflow --target staging-settings

Warning: using default private key for chain write simulation. To use your own key, set CRE_ETH_PRIVATE_KEY in your .env file or system environment.
Workflow compiled

🔗 EVM Trigger Configuration:
Please provide the transaction hash and event index for the EVM log event.
Enter transaction hash (0x...): 0xe00e0939c0b72afe468708271f56beba48194cd1564fa939615828ae60af607c
Enter event index (0-based): 1
Fetching transaction receipt for transaction 0xe00e0939c0b72afe468708271f56beba48194cd1564fa939615828ae60af607c...
Found log event at index 1: contract=0xB48698F8bD0EF69d32CFf07196eb0a8A2F971a25, topics=4
Created EVM trigger log for transaction 0xe00e0939c0b72afe468708271f56beba48194cd1564fa939615828ae60af607c, event 1
2026-02-01T20:44:17Z [SIMULATION] Simulator Initialized

2026-02-01T20:44:17Z [SIMULATION] Running trigger trigger=evm:ChainSelector:16015286601757825753@1.0.0
2026-02-01T20:44:17Z [USER LOG] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2026-02-01T20:44:17Z [USER LOG] LocManagement: LCIssued Event Detected
2026-02-01T20:44:17Z [USER LOG] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2026-02-01T20:44:17Z [USER LOG] [Step 1] Decoded LCIssued event log: {"eventName":"LCIssued","args":{"locNo":"1001","buyerAcc":"0x7248a10797048Bb8C0508D25dE9bDBa82d335EF3","sellerAcc":"0x1C72359024049C79d58c7A0F08408CcDC9516561","amount":"1000000000000000000","locContractAddress":"0x0bc6603e86D55B05db1d9741Be2FEbA23fc41484"}}
2026-02-01T20:44:17Z [USER LOG] [Step 1] LCIssued event detected
2026-02-01T20:44:17Z [USER LOG] [Step 1] LC Number: 1001
2026-02-01T20:44:17Z [USER LOG] [Step 1] Buyer Account: 0x7248a10797048Bb8C0508D25dE9bDBa82d335EF3
2026-02-01T20:44:17Z [USER LOG] [Step 1] Seller Account: 0x1C72359024049C79d58c7A0F08408CcDC9516561
2026-02-01T20:44:17Z [USER LOG] [Step 1] Amount: 1000000000000000000
2026-02-01T20:44:17Z [USER LOG] [Step 1] Loc Contract Address: 0x0bc6603e86D55B05db1d9741Be2FEbA23fc41484
2026-02-01T20:44:17Z [USER LOG] [Step 2] Transaction Hash: 0xe00e0939c0b72afe468708271f56beba48194cd1564fa939615828ae60af607c
2026-02-01T20:44:17Z [USER LOG] [Step 2] Block Number: [object Object]
2026-02-01T20:44:17Z [USER LOG] [Step 3] LC data prepared for processing
2026-02-01T20:44:17Z [USER LOG] [Step 4] Business Logic Integration:
2026-02-01T20:44:17Z [USER LOG] [Step 4] - Store Loc contract address: 0x0bc6603e86D55B05db1d9741Be2FEbA23fc41484
2026-02-01T20:44:17Z [USER LOG] [Step 4] - Register for dynamic Loc event monitoring
2026-02-01T20:44:17Z [USER LOG] [Step 4] - Update LC database/registry
2026-02-01T20:44:17Z [USER LOG] [Step 4] - Send notifications to buyer and seller
2026-02-01T20:44:17Z [USER LOG] [Step 4] - Trigger compliance checks
2026-02-01T20:44:17Z [USER LOG] [Step 5] LC issuance processing complete
2026-02-01T20:44:17Z [USER LOG] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Workflow Simulation Result:
 {
  "amount": 1000000000000000000,
  "blockNumber": {
    "$typeName": "values.v1.BigInt",
    "absVal": "mzy1",
    "sign": 1
  },
  "buyerAcc": "0x7248a10797048Bb8C0508D25dE9bDBa82d335EF3",
  "locContractAddress": "0x0bc6603e86D55B05db1d9741Be2FEbA23fc41484",
  "locNo": 1001,
  "sellerAcc": "0x1C72359024049C79d58c7A0F08408CcDC9516561",
  "txHash": "0xe00e0939c0b72afe468708271f56beba48194cd1564fa939615828ae60af607c"
}

2026-02-01T20:44:17Z [SIMULATION] Execution finished signal received
2026-02-01T20:44:17Z [SIMULATION] Skipping WorkflowEngineV2

```


# References:

LocManagement Contract Address on Sepolia:
https://eth-sepolia.blockscout.com/address/0xB48698F8bD0EF69d32CFf07196eb0a8A2F971a25?tab=contract



Approve Loc contract to spend tokens (as issuing bank, after mint succeeds)
cast send 0x38745011Fc940e9C411dA5774447a6bc0a08C85A \
  "approve(address,uint256)" 0x0bc6603e86d55b05db1d9741be2feba23fc41484 1000000000000000000 \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
  --private-key $ISSUING_BANK_PRIVATE_KEY

cast call 0x38745011Fc940e9C411dA5774447a6bc0a08C85A "allowance(address,address)" 0x836e18BAc805d629177db6D752CEFa31a6B797E5 0x0bc6603e86d55b05db1d9741be2feba23fc41484 --rpc-url https://ethereum-sepolia-rpc.publicnode.com


cast send 0xB48698F8bD0EF69d32CFf07196eb0a8A2F971a25 \
  "settleLC(uint256)" 1001 \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
  --private-key $CRE_ETH_PRIVATE_KEY
