# 🚀 SpectraBench (v5.1 Omni-Platform)

> A blazing fast, zero-dependency, ultimate system benchmarking suite. Designed for SysAdmins, Enthusiasts, and IT Professionals who demand sustained stress-testing and true hardware validation across Servers, PCs, and Edge Devices without the bloatware.

![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Windows%20%7C%20Android%20%7C%20macOS%20%7C%20WSL-lightgrey?style=flat-square)
![Language](https://img.shields.io/badge/Language-Bash%20%7C%20PowerShell-green?style=flat-square)
![Version](https://img.shields.io/badge/Version-5.1_Omni--Platform-orange?style=flat-square)
![Audit](https://img.shields.io/badge/Security-Zero%20Telemetry%20%7C%20Single--File%20Audit-brightgreen?style=flat-square)

---

## 📑 Table of Contents

- [The Philosophy](#-the-philosophy)
- [What's New in v5.1](#-whats-new-in-v51)
- [Compatibility Matrix](#-compatibility-matrix)
- [Quick Start (Ghost Mode)](#-quick-start-ghost-mode)
- [How It Works (The Metrics)](#️-how-it-works-the-metrics)
- [Score Interpretation Guide](#-score-interpretation-guide)
- [Bug Fixes & Changelog](#-bug-fixes--changelog)
- [Troubleshooting & FAQ](#-troubleshooting--faq)
- [Strategic Roadmap](#-strategic-roadmap)
- [Security & Transparency](#-security--transparency)

---

## 📖 The Philosophy

Most modern benchmark tools require gigabytes of downloads, complex GUI installations, and leave residual files deeply embedded in your OS. **SpectraBench** solves this by utilizing a "Sister Scripts" architecture:

1. `spectrabench.sh` (Native Linux Bash & Termux Android)
2. `spectrabench.ps1` (Native Windows PowerShell + Embedded C#)

Both scripts perform identical hardware-level sustained stress tests directly via the OS kernel. **No external frameworks, no compiler installations. Just pure, native execution.**

**Ultra-Universal Design Principles:**
- **Zero Dependencies:** Runs on stock OS installations without `apt`, `brew`, or `choco`.
- **Auto-Scale Intelligence:** Dynamically adjusts test payload sizes based on available RAM and disk space.
- **Omni-Platform Detection:** Automatically detects Android (Termux), WSL, standard Linux, Windows Server, and macOS/BSD fallbacks.
- **Graceful Degradation:** If a test cannot run (e.g., missing `curl`, low disk space), it skips cleanly with a warning rather than crashing.

---

## 🌟 What's New in v5.1 (The Resilience Update)

### Critical Bug Fixes
- **MemoryStream Overflow (Windows):** Replaced the `MemoryStream` 2GB allocation (which hit .NET `int.MaxValue` hard-limit) with a **chunked byte-array engine** (256MB × 8 chunks). Eliminates `IOException: Stream was too long` on all Windows editions.
- **Universal DD Parser (Linux):** Replaced fragile "copied" keyword parsing with a **regex-based universal speed extractor** that understands all `dd` locale outputs: `GB/s`, `MB/s`, `kB/s`, and `bytes/sec`.
- **Spam-Input Loop Fix:** Empty or buffered keystrokes no longer trigger rapid-fire `Invalid selection` loops. The menu now **drains stale TTY buffers** and silently redraws on empty input.
- **Scientific Notation Bug:** Fixed `curl` speed parsing where high-speed downloads returned scientific notation (e.g., `1.23e+06`), causing score corruption.
- **Multi-Socket CPU Detection:** Fixed core-count calculation on dual-socket workstations where `Win32_Processor` returns an array.

### Enhancements
- **Smart Payload Scaling:** CPU test now calculates `needed = (5GB × cores) + 2GB reserve`. Only scales down when the **total system load** would genuinely exceed physical RAM.
- **Asia-First CDN:** Added `speedtest.tele2.net` and `DigitalOcean Singapore` to the network fallback chain for users behind restrictive ISPs.
- **BusyBox & macOS Compatibility:** Removed hard dependencies on GNU-specific `dd` flags (`status=none`, `conv=fdatasync`) and `date +%s.%N`. Added fallback chains for `sha256sum` → `shasum` → `openssl`.
- **Disk Space Guard:** Pre-flight check ensures at least 100MB of free temp space before writing; auto-scales the 5GB test down to `available - 500MB` margin.

---

## ✅ Compatibility Matrix

| Platform | Status | Admin Required | Tested On |
| :--- | :---: | :---: | :--- |
| **Ubuntu 22.04/24.04 LTS** | ✅ Full Support | `sudo` | AMD Ryzen 5 PRO, Intel i7-1185G7 |
| **Debian 12 / Arch / Fedora** | ✅ Full Support | `sudo` | Community verified |
| **Windows 10 / 11 Home & Pro** | ✅ Full Support | Administrator | Intel i3-1115G4, AMD Ryzen 7 |
| **Windows Server 2019/2022** | ✅ Full Support | Administrator | Azure VM, bare-metal |
| **Termux (Android 12–14)** | ✅ Full Support | None | Samsung Galaxy S23, Pixel 7 |
| **WSL2 (Ubuntu)** | ✅ Full Support | `sudo` | Windows 11 + WSL2 kernel |
| **macOS (Intel & Apple Silicon)** | ⚠️ Partial | None | RAM & CPU work; Disk uses temp dir instead of `/dev/shm` |
| **OpenWrt / BusyBox** | ⚠️ Partial | `root` | CPU & RAM only; Network limited by `wget` fallback |

> **Legend:** ✅ = All 4 tests functional. ⚠️ = Graceful degradation (some tests auto-skip or use fallbacks).

---

## 👀 Preview

```text
  ██████  ██▓███  ▓█████  ▄████▄  ▄▄▄█████▓ ██▀███   ▄▄▄       
▒██    ▒ ▓██░  ██▒▓█   ▀ ▒██▀ ▀█  ▓  ██▒ ▓▒▓██ ▒ ██▒▒████▄     
░ ▓██▄   ▓██░ ██▓▒▒███   ▒▓█    ▄ ▒ ▓██░ ▒░▓██ ░▄█ ▒▒██  ▀█▄   
  ▒   ██▒▒██▄█▓▒ ▒▒▓█  ▄ ▒▓▓▄ ▄██▒░ ▓██▓ ░ ▒██▀▀█▄  ░██▄▄▄▄██  
▒██████▒▒▒██▒ ░  ░░▒████▒▒ ▓███▀ ░  ▒██▒ ░ ░██▓ ▒██▒ ▓█   ▓██▒ 
░ ▒░▓  ░ ▒▓▒░ ░  ░░░ ▒░ ░░ ░▒ ▒  ░  ▒ ░░   ░ ▒▓ ░▒▓░ ▒▒   ▓▒█░ 
    v5.1 Omni-Platform Singularity Suite | Linux & Android       
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

### 🐧 For Linux, WSL, macOS & Termux (Debian, Ubuntu, Arch, Android)

Open your terminal and run the secure string-evaluation command:

```bash
# Note: For standard Linux/WSL, prefix with 'sudo'. For Termux (Android), run as is.
sudo bash -c "$(curl -sL https://raw.githubusercontent.com/nabilfp/spectrabench/main/spectrabench.sh)"
```

### 🪟 For Windows (10, 11, Server)

Open **PowerShell as Administrator** and run:

```powershell
iex (irm "https://raw.githubusercontent.com/nabilfp/spectrabench/main/spectrabench.ps1")
```

---

## 🛠️ How It Works (The Metrics)

1. **CPU Score (Cryptographic ALU):** Spawns parallel background jobs enforcing a sustained **SHA-256 calculation** per thread. The payload auto-scales from **500MB to 5GB per thread** depending on system RAM. The score mathematically scales based on core count and elapsed execution time. This separates short-burst turbo speeds from genuine sustained thermal performance.

2. **Thermal Throttling Probe:** Taps into Kernel WMI (Windows) and ACPI thermal zones (Linux) to record temperature spikes during the sustained test, flagging severe heat-soak states above **85°C**.

3. **RAM Score:** Allocates data directly into volatile memory using **chunked arrays** (bypassing the .NET 2GB array limit and `/dev/shm` size restrictions). Tests raw memory bus speed via write-and-touch allocation. On Android/Termux, it automatically falls back to a pure kernel-space zero-to-null pipe buffer.

4. **Disk Score:** Forces a massive sequential write to exhaust caching layers (`WriteThrough` on Windows; `fdatasync` or `sync` on Linux). Auto-scales from **256MB up to 5GB** based on free temp space, revealing true underlying NAND/SSD speeds after SLC cache depletion.

5. **Network Score:** Evaluates Cloudflare DNS ping latency and downloads a 100MB payload from a tiered CDN pool (Tele2 → OVH → Hetzner → DigitalOcean). Measures both **latency stability** and **real-world throughput**.

---

## 📊 Score Interpretation Guide

SpectraBench scores are **relative performance indices**, not absolute units. Use this table to contextualize your hardware:

| Component | Low-End | Mid-Range | High-End | Enthusiast / Workstation |
| :--- | :--- | :--- | :--- | :--- |
| **CPU Score** | < 2,000 | 2,000 – 5,000 | 5,000 – 12,000 | > 12,000 |
| **RAM Score** | < 1,500 | 1,500 – 3,000 | 3,000 – 6,000 | > 6,000 |
| **Disk Score** | < 2,000 | 2,000 – 8,000 | 8,000 – 20,000 | > 20,000 |
| **Network Score** | < 50 | 50 – 150 | 150 – 400 | > 400 |
| **TOTAL** | < 6,000 | 6,000 – 16,000 | 16,000 – 35,000 | > 35,000 |

**Examples:**
- **Intel i3-1115G4 (4T) + SATA SSD:** ~5,000 – 8,000 Total
- **AMD Ryzen 5 PRO 5650U (12T) + NVMe:** ~20,000 – 25,000 Total
- **AMD Ryzen 9 7950X (32T) + PCIe 4.0 NVMe:** > 50,000 Total

> **Note:** Network score is highly dependent on your ISP and geographic location, not local hardware.

---

## 🩹 Bug Fixes & Changelog

### v5.0 → v5.1 (Resilience Update)

| Issue | Severity | Description | Resolution |
| :--- | :---: | :--- | :--- |
| **PowerShell MemoryStream Crash** | 🔴 Critical | `Stream was too long` + `Divide by zero` on Windows when allocating 2GB via `MemoryStream` | Replaced with **chunked byte-array engine** (256MB × N chunks) |
| **Linux DD Parsing Failure** | 🔴 Critical | RAM & Disk tests returned `0` on Ubuntu 24.04 because `dd` output did not contain the keyword "copied" | Implemented **regex universal parser** supporting all locale formats |
| **Spam Input Loop** | 🟡 Major | Rapid invalid selection loop when keys were pressed during benchmark or sleep | Added **TTY buffer drain** + silent redraw on empty input |
| **curl Scientific Notation** | 🟡 Major | High-speed downloads returned `1.23e+06` bytes/sec, breaking string-based parsers | Switched to `awk` numeric parsing with native scientific notation support |
| **Multi-Socket Core Count** | 🟡 Major | Dual-socket systems reported only 1 socket's worth of cores | Fixed with `Measure-Object -Sum` aggregation |
| **BusyBox Incompatibility** | 🟢 Minor | Termux/BusyBox `dd` rejected `status=none` and `conv=fdatasync` | Added **feature detection**; flags used only if supported |
| **macOS Date Nanosecond** | 🟢 Minor | `date +%s.%N` unsupported on macOS/BSD, breaking timing | Added fallback chain: `python` → `perl` → `EPOCHREALTIME` → `date +%s` |
| **SHA-256 Missing** | 🟢 Minor | macOS lacks `sha256sum` by default | Fallback chain: `sha256sum` → `shasum` → `openssl` |
| **Disk Space Crash** | 🟢 Minor | 5GB write attempted on systems with < 5GB free temp space | Added **pre-flight `df` check** with auto-scale to `available - 500MB` |

---

## 🧰 Troubleshooting & FAQ

### Q: Why does SpectraBench require `sudo` (Linux) or `Administrator` (Windows)?

**A:** Three reasons:
1. **Thermal Readings:** Fetching low-level hardware ACPI/WMI zones requires administrative kernel privileges.
2. **Disk Benchmarking:** Bypassing the OS cache to write raw data requires low-level I/O access and `WriteThrough` flags.
3. **RAM Allocation (Linux):** Writing massive chunks directly to `/dev/shm` bypasses user-space limitations.

### Q: The script says "RAM test failed to measure speed." What do I do?

**A:** This usually means `dd` produced an unexpected output format. SpectraBench v5.1 now prints the **raw `dd` output** for debugging. Please open an issue and paste that raw output — we will update the universal parser.

### Q: My CPU test only uses 500MB per thread instead of 5GB. Is this a bug?

**A:** No — this is the **Auto-Scale Intelligence** at work. If your system has limited RAM, the script calculates:
```
needed = (5GB × cores) + 2GB OS reserve
```
If `needed` exceeds your physical RAM, it scales down proportionally to prevent swap thrashing and OOM kills. The minimum per-thread payload is **500MB**.

### Q: Can I run this on a VPS or container (Docker/LXC)?

**A:** Yes, with caveats:
- **CPU & RAM** work perfectly.
- **Disk** will benchmark the container's overlay filesystem, not the host's physical disk.
- **Network** measures the container's virtual NIC throughput.
- **Thermal** readings may be unavailable if the hypervisor hides ACPI zones.

### Q: The network speed is very slow (0.1–0.5 MB/s) but my internet is fast.

**A:** This is usually **ISP throttling or CDN blocking**, not a bug. SpectraBench tries 4 CDN endpoints. If all are slow, your route to Europe may be congested. The score still reflects real-world conditions. You can verify by running `curl -o /dev/null https://speedtest.tele2.net/100MB.zip` manually.

### Q: How do I uninstall SpectraBench?

**A:** Nothing to uninstall. SpectraBench is **ephemeral by design**. It writes temporary files to `/tmp`, `/dev/shm`, or `%TEMP%` and deletes them automatically. No registry entries, no background services, no residual directories.

### Q: Can I pipe the output to a log file?

**A:** Yes, but use the **local file mode** instead of Ghost Mode for non-interactive logging:
```bash
sudo bash spectrabench.sh 2>&1 | tee spectra_log.txt
```
> Note: Piping directly via `curl | bash` is blocked by design because the interactive menu requires a real TTY.

---

## 🗺️ Strategic Roadmap

SpectraBench is continuously evolving to push the boundaries of script-based system telemetry, focusing on deeper accuracy, broader metrics, and extreme edge portability.

| Phase | Focus Area | Planned / Completed Upgrades |
| :--- | :--- | :--- |
| **Phase 1** | **The Foundation** | <ul><li>✅ Zero-dependency core logic (CPU, RAM, Disk, Network).</li><li>✅ Multi-threaded parallel execution.</li><li>✅ Omni-Platform Environment AI (Termux/Mobile support).</li><li>✅ Auto-Scale Intelligence (RAM & Disk payload adaptation).</li><li>✅ Universal DD Parser (all locale compatibility).</li></ul> |
| **Phase 2** | **Hyper-Precision** | <ul><li>🔄 **L1/L2/L3 Cache Profiling:** Shifting from pure RAM bandwidth to measuring nanosecond latency in CPU caches using pointer-chasing algorithms.</li><li>🔄 **Thermal Curve Analytics:** Logging temperature *over time* (1-second granularity) rather than just start/end points to detect micro-throttling patterns.</li><li>🔄 **JSON Telemetry Export:** Allowing SysAdmins to pipe benchmark results directly into log servers (Datadog/Grafana/InfluxDB) via optional `--json` flag.</li><li>🔄 **Cross-Platform Score Normalization:** Database of baseline scores per CPU generation to calculate a "Percentile Rank" instead of raw index.</li></ul> |
| **Phase 3** | **Extreme Edge** | <ul><li>⏳ **IoT / Router Support:** Optimizing the Bash engine to run natively on OpenWrt routers, embedded Raspberry Pi Zero 2W, and ARM64 SBCs with < 512MB RAM.</li><li>⏳ **Power Efficiency Metrics:** Correlating CPU scores with real-time battery drain (Watts) on mobile devices and laptops to generate an Efficiency Index (Performance-per-Watt).</li><li>⏳ **GPU Compute Fallback:** Exploring native OS APIs (OpenCL via `clinfo` / DirectX via WARP) to stress-test integrated and discrete graphics alongside the CPU.</li><li>⏳ **Container-Aware Mode:** Detecting Docker/LXC/cgroups and reporting whether scores reflect bare-metal or virtualized performance.</li></ul> |

> **Legend:** ✅ = Completed | 🔄 = In Active Development | ⏳ = Planned / Research Phase

---

## 🛡️ Security & Transparency

**Why trust a script that asks for Administrator privileges?**

Because you can **audit every line**.

- **Single-File Architecture:** Each script is entirely self-contained. No hidden imports, no downloaded modules, no obfuscated strings.
- **Zero Telemetry:** No outbound connections except to the 4 public CDN endpoints during the Network test. No UUID collection, no hardware fingerprinting, no analytics pings.
- **Ephemeral Design:** All temporary multi-gigabyte payload files are automatically deleted upon completion or Ctrl+C interruption (`trap` / `finally` blocks).
- **Open Source:** MIT Licensed. Every hash, every byte allocation, and every thermal read is visible in plain text.

**We encourage security researchers to read the source code.** It is 100% transparent, contained in single architecture-specific files, and possesses zero hidden telemetry.

---

## 📜 License

MIT License — see [LICENSE](LICENSE) for full details.

---

Crafted with precision by [Nabil](https://github.com/nabilfp)

> *"Benchmarks should validate hardware, not install bloatware."*
