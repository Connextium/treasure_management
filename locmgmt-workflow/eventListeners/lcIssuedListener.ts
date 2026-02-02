// locmgmt-workflow/eventListeners/lcIssuedListener.ts

import {
  type Runtime,
  type EVMLog,
  bytesToHex,
} from "@chainlink/cre-sdk";
import { decodeEventLog } from "viem";
import { type Config } from "../utils/evmClientFactory";
import { locManagementAbi } from "../abis/locManagementAbi";

/**
 * Data structure for LCIssued event
 */
export interface LCIssuedData {
  locNo: bigint;
  buyerAcc: `0x${string}`;
  sellerAcc: `0x${string}`;
  amount: bigint;
  locContractAddress: `0x${string}`;
  txHash: string;
  blockNumber: bigint;
  timestamp?: bigint;
}

/**
 * Event listener for LCIssued events from LocManagement contract
 * 
 * This is triggered when a new Letter of Credit is issued.
 * Critical for tracking new LC creation and obtaining Loc contract addresses
 * for dynamic monitoring.
 * 
 * @param runtime - CRE runtime instance
 * @param payload - EVM log payload containing the event data
 * @returns Decoded LC issuance data
 */
export function lcIssuedListener(
  runtime: Runtime<Config>,
  payload: EVMLog
): LCIssuedData {
  runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  runtime.log("LocManagement: LCIssued Event Detected");
  runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

  try {
    // ─────────────────────────────────────────────────────────────
    // Step 1: Decode LCIssued event data from log
    // ─────────────────────────────────────────────────────────────
    // Construct topics array for decoding
    const topics = payload.topics.map(
      (t) => bytesToHex(t) as `0x${string}`
    ) as [`0x${string}`, ...`0x${string}`[]];

    // Convert data to hex string
    const data = bytesToHex(payload.data);

    const decodedLog = decodeEventLog({
      abi: locManagementAbi,
      topics,
      data,
    });

    runtime.log(`[Step 1] Decoded LCIssued event log: ${JSON.stringify(
      decodedLog,
      (_, v) => typeof v === "bigint" ? v.toString() : v
    )}`);

    const { args } = decodedLog;

    const { locNo, buyerAcc, sellerAcc, amount, locContractAddress } = args as {
      locNo: bigint;
      buyerAcc: `0x${string}`;
      sellerAcc: `0x${string}`;
      amount: bigint;
      locContractAddress: `0x${string}`;
    };

    runtime.log(`[Step 1] LCIssued event detected`);
    runtime.log(`[Step 1] LC Number: ${locNo}`);
    runtime.log(`[Step 1] Buyer Account: ${buyerAcc}`);
    runtime.log(`[Step 1] Seller Account: ${sellerAcc}`);
    runtime.log(`[Step 1] Amount: ${amount.toString()}`);
    runtime.log(`[Step 1] Loc Contract Address: ${locContractAddress}`);

    // ─────────────────────────────────────────────────────────────
    // Step 2: Extract transaction context
    // ─────────────────────────────────────────────────────────────
    const txHash = bytesToHex(payload.txHash);
    const blockNumber = payload.blockNumber;

    runtime.log(`[Step 2] Transaction Hash: ${txHash}`);
    runtime.log(`[Step 2] Block Number: ${blockNumber}`);

    // ─────────────────────────────────────────────────────────────
    // Step 3: Prepare LC data structure
    // ─────────────────────────────────────────────────────────────
    const lcData: LCIssuedData = {
      locNo,
      buyerAcc,
      sellerAcc,
      amount,
      locContractAddress,
      txHash,
      blockNumber,
    };

    runtime.log(`[Step 3] LC data prepared for processing`);

    // ─────────────────────────────────────────────────────────────
    // Step 4: Business logic integration points
    // ─────────────────────────────────────────────────────────────
    runtime.log(`[Step 4] Business Logic Integration:`);
    runtime.log(`[Step 4] - Store Loc contract address: ${locContractAddress}`);
    runtime.log(`[Step 4] - Register for dynamic Loc event monitoring`);
    runtime.log(`[Step 4] - Update LC database/registry`);
    runtime.log(`[Step 4] - Send notifications to buyer and seller`);
    runtime.log(`[Step 4] - Trigger compliance checks`);

    // TODO: Implement business logic:
    // 1. Store locContractAddress in dynamic registry for event monitoring
    // 2. Update database with new LC record
    // 3. Send notifications to buyerAcc and sellerAcc
    // 4. Trigger any required compliance/KYC checks
    // 5. Update analytics/dashboard

    // ─────────────────────────────────────────────────────────────
    // Step 5: Return processed data
    // ─────────────────────────────────────────────────────────────
    runtime.log(`[Step 5] LC issuance processing complete`);
    runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

    return lcData;
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    runtime.log(`[ERROR] Failed to process LCIssued event: ${msg}`);
    runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    throw err;
  }
}
