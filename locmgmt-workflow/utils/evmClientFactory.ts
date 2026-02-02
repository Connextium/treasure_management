// locmgmt-workflow/utils/evmClientFactory.ts

import { cre, getNetwork } from "@chainlink/cre-sdk";

/**
 * Configuration type for LocManagement workflow
 */
export type Config = {
  evms: Array<{
    locManagementAddress: string;
    chainSelectorName: string;
    treasureLedgerAddress: string;
    gasLimit: string;
  }>;
};

/**
 * Create an EVM client using CRE SDK
 * 
 * @param chainSelectorName - CRE SDK chain selector name (e.g., "ethereum-testnet-sepolia")
 * @returns Configured CRE EVM client
 */
export function createEvmClient(chainSelectorName: string) {
  const network = getNetwork({
    chainFamily: "evm",
    chainSelectorName,
    isTestnet: true,
  });

  if (!network) {
    throw new Error(`Unknown chain: ${chainSelectorName}`);
  }

  return new cre.capabilities.EVMClient(network.chainSelector.selector);
}
