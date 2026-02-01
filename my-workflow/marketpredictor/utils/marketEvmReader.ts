// prediction-market/my-workflow/evmMarketReader.ts

import {
  type Runtime,
  bytesToHex,
  encodeCallMsg,
  LAST_FINALIZED_BLOCK_NUMBER,
} from "@chainlink/cre-sdk";
import { encodeFunctionData, decodeFunctionResult, zeroAddress } from "viem";
import { createEvmClient, type Config } from "../../utils/evmClientFactory";
import { getMarketAbi } from "./marketPredictorAbiMapper";

export interface Market {
  creator: `0x${string}`;
  createdAt: bigint;
  settledAt: bigint;
  settled: boolean;
  confidence: number;
  outcome: number; // 0 = Yes, 1 = No
  totalYesPool: bigint;
  totalNoPool: bigint;
  question: string;
}

export function evmMarketReader(runtime: Runtime<Config>, marketId: bigint): Market {
  runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  runtime.log("CRE Workflow: EVM Read - getMarket");
  runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

  try {
    // ─────────────────────────────────────────────────────────────
    // Step 1: Prepare the EVM client and encode the call
    // ─────────────────────────────────────────────────────────────
    const evmConfig = runtime.config.evms[0];
    runtime.log(`[Step 1] Target chain: ${evmConfig.chainSelectorName}`);
    runtime.log(`[Step 1] Contract address: ${evmConfig.marketAddress}`);
    runtime.log(`[Step 1] Market ID: ${marketId}`);

    const evmClient = createEvmClient(evmConfig.chainSelectorName);

    const callData = encodeFunctionData({
      abi: getMarketAbi,
      functionName: "getMarket",
      args: [marketId],
    });

    // ─────────────────────────────────────────────────────────────
    // Step 2: Call the contract
    // ─────────────────────────────────────────────────────────────
    runtime.log("[Step 2] Calling getMarket on contract...");

    const callResult = evmClient
      .callContract(runtime, {
        call: encodeCallMsg({
          from: zeroAddress,
          to: evmConfig.marketAddress as `0x${string}`,
          data: callData,
        }),
        blockNumber: LAST_FINALIZED_BLOCK_NUMBER,
      })
      .result();

    // ─────────────────────────────────────────────────────────────
    // Step 3: Decode the result
    // ─────────────────────────────────────────────────────────────
    runtime.log("[Step 3] Decoding contract response...");

    const decoded = decodeFunctionResult({
      abi: getMarketAbi,
      functionName: "getMarket",
      data: bytesToHex(callResult.data) as `0x${string}`,
    }) as {
      creator: `0x${string}`;
      createdAt: number;
      settledAt: number;
      settled: boolean;
      confidence: number;
      outcome: number;
      totalYesPool: bigint;
      totalNoPool: bigint;
      question: string;
    };

    const market: Market = {
      creator: decoded.creator,
      createdAt: BigInt(decoded.createdAt),
      settledAt: BigInt(decoded.settledAt),
      settled: decoded.settled,
      confidence: decoded.confidence,
      outcome: decoded.outcome,
      totalYesPool: decoded.totalYesPool,
      totalNoPool: decoded.totalNoPool,
      question: decoded.question,
    };

    // ─────────────────────────────────────────────────────────────
    // Step 4: Log the market details
    // ─────────────────────────────────────────────────────────────
    runtime.log(`[Step 4] Market details:`);
    runtime.log(`  Creator:       ${market.creator}`);
    runtime.log(`  Question:      "${market.question}"`);
    runtime.log(`  Created at:    ${market.createdAt}`);
    runtime.log(`  Settled:       ${market.settled}`);
    runtime.log(`  Settled at:    ${market.settledAt}`);
    runtime.log(`  Outcome:       ${market.outcome === 0 ? "Yes" : "No"}`);
    runtime.log(`  Confidence:    ${market.confidence}`);
    runtime.log(`  Yes pool:      ${market.totalYesPool}`);
    runtime.log(`  No pool:       ${market.totalNoPool}`);
    runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

    return market;
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    runtime.log(`[ERROR] ${msg}`);
    runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    throw err;
  }
}
