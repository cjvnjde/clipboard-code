import { atom } from "jotai";

export const modeStateAtom = atom<"normal" | "search">("normal");

export const isSearchModeAtom = atom((get) => get(modeStateAtom) === "search");
export const isNormalModeAtom = atom((get) => get(modeStateAtom) === "normal");
