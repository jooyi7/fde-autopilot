# ⚡ FDE-Autopilot: Deterministic-First (80/20) Rapid Prototyping & Audit Toolkit

An open-source engineering toolkit and architectural boilerplate designed for **Forward Deployed Engineers (FDE)** to rapidly build, profile, and verify data-intensive web applications under strict reliability constraints.

## Core Philosophy: The 80/20 Rule
1. **80% Deterministic Core (`src/core/`)**: All mathematical calculations, threshold evaluations (3-Sigma UCL/LCL), regex validations, and state transitions are executed via pure, deterministic functions.
2. **20% Resilient AI Interpretation (`src/ai/`)**: LLMs are strictly scoped to summarizing and explaining the deterministic output, guarded by an instant zero-crash fallback mechanism.

## Directory Overview
- `bootstrap.sh` : Workspace sanitizer and automated dataset profiler trigger.
- `engine/` : Dataset schema/null/3-sigma profiler (`workspace_profiler.py`), 3-preset deterministic test harness (`deterministic_harness.mjs`), and cross-session audit scripts.
- `docs_kit/` : Standardized engineering templates (`SPEC`, `CLAUDE`, `HANDOFF`).
- `blueprints/` : Production-ready full-stack reference architectures across 12 enterprise & manufacturing domains.