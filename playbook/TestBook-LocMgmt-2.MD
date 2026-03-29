# ============================================================
# Step 1: Issue LC (as issuing bank)
# ============================================================
cast send 0xB48698F8bD0EF69d32CFf07196eb0a8A2F971a25 \
  "issueLC(uint256,address,address,uint256,uint256,uint256)" \
  1002 \
  0x7248a10797048Bb8C0508D25dE9bDBa82d335EF3 \
  0x1C72359024049C79d58c7A0F08408CcDC9516561 \
  1000000000000000000 \
  1700000000 \
  1800000000 \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
  --private-key $ISSUING_BANK_PRIVATE_KEY

# ============================================================
# Step 2: Get the Loc contract address
# ============================================================
cast call 0xB48698F8bD0EF69d32CFf07196eb0a8A2F971a25 \
  "getLocContractAddress(uint256)" 1002 \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com

# ============================================================
# Step 3: Approve Loc contract to spend tokens (as issuing bank)
#         Replace <LOC_CONTRACT_ADDRESS> with result from Step 2
# ============================================================
cast send 0x38745011Fc940e9C411dA5774447a6bc0a08C85A \
  "approve(address,uint256)" <LOC_CONTRACT_ADDRESS> 1000000000000000000 \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
  --private-key $ISSUING_BANK_PRIVATE_KEY

# ============================================================
# Step 4: Activate LC (as issuing bank) - mints tokens + activates
# ============================================================
cast send 0xB48698F8bD0EF69d32CFf07196eb0a8A2F971a25 \
  "activateLC(uint256)" 1002 \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
  --private-key $ISSUING_BANK_PRIVATE_KEY

# ============================================================
# Step 5: Settle LC (as owner/deployer)
# ============================================================
cast send 0xB48698F8bD0EF69d32CFf07196eb0a8A2F971a25 \
  "settleLC(uint256)" 1002 \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
  --private-key $CRE_ETH_PRIVATE_KEY

# ============================================================
# Verify: Check final status and balances
# ============================================================
cast call 0xB48698F8bD0EF69d32CFf07196eb0a8A2F971a25 \
  "getLocStatus(uint256)" 1002 \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com


Others

cast send $MARKET_ADDRESS \
  "predict(uint256,uint8)" 1 0 \
  --value 0.001ether \
  --rpc-url "https://ethereum-sepolia-rpc.publicnode.com" \
  --private-key $CRE_ETH_PRIVATE_KEY


cast send $MARKET_ADDRESS \
  "requestSettlement(uint256)" \
  0 \
  --rpc-url "https://ethereum-sepolia-rpc.publicnode.com" \
  --private-key $CRE_ETH_PRIVATE_KEY




