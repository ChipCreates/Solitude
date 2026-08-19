import init, {
  ping,
  initialize_game,
  tap_stock,
  undo,
  redo,
  check_win,
  is_lost,
  execute_move_wasm,
  execute_pair_move_wasm,
  get_layout_buffer_ptr,
  get_layout_buffer_len,
  get_hint_json,
  auto_play_step_wasm,
  auto_complete_step_wasm,
} from "./pkg/engine_wasm.js";

let isInitialized = false;
let wasmModule: any = null;
let initPromise: Promise<any> | null = null;

export async function initEngine(): Promise<void> {
  if (!initPromise) {
    initPromise = init().then((module) => {
      wasmModule = module;
      isInitialized = true;
      return module;
    });
  }
  await initPromise;
}

export function pingEngine(): number {
  return ping();
}

export interface VariantOptions {
  klondikeDrawMode: number; // 1 or 3
  spiderSuitCount: number; // 1, 2, or 4
  golfWrapAround: boolean;
}

const DEFAULT_VARIANT_OPTIONS: VariantOptions = {
  klondikeDrawMode: 1,
  spiderSuitCount: 4,
  golfWrapAround: false,
};

export function initializeGame(gameTypeCode: number, seed: bigint, options?: Partial<VariantOptions>): boolean {
  const o = { ...DEFAULT_VARIANT_OPTIONS, ...options };
  return initialize_game(gameTypeCode, seed, o.klondikeDrawMode, o.spiderSuitCount, o.golfWrapAround);
}

export function tapStockWasm(): boolean {
  return tap_stock();
}

export function undoWasm(): boolean {
  return undo();
}

export function redoWasm(): boolean {
  return redo();
}

export function checkWinWasm(): boolean {
  if (!isInitialized) return false;
  return check_win();
}

export function isLostWasm(): boolean {
  if (!isInitialized) return false;
  return is_lost();
}

export function executeMoveWasm(
  fromKind: number,
  fromIdx: number,
  toKind: number,
  toIdx: number,
  cardId: number
): boolean {
  return execute_move_wasm(fromKind, fromIdx, toKind, toIdx, cardId);
}

export function executePairMoveWasm(
  fromKind: number,
  fromIdx: number,
  toKind: number,
  toIdx: number,
  cardId: number,
  secondCardId: number
): boolean {
  return execute_pair_move_wasm(
    fromKind,
    fromIdx,
    toKind,
    toIdx,
    cardId,
    secondCardId
  );
}

export interface WasmCard {
  id: number;
  suit: number; // 0: Hearts, 1: Diamonds, 2: Clubs, 3: Spades
  rank: number; // 1-13
  faceUp: boolean;
}

export interface WasmPile {
  kind: number; // 0: Stock, 1: Waste, 2: Foundation, 3: Tableau, 4: Cell, 5: Reserve, 6: Pyramid, 7: Discard
  index: number;
  cards: WasmCard[];
}

export function getPilesLayout(): WasmPile[] {
  if (!isInitialized || !wasmModule) return [];

  const ptr = get_layout_buffer_ptr();
  const len = get_layout_buffer_len();
  if (len === 0) return [];

  const buffer = new Uint8Array(wasmModule.memory.buffer, ptr, len);
  let offset = 0;

  const pileCount = buffer[offset++];
  const piles: WasmPile[] = [];

  for (let i = 0; i < pileCount; i++) {
    const kind = buffer[offset++];
    const index = buffer[offset++];
    const cardCount = buffer[offset++];
    const cards: WasmCard[] = [];

    for (let c = 0; c < cardCount; c++) {
      const id = buffer[offset++];
      const suit = buffer[offset++];
      const rank = buffer[offset++];
      const faceUp = buffer[offset++] === 1;

      cards.push({ id, suit, rank, faceUp });
    }

    piles.push({ kind, index, cards });
  }

  return piles;
}

export function getHintWasm(): any | null {
  if (!isInitialized) return null;
  const json = get_hint_json();
  if (!json) return null;
  try {
    return JSON.parse(json);
  } catch {
    return null;
  }
}

export function autoPlayStepWasm(): boolean {
  if (!isInitialized) return false;
  return auto_play_step_wasm();
}

export function autoCompleteStepWasm(): boolean {
  if (!isInitialized) return false;
  return auto_complete_step_wasm();
}
