# 🚀 SpectraBench (v1.0 Core Edition)

> A blazing fast, zero-dependency, cross-platform system benchmarking tool. Designed for SysAdmins, Enthusiasts, and IT Professionals who need instant hardware validation without the bloatware.

![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Windows-lightgrey?style=flat-square)
![Language](https://img.shields.io/badge/Language-Bash%20%7C%20PowerShell-green?style=flat-square)
![Version](https://img.shields.io/badge/Version-1.0_Core-orange?style=flat-square)

---

## 📑 Table of Contents
- [The Philosophy](#-the-philosophy)
- [Preview](#-preview)
- [Quick Start (Ghost Mode)](#-quick-start-ghost-mode)
- [How It Works (The Metrics)](#️-how-it-works-the-metrics)
- [Security & Transparency](#-security--transparency)
- [Project Roadmap](#-project-roadmap)

---

## 📖 The Philosophy

Most modern benchmark tools are fantastic, but they share a common flaw when it comes to rapid triage: **they are heavy**. They require gigabytes of downloads, GUI installations, and leave residual registry keys or temp files in your OS. 

**SpectraBench** solves this by utilizing a "Sister Scripts" architecture:
1. `spectrabench.sh` (Native Linux Bash & AWK)
2. `spectrabench.ps1` (Native Windows PowerShell)

Both scripts perform identical mathematical stress tests and raw memory/storage I/O operations directly via the OS kernel. **No Python, No C++, No Java required. Just pure, native scripting.**

### ✨ Key Features
- **Zero Dependencies:** Runs on fresh OS installations out-of-the-box.
- **Ghost Mode Execution:** Can be executed directly in RAM without saving any files to the hard drive.
- **Enterprise Standard:** Pure English CLI interface focused on speed, accuracy, and telemetry.
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
             v1.0 Core | Linux Native Edition            
===============================================================

[*] Gathering System Architecture...
  OS       : Ubuntu 24.04.4 LTS
  CPU      : AMD Ryzen 5 PRO 5650U with Radeon Graphics (12 Cores)
  RAM      : 14Gi

[*] Running CPU Single-Core Test (Prime Sieve 100k)...
  [V] Completed in 0.24052s -> Score: 207882

[*] Running Volatile Memory I/O Test (500MB to /dev/shm)...
  [V] Memory Speed: 1.4 GB/s -> Score: 17203
...

```

---

## ⚡ Quick Start (Ghost Mode)

You don't even need to `git clone`. Run the benchmark directly from the repository into your system's volatile memory.

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

## 🛠️ How It Works (The Metrics)

1. **CPU Score:** Executes a complex Prime Number Sieve (up to 100,000) using native math operators (`awk` in Linux, `for-loops` in PowerShell). Measures single-core logic, branching, and ALU (Arithmetic Logic Unit) performance.
2. **RAM Score:** Streams a massive 500MB byte block directly into volatile memory (`/dev/shm` in Linux, `MemoryStream` in .NET), testing pure RAM bandwidth limits.
3. **Disk Score:** Forces a sequential write of 500MB to the primary storage drive. It strictly uses `fdatasync` (Linux) and `FileOptions.WriteThrough` (Windows) to aggressively bypass OS caching mechanisms, measuring true hardware write speed.

---

## 🛡️ Security & Transparency

**Why does SpectraBench require `sudo` (Linux) or `Administrator` (Windows)?**

* **Disk Benchmarking:** Bypassing the OS cache to measure true raw disk speed requires low-level kernel I/O access and WriteThrough flags.
* **RAM Benchmarking (Linux):** Writing massive chunks directly to `/dev/shm` requires elevated privileges to prevent user-space memory limits from bottlenecking the test.
* **Trace Destruction:** The script automatically deletes its own temporary 500MB payload files upon completion to keep your system clean, which requires write/delete permissions in system temp directories.

*We encourage you to read the source code. It's 100% transparent, contained in a single file per OS, and contains absolutely zero telemetry.*

---

## 🗺️ Project Roadmap

We are continuously evolving SpectraBench to become the ultimate CLI benchmarking suite.

* [x] **v1.0 (Core):** Core CPU, RAM, and Storage tests with cache-bypass architecture.
* [ ] **v2.0 (Multi-Threading):** Implement parallel background jobs to stress-test Multi-Core CPUs, plus thermal throttling detection.
* [ ] **v3.0 (Network Edge):** Global DNS latency checks and upload/download bandwidth testing.
* [ ] **v4.0 (Interactive Suite):** Modular testing menu (choose specific components to test) and JSON export capabilities.
* [ ] **v5.0 (Leaderboard):** Webhook integration to push scores to Discord or Google Sheets for team leaderboards.

---

**Crafted with precision by [Nabil**](https://github.com/nabilfp)

```
