// prediction-market/my-workflow/predictMarketHttpRequester.ts

import {
  type Runtime,
  type HTTPPayload,
  bytesToHex,
  hexToBase64,
  TxStatus,
  decodeJson,
} from "@chainlink/cre-sdk";
import { encodeAbiParameters, parseAbiParameters, keccak256, parseEther, toHex } from "viem";
import { createEvmClient, type Config } from "../utils/evmClientFactory";

interface PredictMarketPayload {
  marketId: number;
  prediction: 0 | 1; // 0 = Yes, 1 = No
  amount: string; // ETH amount to bet (e.g., "0.1" for 0.1 ETH)
}

// Function signature for prediction routing
const PREDICT_MARKET_SELECTOR = keccak256(toHex("predict(uint256,uint8)")).slice(0, 10);

// ABI parameters for predict: (uint256 marketId, uint8 prediction)
const PREDICT_MARKET_PARAMS = parseAbiParameters("uint256, uint8");

export function predictMarketHttpRequester(runtime: Runtime<Config>, payload: HTTPPayload): string {
  runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  runtime.log("CRE Workflow: HTTP Trigger - Predict Market");
  runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

  try {
    // ─────────────────────────────────────────────────────────────
    // Step 1: Parse and validate the incoming payload
    // ─────────────────────────────────────────────────────────────
    if (!payload.input || payload.input.length === 0) {
      runtime.log("[ERROR] Empty request payload");
      return "Error: Empty request";
    }

    const inputData = decodeJson(payload.input) as PredictMarketPayload;
    runtime.log(`[Step 1] Received prediction for market ${inputData.marketId}`);
    runtime.log(`         Prediction: ${inputData.prediction === 0 ? 'Yes' : 'No'}`);
    runtime.log(`         Bet amount: ${inputData.amount} ETH`);

    if (inputData.marketId === undefined || inputData.marketId < 0) {
      runtime.log("[ERROR] Invalid market ID");
      return "Error: Invalid market ID";
    }

    if (inputData.prediction !== 0 && inputData.prediction !== 1) {
      runtime.log("[ERROR] Prediction must be 0 (Yes) or 1 (No)");
      return "Error: Invalid prediction value";
    }

    if (!inputData.amount || parseFloat(inputData.amount) <= 0) {
      runtime.log("[ERROR] Bet amount must be greater than 0");
      return "Error: Invalid bet amount";
    }

    // ─────────────────────────────────────────────────────────────
    // Step 2: Get network and create EVM client
    // ─────────────────────────────────────────────────────────────
    const evmConfig = runtime.config.evms[0];
    const evmClient = createEvmClient(evmConfig.chainSelectorName);
    runtime.log(`[Step 2] Connected to ${evmConfig.chainSelectorName}`);
    runtime.log(`         Contract: ${evmConfig.marketAddress}`);

    // ─────────────────────────────────────────────────────────────
    // Step 3: Encode prediction parameters
    // ─────────────────────────────────────────────────────────────
    const predictionData = encodeAbiParameters(PREDICT_MARKET_PARAMS, [
      BigInt(inputData.marketId),
      inputData.prediction,
    ]);
    runtime.log(`[Step 3] Encoded prediction data: marketId=${inputData.marketId}, prediction=${inputData.prediction}`);

    // ─────────────────────────────────────────────────────────────
    // Step 4: Add function selector prefix for routing
    // ─────────────────────────────────────────────────────────────
    const prefixedData = (PREDICT_MARKET_SELECTOR + predictionData.slice(2)) as `0x${string}`;
    runtime.log(`[Step 4] Function selector: ${PREDICT_MARKET_SELECTOR}`);

    // ─────────────────────────────────────────────────────────────
    // Step 5: Generate CRE report with encoded data
    // ─────────────────────────────────────────────────────────────
    const reportResponse = runtime
      .report({
        encodedPayload: hexToBase64(prefixedData),
        encoderName: "evm",
        signingAlgo: "ecdsa",
        hashingAlgo: "keccak256",
      })
      .result();
    runtime.log(`[Step 5] Generated CRE report with encoded prediction data`);

    // ─────────────────────────────────────────────────────────────
    // Step 6: Convert ETH amount to wei and send transaction
    // ─────────────────────────────────────────────────────────────
    const valueInWei = parseEther(inputData.amount);
    runtime.log(`[Step 6] Converting ${inputData.amount} ETH to ${valueInWei} wei`);

    const writeResult = evmClient
      .writeReport(runtime, {
        receiver: evmConfig.marketAddress,
        report: reportResponse,
        gasConfig: {
          gasLimit: evmConfig.gasLimit,
        },
        value: valueInWei.toString(), // Send ETH with the transaction
      })
      .result();

    // ─────────────────────────────────────────────────────────────
    // Step 7: Check transaction status and return result
    // ─────────────────────────────────────────────────────────────
    if (writeResult.txStatus === TxStatus.SUCCESS) {
      const txHash = bytesToHex(writeResult.txHash || new Uint8Array(32));
      runtime.log(`[Step 7] ✓ Prediction transaction successful!`);
      runtime.log(`         TX Hash: ${txHash}`);
      runtime.log(`         Market: ${inputData.marketId}`);
      runtime.log(`         Prediction: ${inputData.prediction === 0 ? 'Yes' : 'No'}`);
      runtime.log(`         Amount: ${inputData.amount} ETH`);
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
