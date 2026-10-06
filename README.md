# SpectraBench v5.2.2 Omni-Platform

> Suite benchmarking sistem zero-dependency, cepat, dan aman untuk validasi hardware berkelanjutan (CPU/RAM/Disk/Network/Cache). Berjalan native di Linux, WSL, macOS/BSD, Termux (Android), dan Windows (PowerShell + C# ter-embed).

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20WSL%20%7C%20macOS%20%7C%20Android%20%7C%20Windows-lightgrey)](#kompatibilitas)
[![Language](https://img.shields.io/badge/Language-Bash%20%7C%20PowerShell-green)](#mode-ghost)

[English README](README-eng.md)

## Daftar Isi

- [Filosofi](#filosofi)
- [Apa yang Baru di v5.2.2](#apa-yang-baru-di-v522)
- [Kompatibilitas](#kompatibilitas)
- [Quick Start](#quick-start)
- [Cara Kerja](#cara-kerja)
- [Interpretasi Skor](#interpretasi-skor)
- [Perbaikan Bug & Changelog](#perbaikan-bug--changelog)
- [Troubleshooting & FAQ](#troubleshooting--faq)
- [Keamanan & Transparansi](#keamanan--transparansi)
- [Lisensi](#lisensi)

## Filosofi

SpectraBench menggunakan arsitektur "sister scripts":
1. `spectrabench.sh` (Linux/Bash, WSL, macOS/BSD, Termux)
2. `spectrabench.ps1` (Windows PowerShell + C# ter-embed)

Prinsip: zero-dependency, auto-scaling berdasarkan RAM/disk, graceful degradation, dan ephemeral (semua file temporer dibersihkan otomatis).

## Apa yang Baru di v5.2.2

- **CPU Sustained Load**: Mengulangi pass hingga mencapai minimum durasi/iterasi untuk mendeteksi thermal throttling, bukan burst sesaat.
- **Cache Latency Profiling (paritas)**: Pointer-chasing berbasis C (dengan fallback Python yang hemat memori, `array('i')` menggantikan `list[int]`).
- **Parser `dd` Universal**: Mendukung notasi ilmiah (`1.23e+06`), berbagai format satuan (`MB/s`, `GB/s`, `bytes/sec`), dan deteksi truncation (jumlah byte).
- **Flush Disk**: Deteksi `conv=fdatasync`/`oflag=direct`, pakai `fdatasync` jika tersedia (mengukur kecepatan non-page-cache).
- **Network Robust**: Validasi ukuran payload >=50MB, fallback wget, perbaikan parsing HTTP.
- **Menu Robust**: Drain buffer TTY, handle EOF (Ctrl-D) tanpa infinite loop.
- **RAM/Scoring**: Verifikasi byte count, perbaikan pembagian dengan nilai kosong -> skor 0 (bukan 2500 poin palsu).

## Kompatibilitas

| Platform | Status | Privilege | Catatan |
|---|---|---|---|
| Ubuntu/Debian/Fedora/Arch | ✅ Full | sudo (Linux) | Semua tes jalan |
| WSL2 | ✅ Full | sudo | Label OS terdeteksi |
| Termux (Android) | ✅ Full | Tanpa sudo | Gunakan Bash langsung |
| macOS (Intel/Apple Silicon) | ⚠️ Partial | Tanpa root | Cache via C/Python, disk buffered bila fdatasync tidak ada |
| Windows 10/11/Server | ✅ Full | Administrator | PowerShell + C# embedded |

## Quick Start

### Linux/WSL/macOS/Termux
```bash
sudo bash -c "$(curl -sL https://raw.githubusercontent.com/nabilfp/spectrabench/main/spectrabench.sh)"
```

Termux: jalankan tanpa `sudo`.

### Windows (PowerShell sebagai Administrator)
```powershell
iex (irm "https://raw.githubusercontent.com/nabilfp/spectrabench/main/spectrabench.ps1")
```

## Cara Kerja

1. **CPU** – Multi-thread SHA-256 berkelanjutan (auto-scale 500MB–5GB/thread). Sustained pass mencegah bias burst.
2. **RAM** – Alokasi chunked (hindari limit 2GB), traversal untuk touch memori.
3. **Disk** – Sequential write (5GB target, auto-scale), mendeteksi `fdatasync`/`oflag=direct` untuk mengukur true disk speed (bukan page-cache).
4. **Network** – Ping Cloudflare (1.1.1.1), download 100MB dari CDN berjenjang (validasi ukuran payload).
5. **Cache** – Pointer-chasing L1/L2/L3/RAM (ns/access). Native C, fallback Python `array('i')`.

## Interpretasi Skor

| Komponen | Low-End | Mid-Range | High-End | Enthusiast |
|---|---|---|---|---|
| CPU | < 2,000 | 2,000–5,000 | 5,000–12,000 | > 12,000 |
| RAM | < 1,500 | 1,500–3,000 | 3,000–6,000 | > 6,000 |
| Disk | < 2,000 | 2,000–8,000 | 8,000–20,000 | > 20,000 |
| Network | < 50 | 50–150 | 150–400 | > 400 |
| Cache | (relatif) | — | — | — |

## Perbaikan Bug & Changelog

Lihat `README-eng.md` untuk detail teknis v5.2.2.

## Keamanan & Transparansi

- Single-file, bisa diaudit full.
- Zero telemetry, hanya koneksi CDN saat test Network.
- Ephemeral: semua file temporer terhapus otomatis (trap cleanup).
- MIT Licensed.

## Lisensi

MIT License — lihat [LICENSE](LICENSE).
