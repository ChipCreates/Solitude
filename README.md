# Solitude

A high-performance, open-source solitaire card game built with **Rust (WASM & Core Engine)**, **React 18**, and **Tauri 2.0**.

![License](https://img.shields.io/badge/license-GPL--3.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-Web%20%7C%20PWA%20%7C%20Linux%20%7C%20Windows%20%7C%20macOS-lightgrey.svg)
![Rust](https://img.shields.io/badge/Rust-1.75+-orange.svg)
![Tauri](https://img.shields.io/badge/Tauri-2.0-blue.svg)

> **Note on Scope**: This project adopts the *"one codebase, three targets"* model (Desktop Native, Web/PWA, Android Native via Tauri). iOS is explicitly out of scope for this release. The original Flutter implementation remains in `lib/` as an archived reference.

## Supported Games (10 Solitaire Variants)

- **Klondike** (Draw 1 & Draw 3)
- **Spider** (1, 2, or 4 Suits)
- **FreeCell**
- **Pyramid**
- **Golf**
- **TriPeaks**
- **Yukon**
- **Forty Thieves**
- **Canfield**
- **Scorpion**

## Features

- **Blazing-Fast Engine**: High-performance Rust backend compiled to WebAssembly for sub-millisecond move evaluation.
- **AI Solver & Autoplay**: Best-first search solver utilizing `BinaryHeap` heuristics for instant hints and automated solver execution.
- **Structure-of-Arrays (SoA) Particle System**: 60 FPS HTML5 Canvas victory particle celebrations (Cascade, Fountain, Scatter, Vortex).
- **Glassmorphism UI**: Premium dark mode design system with customizable felt themes, card backs, and animation speeds.
- **Offline-First & Local-Only**: Zero telemetry, zero tracking, zero external network requests. All data saved locally.

## Development & Building

### Prerequisites

- **Rust** (1.75 or higher)
- **Node.js** (v18 or higher) & `pnpm` / `npm`
- **wasm-pack** (`cargo install wasm-pack`)

### Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/plotworx/solitude.git
   cd solitude/solitude-rs
   ```

2. **Build WASM Engine**
   ```bash
   npm run build:wasm
   ```

3. **Run Web Dev Server**
   ```bash
   npm run dev
   ```

4. **Run Desktop App (Tauri)**
   ```bash
   npm run tauri dev
   ```

## Project Architecture

```
solitude/
├── solitude-rs/
│   ├── crates/
│   │   ├── engine-core/       # Core Rust game engines (10 variants, solver, snapshots)
│   │   └── engine-wasm/       # WASM bindings & Serde bridge
│   ├── src/
│   │   ├── canvas/            # Canvas renderer, SoA particle system & custom layouts
│   │   ├── components/        # React glassmorphism UI & settings modal
│   │   ├── store/             # Zustand persistent UI state
│   │   └── wasm/              # TypeScript engine wrappers & types
│   ├── src-tauri/             # Tauri 2.0 desktop shell & native packaging
│   └── package.json
├── lib/                       # Legacy Flutter codebase (Archived reference)
├── PRIVACY.md                 # Privacy Policy
├── CREDITS.md                 # Asset attributions
└── README.md
```

## Testing

Run cargo unit tests across all 10 game engines and property/fuzz testing:

```bash
cd solitude-rs
cargo test -p engine-core
```

## License

This project is licensed under the **GNU General Public License v3.0** - see the [LICENSE](LICENSE) file for details.

### Third-Party Licenses

- **Card Graphics**: [SVG Playing Cards](https://github.com/htdebeer/SVG-cards) by David Bellot / Huub de Beer - LGPL 2.1+
- **Font**: [Inter](https://rsms.me/inter/) by Rasmus Andersson - SIL Open Font License

---

Made with ♠️ by [Plotworx](https://plotworx.org)
