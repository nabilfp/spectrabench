# 🚀 SpectraBench (v2.0 Multi-Threaded Edition)

> A blazing fast, zero-dependency, cross-platform system benchmarking tool. Designed for SysAdmins, Enthusiasts, and IT Professionals who need instant hardware validation without the bloatware.

![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Windows-lightgrey?style=flat-square)
![Language](https://img.shields.io/badge/Language-Bash%20%7C%20PowerShell-green?style=flat-square)
![Version](https://img.shields.io/badge/Version-2.0_Multi--Threaded-orange?style=flat-square)

---

## 📑 Table of Contents
- [The Philosophy](#-the-philosophy)
- [Preview](#-preview)
- [Quick Start (Ghost Mode)](#-quick-start-ghost-mode)
- [How It Works (The Engine & Metrics)](#️-how-it-works-the-engine--metrics)
- [Security & Transparency](#-security--transparency)
- [Project Roadmap](#-project-roadmap)

---

## 📖 The Philosophy

Most modern benchmark tools are fantastic, but they share a common flaw when it comes to rapid triage: **they are heavy**. They require gigabytes of downloads, GUI installations, and leave residual registry keys or temp files in your OS. 

**SpectraBench** solves this by utilizing a "Sister Scripts" architecture:
1. `spectrabench.sh` (Native Linux Bash)
2. `spectrabench.ps1` (Native Windows PowerShell)

Both scripts perform identical hardware-level stress tests and raw memory/storage I/O operations directly via the OS kernel. **No external dependencies. Just pure, native architecture.**

### ✨ Key Features
- **Zero Dependencies:** Runs on fresh OS installations out-of-the-box.
- **Ghost Mode Execution:** Executed directly in RAM without saving any files to the hard drive.
- **Thermal Detection [NEW]:** Detects system ACPI/WMI Thermal Zones to log pre-test and post-test CPU temperatures, actively flagging Thermal Throttling.
- **Ephemeral Testing:** All I/O test files are created in volatile memory (`/dev/shm` or `$env:TEMP`) and automatically purged upon completion or a `Ctrl+C` interrupt.

---

## 👀 Preview

```text
  ██████  ██▓███  ▓█████  ▄████▄  ▄▄▄█████▓ ██▀███   ▄▄▄       
▒██    ▒ ▓██░  ██▒▓█   ▀ ▒██▀ ▀█  ▓  ██▒ ▓▒▓██ ▒ ██▒▒████▄     
░ ▓██▄   ▓██░ ██▓▒▒███   ▒▓█    ▄ ▒ ▓██░ ▒░▓██ ░▄█ ▒▒██  ▀█▄   
  ▒   ██▒▒██▄█▓▒ ▒▒▓█  ▄ ▒▓▓▄ ▄██▒░ ▓██▓ ░ ▒██▀▀█▄  ░██▄▄▄▄██  
▒██████▒▒▒██▒ ░  ░░▒████▒▒ ▓███▀ ░  ▒██▒ ░ ░██▓ ▒██▒ ▓█   ▓██▒ 
░ ▒░▓  ░ ▒▓▒░ ░  ░░░ ▒░ ░░ ░▒ ▒  ░  ▒ ░░   ░ ▒▓ ░▒▓░ ▒▒   ▓▒█░ 
          v2.0 Multi-Threaded | Linux Native Edition         
===============================================================

[*] Gathering System Architecture...
  OS       : Ubuntu 24.04.4 LTS
  CPU      : AMD Ryzen 5 PRO 5650U with Radeon Graphics (12 Threads)
  RAM      : 14Gi

[*] Running Multi-Core Stress Test (SHA-256 on 12 Threads)...
  [V] Completed in 0.09106s -> Score: 1317741
  [ Thermals: 47°C -> 47°C ]

[*] Running Volatile Memory I/O Test (500MB to /dev/shm)...
  [V] Memory Speed: 2.8 GB/s -> Score: 34406

[*] Running Storage Drive I/O Test (500MB Sequential)...
  [V] Disk Speed: 1.4 GB/s -> Score: 11468
...

```

---

## ⚡ Quick Start (Ghost Mode)

Run the benchmark directly from the repository into your system's volatile memory.

### 🐧 For Linux (Debian, Ubuntu, RHEL, Arch)

Open your terminal and run:

```bash
curl -sL "https://raw.githubusercontent.com/nabilfp/spectrabench/main/spectrabench.sh" | sudo bash

```

### 🪟 For Windows (10, 11, Server)

Open **PowerShell as Administrator** and run:

```powershell
iex (irm "https://raw.githubusercontent.com/nabilfp/spectrabench/main/spectrabench.ps1")

```

---

## 🛠️ How It Works (The Engine & Metrics)

In order to provide true cross-platform parity without installing bulky frameworks, SpectraBench implements architecture-specific optimizations using OS-level compiled libraries:

1. **CPU Score (Parallel Cryptographic ALU):** The script auto-detects your system's logical cores/threads. It then spawns parallel background jobs (in Linux via `wait` fork, in Windows via Embedded C# `Parallel.For`), unleashing an aggressive 50MB SHA-256 Crypto calculation per thread simultaneously. The score scales dynamically based on core count and completion time.
2. **Thermal Throttling Probe:** Taps into Kernel WMI (Windows) and ACPI thermal zones (Linux) to record temperature spikes during the Multi-Core stress test. Flags red if it exceeds 85°C.
3. **RAM Score:** Streams a massive 500MB byte block directly into volatile memory (`/dev/shm` in Linux, `MemoryStream` in .NET), testing pure RAM bandwidth limits.
4. **Disk Score:** Forces a sequential write of 500MB to the primary storage drive. It strictly uses `fdatasync` (Linux) and `FileOptions.WriteThrough` (Windows) to aggressively bypass OS caching mechanisms, measuring true hardware write speed.

---

## 🛡️ Security & Transparency

**Why does SpectraBench require `sudo` (Linux) or `Administrator` (Windows)?**

* **Thermal Readings:** Fetching low-level hardware ACPI zones requires kernel/WMI administrative privileges.
* **Disk Benchmarking:** Bypassing the OS cache requires low-level kernel I/O access and WriteThrough flags.
* **RAM Benchmarking (Linux):** Writing massive chunks directly to `/dev/shm` requires elevated privileges.
* **Trace Destruction:** The script automatically deletes its own temporary 500MB payload files upon completion to keep your system clean.

*We encourage you to read the source code. It's 100% transparent, single-file, and contains zero telemetry.*

---

## 🗺️ Project Roadmap

* [x] **v1.0 (Core):** CPU Crypto Hashing, RAM, and Storage tests with cache-bypass architecture.
* [x] **v2.0 (Multi-Threading):** Implemented parallel background jobs to stress-test Multi-Core CPUs, plus thermal throttling detection.
* [ ] **v3.0 (Network Edge):** Global DNS latency checks and upload/download bandwidth testing.
* [ ] **v4.0 (Interactive Suite):** Modular testing menu and JSON export capabilities.
* [ ] **v5.0 (Leaderboard):** Webhook integration to push scores to Discord or Google Sheets.

---

Crafted with precision by [Nabil](https://github.com/nabilfp)
