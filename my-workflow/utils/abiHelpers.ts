// my-workflow/utils/abiHelpers.ts

import { type Abi, type AbiEvent, type AbiFunction } from "viem";

export function getEvent(abi: Abi, name: string): AbiEvent {
  const event = abi.find(
    (item): item is AbiEvent => item.type === "event" && item.name === name
  );
  if (!event) throw new Error(`Event "${name}" not found in ABI`);
  return event;
}

export function getFunction(abi: Abi, name: string): AbiFunction {
  const fn = abi.find(
    (item): item is AbiFunction => item.type === "function" && item.name === name
  );
  if (!fn) throw new Error(`Function "${name}" not found in ABI`);
  return fn;
}
