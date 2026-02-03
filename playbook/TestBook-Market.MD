

cd contracts

source ../.env

forge create src/MarketPredictor.sol:MarketPredictor \
  --rpc-url "https://ethereum-sepolia-rpc.publicnode.com" \
  --private-key $CRE_ETH_PRIVATE_KEY \
  --broadcast \
  --verify $ETHERSCAN_API_KEY \
  --constructor-args $CRE_KEYSTONE_FORWARDER_ADDRESS

0x91D01d520EC2dC8461bd71cc846c115D739658E7

# Deploy with the MockKeystoneForwarder address for Sepolia
forge create src/treasure/TreasureLedger.sol:TreasureLedger \
  --rpc-url "https://ethereum-sepolia-rpc.publicnode.com" \
  --private-key $CRE_ETH_PRIVATE_KEY \
  --etherscan-api-key $ETHERSCAN_API_KEY --verify \
  --constructor-args $CRE_KEYSTONE_FORWARDER_ADDRESS

0xb1598389c60829B4c7359d85E2bD99bC8Bd557a6

# Deploy with the MockKeystoneForwarder address for Sepolia
forge create src/letterofcredit/LocManagement.sol:LocManagement \
  --rpc-url "https://ethereum-sepolia-rpc.publicnode.com" \
  --private-key $CRE_ETH_PRIVATE_KEY \
  --constructor-args 0xb1598389c60829B4c7359d85E2bD99bC8Bd557a6 $ISSUING_BANK_ADDRESS $CRE_KEYSTONE_FORWARDER_ADDRESS

0xFbbD48bF74507c1bb67893B442f736deFc443BAE


cd my-workflow

bun install          
# ensures cre-setup runs via postinstall

bunx cre workflow simulate --target staging-settings





