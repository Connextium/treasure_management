import { cre, Runner } from "@chainlink/cre-sdk";
import { lcIssuedListener } from "./eventListeners/lcIssuedListener";
import { LC_ISSUED_EVENT_HASH } from "./abis/locManagementAbi";
import { createEvmClient, type Config } from "./utils/evmClientFactory";

const initWorkflow = (config: Config) => {
  // Initialize EVM client for the configured chain
  const evmClient = createEvmClient(config.evms[0].chainSelectorName);

  return [
    // Log Trigger - LCIssued Event Listener
    cre.handler(
      evmClient.logTrigger({
        addresses: [config.evms[0].locManagementAddress as `0x${string}`],
        topics: [{ values: [LC_ISSUED_EVENT_HASH as `0x${string}`] }],
        confidence: "CONFIDENCE_LEVEL_FINALIZED",
      }),
      lcIssuedListener
    ),
    
    // TODO: Add more event listeners:
    // - LCActivated
    // - LCSettled
    // - LCExpired
    // - LCFundsMinted
    // - Individual Loc contract events (dynamic registration)
  ];
};

export async function main() {
  const runner = await Runner.newRunner<Config>();
  await runner.run(initWorkflow);
}

main();

