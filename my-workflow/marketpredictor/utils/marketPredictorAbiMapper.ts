// my-workflow/marketpredictor/marketPredictorAbi.ts

import MarketPredictorJson from "../../../contracts/out/MarketPredictor.sol/MarketPredictor.json";
import { type Abi, toEventSelector } from "viem";
import { getEvent, getFunction } from "../../utils/abiHelpers";

const fullAbi: Abi = MarketPredictorJson.abi as Abi;

// ─────────────────────────────────────────────────────────────
// MarketCreated event
// ─────────────────────────────────────────────────────────────

export const marketCreatedAbi = [getEvent(fullAbi, "MarketCreated")] as const;
export const marketCreatedEventHash = toEventSelector(marketCreatedAbi[0]);

// ─────────────────────────────────────────────────────────────
// getMarket function
// ─────────────────────────────────────────────────────────────

export const getMarketAbi = [getFunction(fullAbi, "getMarket")] as const;
