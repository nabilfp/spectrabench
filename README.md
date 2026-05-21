# 🚀 SpectraBench (v1.1 Foundation)

> A blazing fast, zero-dependency, cross-platform system benchmarking tool. Designed for SysAdmins, Enthusiasts, and IT Professionals who need instant hardware validation without the bloatware.

![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Windows-lightgrey?style=flat-square)
![Language](https://img.shields.io/badge/Language-Bash%20%7C%20PowerShell-green?style=flat-square)
![Version](https://img.shields.io/badge/Version-1.1-orange?style=flat-square)

---

## 📑 Table of Contents
- [The Philosophy](#-the-philosophy)
- [Preview](#-preview)
- [Quick Start (Ghost Mode)](#-quick-start-ghost-mode)
- [Manual Execution](#-manual-execution)
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
- **Multilanguage (i18n):** Fully supports English, Bahasa Indonesia, and Mandarin (中文) via an interactive bootloader.
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
             v1.1 Foundation | Native Edition            
===============================================================

[*] Gathering System Architecture...
  OS       : Ubuntu 24.04 LTS
  CPU      : AMD Ryzen 7 (16 Cores)
  RAM      : 15Gi

[*] Running CPU Single-Core Test (Prime Sieve 100k)...
  [V] Completed in 0.842s -> Score: 59382
...

```

---

## ⚡ Quick Start (Ghost Mode)

You don't even need to `git clone`. Run the benchmark directly from the repository into your system's volatile memory.

### 🐧 For Linux (Debian, Ubuntu, RHEL, Arch)

Open your terminal and run:

```bash
curl -sL "[https://raw.githubusercontent.com/nabilfp/spectrabench/main/spectrabench.sh](https://raw.githubusercontent.com/nabilfp/spectrabench/main/spectrabench.sh)" | sudo bash

```

### 🪟 For Windows (10, 11, Server)

Open **PowerShell as Administrator** and run:

```powershell
iex (irm "[https://raw.githubusercontent.com/nabilfp/spectrabench/main/spectrabench.ps1](https://raw.githubusercontent.com/nabilfp/spectrabench/main/spectrabench.ps1)")

```

---

## 📥 Manual Execution

If you prefer to review the code before running it (which is always a good practice):

**Linux:**

```bash
git clone [https://github.com/nabilfp/spectrabench.git](https://github.com/nabilfp/spectrabench.git)
cd spectrabench
chmod +x spectrabench.sh
sudo ./spectrabench.sh

```

**Windows:**

```powershell
git clone [https://github.com/nabilfp/spectrabench.git](https://github.com/nabilfp/spectrabench.git)
cd spectrabench
Set-ExecutionPolicy Bypass -Scope Process -Force
.\spectrabench.ps1

```

---

## 🛠️ How It Works (The Metrics)

1. **CPU Score:** Executes a complex Prime Number Sieve (up to 100,000) using native math operators (`awk` in Linux, `for-loops` in PowerShell). Measures single-core logic, branching, and ALU (Arithmetic Logic Unit) performance.
2. **RAM Score:** Allocates and writes a massive byte array directly into volatile memory, testing RAM bandwidth and OS memory management overhead.
3. **Disk Score:** Forces a sequential write of 500MB to the primary storage drive. It uses `fdatasync` (Linux) and flush buffers (Windows) to bypass OS caching, measuring the true hardware write speed.

---

## 🛡️ Security & Transparency

**Why does SpectraBench require `sudo` (Linux) or `Administrator` (Windows)?**

* **Disk Benchmarking:** Bypassing the OS cache to measure true raw disk speed requires low-level kernel I/O access.
* **RAM Benchmarking (Linux):** Writing massive chunks directly to `/dev/shm` requires elevated privileges to prevent user-space memory limits from bottlenecking the test.
* **Trace Destruction:** The script automatically deletes its own temporary 500MB payload files upon completion to keep your system clean, which requires write/delete permissions in root temp directories.

*We encourage you to read the source code. It's 100% transparent, contained in a single file per OS, and contains absolutely zero telemetry.*

---

## 🗺️ Project Roadmap

We are continuously evolving SpectraBench to become the ultimate CLI benchmarking suite.

* [x] **v1.0 (Foundation):** Core CPU, RAM, and Storage tests.
* [x] **v1.1 (Multilanguage):** i18n support (English, Indonesian, Mandarin).
* [ ] **v2.0 (Multi-Threading):** Implement parallel background jobs to stress-test Multi-Core CPUs, plus thermal throttling detection.
* [ ] **v3.0 (Network Edge):** Global DNS latency checks and upload/download bandwidth testing.
* [ ] **v4.0 (Interactive Suite):** Modular testing menu (choose specific components to test) and JSON export capabilities.
* [ ] **v5.0 (Leaderboard):** Webhook integration to push scores to Discord or Google Sheets for team leaderboards.

---

**Crafted with precision by [Nabil**](https://github.com/nabilfp)

```

```
