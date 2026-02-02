// locmgmt-workflow/abis/locManagementAbi.ts

/**
 * ABI for LocManagement contract
 * Auto-generated from compiled Solidity contracts
 * To regenerate: bun run codegen
 */

export { locManagementAbi, locAbi } from '../generated/LocManagementAbi';

/**
 * Event topic hashes for log filtering
 * These are calculated from keccak256 hash of event signatures
 */
import { keccak256, toHex } from 'viem';

export const LC_ISSUED_EVENT_HASH = keccak256(
  toHex('LCIssued(uint256,address,address,uint256,address)')
);

export const LC_ACTIVATED_EVENT_HASH = keccak256(
  toHex('LCActivated(uint256)')
);

export const LC_SETTLED_EVENT_HASH = keccak256(
  toHex('LCSettled(uint256)')
);

export const LC_EXPIRED_EVENT_HASH = keccak256(
  toHex('LCExpired(uint256)')
);

export const LC_FUNDS_MINTED_EVENT_HASH = keccak256(
  toHex('LCFundsMinted(uint256,address,uint256)')
);

// Loc contract event hashes
export const LOC_ACTIVATED_EVENT_HASH = keccak256(
  toHex('LocActivated(uint256,uint256)')
);

export const LOC_SETTLED_EVENT_HASH = keccak256(
  toHex('LocSettled(uint256,address,uint256,uint256)')
);

export const LOC_EXPIRED_EVENT_HASH = keccak256(
  toHex('LocExpired(uint256,uint256)')
);

export const FUNDS_RELEASED_EVENT_HASH = keccak256(
  toHex('FundsReleased(address,uint256,uint256)')
);
