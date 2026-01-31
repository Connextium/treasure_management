// prediction-market/my-workflow/eventMarketCreatedListener.ts

import {
  type Runtime,
  type EVMLog,
  bytesToHex,
} from "@chainlink/cre-sdk";
import { decodeEventLog } from "viem";
import { type Config } from "../utils/evmClientFactory";
import { marketCreatedAbi } from "./marketPredictorAbiMapper";
import { evmMarketReader, type Market } from "./marketEvmReader";

export function eventMarketCreatedListener(runtime: Runtime<Config>, payload: EVMLog): Market {
  runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  runtime.log("CRE Workflow: Log Trigger - MarketCreated Event");
  runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

  try {
    // ─────────────────────────────────────────────────────────────
    // Step 1: Decode MarketCreated event data from log
    // ─────────────────────────────────────────────────────────────
    // Construct topics array for decoding
    const topics = payload.topics.map(
      (t) => bytesToHex(t) as `0x${string}`
    ) as [`0x${string}`, ...`0x${string}`[]];

    // Convert data to hex string
    const data = bytesToHex(payload.data);

    const decodedLog = decodeEventLog({
      abi: marketCreatedAbi,
      topics,
      data,
    });
    runtime.log(`[Step 1] Decoded MarketCreated event log: ${JSON.stringify(decodedLog, (_, v) => typeof v === "bigint" ? v.toString() : v)}`);

    const { args } = decodedLog;

    const { marketId, question, creator } = args as {
      marketId: bigint;
      question: string;
      creator: `0x${string}`;
    };
    runtime.log(`[Step 1] MarketCreated event detected`);
    runtime.log(`[Step 1] Market ID: ${marketId}`);
    runtime.log(`[Step 1] Question: "${question}"`);
    runtime.log(`[Step 1] Creator: ${creator}`);

    // ─────────────────────────────────────────────────────────────
    // Step 2: Log transaction context
    // ─────────────────────────────────────────────────────────────
    const txHash = bytesToHex(payload.txHash);
    runtime.log(`[Step 2] Tx hash: ${txHash}`);
    runtime.log(`[Step 2] Block: ${payload.blockNumber}`);

    // ─────────────────────────────────────────────────────────────
    // Step 3: Read full market data from contract
    // ─────────────────────────────────────────────────────────────
    runtime.log(`[Step 3] Reading market data for market ID: ${marketId}`);
    const market = evmMarketReader(runtime, marketId);

    // ─────────────────────────────────────────────────────────────
    // Step 4: Return market data
    // ─────────────────────────────────────────────────────────────
    runtime.log(`[Step 4] Market data retrieved successfully`);
    runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

    return market;
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    runtime.log(`[ERROR] ${msg}`);
    runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    throw err;
  }
}
