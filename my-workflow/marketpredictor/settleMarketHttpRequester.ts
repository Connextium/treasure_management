import {
  type Runtime,
  type HTTPPayload,
  bytesToHex,
  hexToBase64,
  TxStatus,
  decodeJson,
} from "@chainlink/cre-sdk";
import { encodeAbiParameters, parseAbiParameters, keccak256, toHex } from "viem";
import { createEvmClient, type Config } from "../utils/evmClientFactory";

interface SettleMarketPayload {
  marketId: number;
  outcome: 0 | 1; // 0 = Yes, 1 = No
  confidence: number; // 0-100
}

// Function signature for settlement routing
const SETTLE_MARKET_SELECTOR = keccak256(toHex("settleMarket(uint256,uint8,uint16)")).slice(0, 10);

// ABI parameters for settlement: (uint256 marketId, Prediction outcome, uint16 confidence)
const SETTLE_MARKET_PARAMS = parseAbiParameters("uint256, uint8, uint16");

export function settleMarketHttpRequester(runtime: Runtime<Config>, payload: HTTPPayload): string {
  runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  runtime.log("CRE Workflow: HTTP Trigger - Settle Market");
  runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

  try {
    // Parse settlement payload
    if (!payload.input || payload.input.length === 0) {
      runtime.log("[ERROR] Empty request payload");
      return "Error: Empty request";
    }

    const inputData = decodeJson(payload.input) as SettleMarketPayload;
    runtime.log(`[Step 1] Settling market ${inputData.marketId} with outcome ${inputData.outcome}`);

    const evmConfig = runtime.config.evms[0];
    const evmClient = createEvmClient(evmConfig.chainSelectorName);

    // Encode settlement data
    const settlementData = encodeAbiParameters(SETTLE_MARKET_PARAMS, [
      BigInt(inputData.marketId),
      inputData.outcome,
      inputData.confidence,
    ]);

    // Add function selector for routing
    const prefixedData = (SETTLE_MARKET_SELECTOR + settlementData.slice(2)) as `0x${string}`;
    runtime.log(`[Step 3] Function selector: ${SETTLE_MARKET_SELECTOR}`);

    // Generate CRE report with prefixed data
    const reportResponse = runtime
      .report({
        encodedPayload: hexToBase64(prefixedData),
        encoderName: "evm",
        signingAlgo: "ecdsa",
        hashingAlgo: "keccak256",
      })
      .result();

    // Write to contract
    const writeResult = evmClient
      .writeReport(runtime, {
        receiver: evmConfig.marketAddress,
        report: reportResponse,
        gasConfig: {
          gasLimit: evmConfig.gasLimit,
        },
      })
      .result();

    if (writeResult.txStatus === TxStatus.SUCCESS) {
      const txHash = bytesToHex(writeResult.txHash || new Uint8Array(32));
      runtime.log(`[Step 6] ✓ Settlement transaction successful: ${txHash}`);
      runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      return txHash;
    }

    throw new Error(`Transaction failed with status: ${writeResult.txStatus}`);
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    runtime.log(`[ERROR] ${msg}`);
    runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    throw err;
  }
}
