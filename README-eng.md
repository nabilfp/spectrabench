# SpectraBench v5.2.2 Omni-Platform

> Blazing fast, zero-dependency, cross-platform system benchmarking suite. Native Linux, WSL, macOS/BSD, Termux (Android), Windows (PowerShell + embedded C#).

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20WSL%20%7C%20macOS%20%7C%20Android%20%7C%20Windows-lightgrey)](#compatibility)
[![Language](https://img.shields.io/badge/Language-Bash%20%7C%20PowerShell-green)](#quick-start)

[Indonesian README](README.md)

## What's New in v5.2.2 (Critical Fixes)

**Shell (spectrabench.sh):**
- Cache probe: 32-bit index overflow → segfault (fixed: 64-bit indexing, O2/gnu99, working-set 64MB for RAM probe). Python fallback now uses `array('i')` (no 2.7GB OOM).
- Timer: guaranteed positive numbers; `_elapsed_since` guards; no awk syntax errors from empty timestamps.
- `dd` parser: handles scientific notation, `bytes/sec`, multiple units; detects truncated writes via byte count.
- Disk: detects `conv=fdatasync`/`oflag=direct`, uses fdatasync when available (true non-cache measurement).
- CPU: sustained load (min seconds/passes) to expose thermal throttling; scales safely on Termux/low-RAM.
- Network: validates payload size, wget fallback, robust ping parsing (`$?` masked fixed).
- Menu: drains TTY buffer, handles EOF (read returns non-zero) without infinite loop.
- Scoring: rejects empty/non-positive latency readings (previously could award phantom points).

**PowerShell (spectrabench.ps1):**
- CPU per-thread scaling capped 500–5000MB with proper total RAM guard.
- CPU fill: use `Buffer.BlockCopy` from seed (faster, OOM-safe) instead of slow `Random.NextBytes` over gigabyte arrays.
- RAM: chunked allocation, checksum touch, OOM guards.
- Disk: WriteThrough, reasonable space checks.
- Network: PS7-compatible Test-Connection, TLS 1.2, payload size validation.
- Added Cache parity (L1/L2/L3/RAM pointer-chasing, scoring).
- Menu: EOF/read exception handling.

## Quick Start

**Linux/WSL/macOS/Termux:**
```bash
sudo bash -c "$(curl -sL https://raw.githubusercontent.com/nabilfp/spectrabench/main/spectrabench.sh)"
```
(Termux: omit sudo)

**Windows (Admin PowerShell):**
```powershell
iex (irm "https://raw.githubusercontent.com/nabilfp/spectrabench/main/spectrabench.ps1")
```

## Verification

- `bash -n spectrabench.sh` passes
- `shellcheck -S warning` (only SC2155 benign style warnings noted)

## License

MIT License — see [LICENSE](LICENSE).
