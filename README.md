# 🚀 SpectraBench (v5.0 Omni-Platform)

> A blazing fast, zero-dependency, ultimate system benchmarking suite. Designed for SysAdmins, Enthusiasts, and IT Professionals who demand sustained stress-testing and true hardware validation across Servers, PCs, and Edge Devices without the bloatware.

![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Windows%20%7C%20Android-lightgrey?style=flat-square)
![Language](https://img.shields.io/badge/Language-Bash%20%7C%20PowerShell-green?style=flat-square)
![Version](https://img.shields.io/badge/Version-5.0_Omni--Platform-orange?style=flat-square)

---

## 📑 Table of Contents
- [The Philosophy](#-the-philosophy)
- [New in v5.0](#-new-in-v50)
- [Quick Start (Ghost Mode)](#-quick-start-ghost-mode)
- [How It Works (The Metrics)](#️-how-it-works-the-metrics)
- [Strategic Roadmap](#-strategic-roadmap)
- [Security & Transparency](#-security--transparency)

---

## 📖 The Philosophy

Most modern benchmark tools require gigabytes of downloads, complex GUI installations, and leave residual files deeply embedded in your OS. **SpectraBench** solves this by utilizing a "Sister Scripts" architecture:

1. `spectrabench.sh` (Native Linux Bash & Termux Android)
2. `spectrabench.ps1` (Native Windows PowerShell + Embedded C#)

Both scripts perform identical hardware-level sustained stress tests directly via the OS kernel. **No external frameworks, no compiler installations. Just pure, native execution.**

---

## 🌟 New in v5.0 (The Singularity Update)
- **Omni-Platform AI:** The Linux script intelligently detects Android environments (`Termux`) to dynamically adapt filesystem paths and kernel permissions, enabling pure hardware testing on mobile ARM chips without root access.
- **The Singularity Load (Sustained Stress):** CPU payloads are aggressively increased to **5GB of Cryptographic Hashing per thread**. This enforces a true sustained thermal load, separating short-burst turbo speeds from genuine, long-term hardware Thermal Throttling.
- **Massive I/O Exhaustion:** Disk tests now enforce 5GB sustained writes to entirely deplete SSD/UFS SLC caches, revealing true underlying NAND speeds.
- **TTY-Safe Interactive UI:** A robust, pipeline-safe interactive terminal menu prevents execution loops when triggered via remote web requests (`curl`).

---

## 👀 Preview

```text
  ██████  ██▓███  ▓█████  ▄████▄  ▄▄▄█████▓ ██▀███   ▄▄▄       
▒██    ▒ ▓██░  ██▒▓█   ▀ ▒██▀ ▀█  ▓  ██▒ ▓▒▓██ ▒ ██▒▒████▄     
░ ▓██▄   ▓██░ ██▓▒▒███   ▒▓█    ▄ ▒ ▓██░ ▒░▓██ ░▄█ ▒▒██  ▀█▄   
  ▒   ██▒▒██▄█▓▒ ▒▒▓█  ▄ ▒▓▓▄ ▄██▒░ ▓██▓ ░ ▒██▀▀█▄  ░██▄▄▄▄██  
▒██████▒▒▒██▒ ░  ░░▒████▒▒ ▓███▀ ░  ▒██▒ ░ ░██▓ ▒██▒ ▓█   ▓██▒ 
░ ▒░▓  ░ ▒▓▒░ ░  ░░░ ▒░ ░░ ░▒ ▒  ░  ▒ ░░   ░ ▒▓ ░▒▓░ ▒▒   ▓▒█░ 
    v5.0 Omni-Platform Singularity Suite | Linux & Android       
=================================================================

[*] Gathering System Architecture...
  OS       : Ubuntu 24.04 LTS
  CPU      : AMD Ryzen 5 PRO 5650U with Radeon Graphics (12 Threads)
  RAM      : 14Gi

Select an operation to perform:
  1. 🚀 Run Full Singularity Benchmark Suite
  2. 🧠 Test CPU (5GB Singularity Multi-Core Load)
  3. ⚡ Test RAM (Allocation Latency & Bandwidth)
  4. 💾 Test Storage (5GB SLC Cache Exhaustion)
  5. 🌐 Test Network (Global Edge & 100MB CDN)
  0. ❌ Exit
-----------------------------------------------------------------

```

---

## ⚡ Quick Start (Ghost Mode)

Execute the benchmark directly from the repository into your system's volatile memory. No files are permanently saved to your drive.

### 🐧 For Linux & Termux (Debian, Ubuntu, Arch, Android)

Open your terminal and run the secure string-evaluation command:

```bash
# Note: For standard Linux, prefix with 'sudo'. For Termux (Android), run as is.
sudo bash -c "$(curl -sL https://raw.githubusercontent.com/nabilfp/spectrabench/main/spectrabench.sh)"

```

### 🪟 For Windows (10, 11, Server)

Open **PowerShell as Administrator** and run:

```powershell
iex (irm "https://raw.githubusercontent.com/nabilfp/spectrabench/main/spectrabench.ps1")

```

---

## 🛠️ How It Works (The Metrics)

1. **CPU Score (Cryptographic ALU):** Spawns parallel background jobs enforcing a brutal **5GB SHA-256 Crypto calculation per thread**. The score mathematically scales based on core count and elapsed execution time.
2. **Thermal Throttling Probe:** Taps into Kernel WMI (Windows) and ACPI thermal zones (Linux) to record temperature spikes during the sustained test, flagging severe heat-soak states.
3. **RAM Score:** Allocates 2GB of data directly into volatile memory. On standard OS, it utilizes `/dev/shm` and `MemoryStream`. On Android/Termux, it automatically falls back to a pure zero-to-null Kernel Memory pipe buffer to test raw memory bus speed securely.
4. **Disk Score:** Forces a massive sequential write of 5GB to exhaust caching layers (`fdatasync` and `WriteThrough`).
5. **Network Score:** Evaluates Cloudflare DNS ping latency and forcefully downloads a 100MB CDN payload to memory.

---
## 🗺️ Strategic Roadmap

SpectraBench is continuously evolving to push the boundaries of script-based system telemetry, focusing on deeper accuracy, broader metrics, and extreme edge portability.

| Phase | Focus Area | Planned / Completed Upgrades |
| :--- | :--- | :--- |
| **Phase 1** | **The Foundation** | <ul><li>✅ Zero-dependency core logic (CPU, RAM, Disk).</li><li>✅ Multi-threaded parallel execution.</li><li>✅ Omni-Platform Environment AI (Termux/Mobile support).</li></ul> |
| **Phase 2** | **Hyper-Precision** | <ul><li>⏳ **L1/L2/L3 Cache Profiling:** Shifting from pure RAM bandwidth to measuring nanosecond latency in CPU caches.</li><li>⏳ **Thermal Curve Analytics:** Logging temperature *over time* rather than just start/end points to detect micro-throttling.</li><li>⏳ **JSON Telemetry Export:** Allowing SysAdmins to pipe benchmark results directly into log servers (Datadog/Grafana).</li></ul> |
| **Phase 3** | **Extreme Edge** | <ul><li>⏳ **IoT / Router Support:** Optimizing the Bash engine to run natively on OpenWrt routers and embedded Raspberry Pi controllers.</li><li>⏳ **Power Efficiency Metrics:** Correlating CPU scores with real-time battery drain (Watts) on mobile devices to score hardware efficiency.</li><li>⏳ **GPU Compute Fallback:** Exploring native OS APIs to stress-test integrated graphics alongside the CPU.</li></ul> |
---

## 🛡️ Security & Transparency

**Why does SpectraBench require `sudo` (Linux) or `Administrator` (Windows)?**

* **Thermal Readings:** Fetching low-level hardware ACPI/WMI zones requires administrative kernel privileges.
* **Disk Benchmarking:** Bypassing the OS cache to write raw data requires low-level I/O access and WriteThrough flags.
* **RAM Allocation (Linux):** Writing massive chunks directly to `/dev/shm` bypasses user-space limitations.
* **Ephemeral Design:** The script requires permission to automatically delete its own temporary multi-gigabyte payload files upon completion to keep your system meticulously clean.

*We encourage you to read the source code. It is 100% transparent, contained in single architecture-specific files, and possesses zero hidden telemetry.*

---

Crafted with precision by [Nabil](https://github.com/nabilfp)
