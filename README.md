# Chess 2.0

Desktop chess game built with **Godot 4.7** (GL Compatibility), Stockfish 18 analysis & AI, Maia-3 human-like bot support, Opening/Tactics Trainer, and Game Review.

## Quick Start (After `git clone`)

### Requirements
- **Godot 4.7.x** (`GL Compatibility`)
- Windows x64

### Option 1: Open directly in Godot Editor (Automatic Setup)
1. Open this folder in **Godot 4.7 Editor** and wait for the initial asset import (`.godot/` cache) to finish.
2. Press **Play (F5)**.
3. On first launch after a fresh clone, the game automatically detects if `engine/stockfish.exe` is missing and downloads **Stockfish 18** inside the Main Menu. Once complete, bots, engine arrows, and Game Review are ready to use.

### Option 2: Pre-setup via PowerShell (Stockfish + optional Maia-3)
Run from the repository root:
```powershell
.\setup_engines.ps1
```
This downloads `engine/stockfish.exe`, downloads the optional `engine/maia3-5m.pt` checkpoint, compiles `engine/maia3.exe`, and runs `godot --headless --path . --import` if `godot` is in your `PATH`.

> **Optional Maia-3 Python dependencies:** If you want human-like Maia-3 bot moves, install Python dependencies via:
> ```powershell
> pip install -r engine/maia3/requirements.txt
> ```
> Without Maia-3, the game automatically uses Stockfish 18 for all Elo levels.
