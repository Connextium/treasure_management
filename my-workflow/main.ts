// prediction-market/my-workflow/main.ts

import { cre, Runner } from "@chainlink/cre-sdk";
import { createMarketHttpRequester } from "./marketpredictor/createMarketHttpRequester";
import { settleMarketHttpRequester } from "./marketpredictor/settleMarketHttpRequester";
import { marketCreatedEventHash } from "./marketpredictor/marketPredictorAbiMapper";
import { eventMarketCreatedListener } from "./marketpredictor/eventMarketCreatedListener";
import { createEvmClient, type Config } from "./utils/evmClientFactory";
import { http } from "viem";

const initWorkflow = (config: Config) => {
  // Initialize HTTP capability
  const httpCapability = new cre.capabilities.HTTPCapability();
  const httpTrigger = httpCapability.trigger({});

  const evmClient = createEvmClient(config.evms[0].chainSelectorName);

  return [
    // Day 1: HTTP Trigger - Market Creation
    cre.handler(httpTrigger, createMarketHttpRequester),
    cre.handler(httpTrigger, settleMarketHttpRequester),

    // Log Trigger - MarketCreated Event Listener
    cre.handler(
      evmClient.logTrigger({
        addresses: [config.evms[0].marketAddress],
        topics: [{ values: [marketCreatedEventHash] }],
        confidence: "CONFIDENCE_LEVEL_FINALIZED",
      }),
      eventMarketCreatedListener
    ),
  ];
};

export async function main() {
  const runner = await Runner.newRunner<Config>();
  await runner.run(initWorkflow);
}

main();
