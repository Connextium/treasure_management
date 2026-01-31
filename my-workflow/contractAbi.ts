// prediction-market/my-workflow/contractAbi.ts

import MarketPredictorJson from "../contracts/out/MarketPredictor.sol/MarketPredictor.json";
import { type Abi, type AbiEvent, type AbiFunction, toEventSelector } from "viem";

const fullAbi: Abi = MarketPredictorJson.abi as Abi;

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────

function getEvent(name: string): AbiEvent {
  const event = fullAbi.find(
    (item): item is AbiEvent => item.type === "event" && item.name === name
  );
  if (!event) throw new Error(`Event "${name}" not found in MarketPredictor ABI`);
  return event;
}

function getFunction(name: string): AbiFunction {
  const fn = fullAbi.find(
    (item): item is AbiFunction => item.type === "function" && item.name === name
  );
  if (!fn) throw new Error(`Function "${name}" not found in MarketPredictor ABI`);
  return fn;
}

// ─────────────────────────────────────────────────────────────
// MarketCreated event
// ─────────────────────────────────────────────────────────────

export const marketCreatedAbi = [getEvent("MarketCreated")] as const;
export const marketCreatedEventHash = toEventSelector(marketCreatedAbi[0]);

// ─────────────────────────────────────────────────────────────
// getMarket function
// ─────────────────────────────────────────────────────────────

export const getMarketAbi = [getFunction("getMarket")] as const;
