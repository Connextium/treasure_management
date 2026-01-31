// prediction-market/my-workflow/evmClientFactory.ts

import { cre, getNetwork } from "@chainlink/cre-sdk";

export type Config = {
  geminiModel: string;
  evms: Array<{
    marketAddress: string;
    chainSelectorName: string;
    gasLimit: string;
  }>;
};

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
