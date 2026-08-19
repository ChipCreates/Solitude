export interface KeyboardNavActions {
  onUndo: () => void;
  onRedo: () => void;
  onNewGame: () => void;
  onHint: () => void;
  onAutoPlay: () => void;
  onSettings: () => void;
}

export function setupKeyboardNav(actions: KeyboardNavActions): () => void {
  const handleKeyDown = (e: KeyboardEvent) => {
    if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) {
      return;
    }
    if (e.key === "u" || (e.ctrlKey && e.key.toLowerCase() === "z")) {
      e.preventDefault();
      actions.onUndo();
    } else if (e.key === "r" || (e.ctrlKey && e.key.toLowerCase() === "y")) {
      e.preventDefault();
      actions.onRedo();
    } else if (e.key === "n" || e.key === "N") {
      e.preventDefault();
      actions.onNewGame();
    } else if (e.key === "h" || e.key === "H") {
      e.preventDefault();
      actions.onHint();
    } else if (e.key === "a" || e.key === "A") {
      e.preventDefault();
      actions.onAutoPlay();
    } else if (e.key === "Escape") {
      e.preventDefault();
      actions.onSettings();
    }
  };

  window.addEventListener("keydown", handleKeyDown);
  return () => window.removeEventListener("keydown", handleKeyDown);
}
