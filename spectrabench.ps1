<#
.SYNOPSIS
Project      : SpectraBench (v5.2.2-OmniPlatform Singularity)
Description  : Zero-Dependency Ultimate System Benchmark
Author       : Nabil
Architecture : PowerShell + Embedded C#, Sustained Singularity Stress, Cache Profiling
#>

# --- [ REQUIRE ADMIN ] ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] Access Denied. SpectraBench requires Administrator privileges (Run as Admin)." -ForegroundColor Red
    Exit
}

$Host.UI.RawUI.WindowTitle = "SpectraBench v5.2.2 (Windows Edition)"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- [ THE ENGINE: SUSTAINED SINGULARITY INJECTION ] ---
$csharpCode = @"
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Security.Cryptography;
using System.Threading.Tasks;

public class SpectraDeepCore {
    public static double RunCpu(int cores, int mbPerThread) {
        Stopwatch sw = Stopwatch.StartNew();
        int bytes = mbPerThread * 1024 * 1024;
        byte[] buf = new byte[64 * 1024];
        new Random(42).NextBytes(buf);
        Parallel.For(0, cores, i => {
            byte[] data = new byte[bytes];
            int filled = 0;
            while (filled < bytes) {
                int take = buf.Length < (bytes - filled) ? buf.Length : (bytes - filled);
                Buffer.BlockCopy(buf, 0, data, filled, take);
                filled += take;
            }
            using (SHA256 sha = SHA256.Create()) {
                for(int j=0; j<50; j++) { sha.ComputeHash(data); }
            }
        });
        sw.Stop();
        return sw.Elapsed.TotalSeconds <= 0 ? 0.001 : sw.Elapsed.TotalSeconds;
    }

    public static double RunRam(int chunkCount, int chunkSizeMB) {
        Stopwatch sw = Stopwatch.StartNew();
        int chunkSize = chunkSizeMB * 1024 * 1024;
        List<byte[]> chunks = new List<byte[]>(chunkCount);
        byte[] seed = new byte[4096];
        new Random(42).NextBytes(seed);
        for (int i = 0; i < chunkCount; i++) {
            byte[] chunk = new byte[chunkSize];
            int filled = 0;
            while (filled < chunkSize) {
                int take = seed.Length < (chunkSize - filled) ? seed.Length : (chunkSize - filled);
                Buffer.BlockCopy(seed, 0, chunk, filled, take);
                filled += take;
            }
            chunks.Add(chunk);
        }
        long checksum = 0;
        foreach (var chunk in chunks) {
            for (int i = 0; i < chunk.Length; i += 4096) {
                checksum += chunk[i];
            }
        }
        sw.Stop();
        chunks.Clear();
        GC.Collect();
        return sw.Elapsed.TotalSeconds <= 0 ? 0.001 : sw.Elapsed.TotalSeconds;
    }
}
"@

try {
    if (-not ("SpectraDeepCore" -as [type])) {
        Add-Type -TypeDefinition $csharpCode -Language CSharp
    }
} catch {
    Write-Host "[!] Failed to compile benchmark engine. Error: $_" -ForegroundColor Red
    Exit
}

# --- [ GLOBAL VARIABLES ] ---
$procInfo = Get-CimInstance Win32_Processor
$script:cores = ($procInfo | Measure-Object NumberOfLogicalProcessors -Sum).Sum
if ($script:cores -le 0) { $script:cores = 1 }

$sysInfo = Get-CimInstance Win32_ComputerSystem
$totalRamBytes = $sysInfo.TotalPhysicalMemory
$totalRamGB = [math]::Round($totalRamBytes / 1GB, 2)

$availableRamMB = [math]::Floor($totalRamBytes / 1MB)
$minOsReserveMB = 2048

$script:cpuMBperThread = 5000
$maxCpuTotalMB = [math]::Max(512, $availableRamMB - $minOsReserveMB)
$safeCpuMBperThread = [math]::Floor($maxCpuTotalMB / $script:cores)
if ($safeCpuMBperThread -lt 500) { $safeCpuMBperThread = 500 }
if ($safeCpuMBperThread -gt 5000) { $safeCpuMBperThread = 5000 }
$script:cpuMBperThread = $safeCpuMBperThread

$script:cpuMinSeconds = 8
$script:cpuMaxPasses = 6

$script:ramChunkSizeMB = 256
$script:ramChunkCount = 8
$maxRamTestMB = [math]::Floor(($availableRamMB - $minOsReserveMB) / 2)
if ($maxRamTestMB -lt 512) {
    $script:ramChunkCount = [math]::Max(2, [math]::Floor($maxRamTestMB / $script:ramChunkSizeMB))
    if ($script:ramChunkCount -lt 2) { $script:ramChunkCount = 2 }
}

$script:scoreCpu = 0; $script:scoreRam = 0; $script:scoreDisk = 0; $script:scoreNet = 0; $script:scoreCache = 0
$script:cacheL1 = "N/A"; $script:cacheL2 = "N/A"; $script:cacheL3 = "N/A"; $script:cacheRam = "N/A"

function Draw-Banner {
    Clear-Host
    Write-Host "  ██████  ██▓███  ▓█████  ▄████▄  ▄▄▄█████▓ ██▀███   ▄▄▄       " -ForegroundColor Magenta
    Write-Host "▒██    ▒ ▓██░  ██▒▓█   ▀ ▒██▀ ▀█  ▓  ██▒ ▓▒▓██ ▒ ██▒▒████▄     " -ForegroundColor Magenta
    Write-Host "░ ▓██▄   ▓██░ ██▓▒▒███   ▒▓█    ▄ ▒ ▓██░ ▒░▓██ ░▄█ ▒▒██  ▀█▄   " -ForegroundColor Magenta
    Write-Host "  ▒   ██▒▒██▄█▓▒ ▒▒▓█  ▄ ▒▓▓▄ ▄██▒░ ▓██▓ ░ ▒██▀▀█▄  ░██▄▄▄▄██  " -ForegroundColor Magenta
    Write-Host "▒██████▒▒▒██▒ ░  ░░▒████▒▒ ▓███▀ ░  ▒██▒ ░ ░██▓ ▒██▒ ▓█   ▓██▒ " -ForegroundColor Magenta
    Write-Host "░ ▒░▓  ░ ▒▓▒░ ░  ░░░ ▒░ ░░ ░▒ ▒  ░  ▒ ░░   ░ ▒▓ ░▒▓░ ▒▒   ▓▒█░ " -ForegroundColor Magenta
    Write-Host "    v5.2.2 Omni-Platform Singularity Suite | Windows Edition       " -ForegroundColor Cyan
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Get-SysInfo {
    try { $os = (Get-CimInstance Win32_OperatingSystem).Caption } catch { $os = "Windows" }
    $cpuName = ($procInfo | Select-Object -First 1).Name
    Write-Host "  OS       : $os" -ForegroundColor Cyan
    Write-Host "  CPU      : $cpuName ($script:cores Threads)" -ForegroundColor Cyan
    Write-Host "  RAM      : $totalRamGB GB`n" -ForegroundColor Cyan
}

function Get-Temp {
    try {
        $t = Get-CimInstance -Namespace "root\wmi" -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop | Sort-Object CurrentTemperature -Descending | Select-Object -First 1
        if ($t) { return [math]::Round(($t.CurrentTemperature / 10) - 273.15, 0) }
    } catch {}
    return "N/A"
}

function Pause-Continue {
    Write-Host "`nPress [ENTER] to return to the menu..." -ForegroundColor Cyan
    $null = Read-Host
}

function Test-Cpu {
    Write-Host "[*] Singularity CPU Stress ($($script:cpuMBperThread)MB SHA-256 per Thread x $($script:cores) Threads)..." -ForegroundColor Yellow
    $tempStart = Get-Temp
    $totalMb = 0
    $passes = 0
    $swTotal = [System.Diagnostics.Stopwatch]::StartNew()
    do {
        try {
            $elPass = [SpectraDeepCore]::RunCpu($script:cores, $script:cpuMBperThread)
        } catch {
            Write-Host "  [!] CPU Test Failed: $_" -ForegroundColor Red
            $script:scoreCpu = 0
            return
        }
        $passes++
        $totalMb += ($script:cpuMBperThread * $script:cores)
        $elapsedTotal = $swTotal.Elapsed.TotalSeconds
        if ($elapsedTotal -ge $script:cpuMinSeconds -or $passes -ge $script:cpuMaxPasses) { break }
    } while ($true)
    $swTotal.Stop()
    $elapsed = $swTotal.Elapsed.TotalSeconds
    if ($elapsed -le 0) { $elapsed = 0.001 }
    $script:scoreCpu = [math]::Floor($totalMb / $elapsed)
    Write-Host "  [V] $passes pass(es), $totalMb MB hashed in $([math]::Round($elapsed,4))s -> CPU Score: $script:scoreCpu" -ForegroundColor Green
    $tempEnd = Get-Temp
    if ($tempStart -ne "N/A" -and $tempEnd -ne "N/A" -and $tempEnd -is [double]) {
        if ($tempEnd -ge 85) { Write-Host "  [!] THERMAL THROTTLING DETECTED (Max: ${tempEnd}°C)" -ForegroundColor Red }
        else { Write-Host "  [ Thermals: ${tempStart}°C -> ${tempEnd}°C ]" -ForegroundColor Cyan }
    }
}

function Test-Ram {
    $testMB = $script:ramChunkSizeMB * $script:ramChunkCount
    Write-Host "[*] Deep Memory Bandwidth ($testMB MB Chunked Allocations)..." -ForegroundColor Yellow
    try {
        $elapsed = [SpectraDeepCore]::RunRam($script:ramChunkCount, $script:ramChunkSizeMB)
        if ($elapsed -le 0) { $elapsed = 0.001 }
        $speedMBps = [math]::Round(($testMB / $elapsed), 2)
        if ($speedMBps -ge 1024) { $speedStr = "$([math]::Round($speedMBps / 1024, 2)) GB/s" }
        else { $speedStr = "$speedMBps MB/s" }
        $script:scoreRam = [math]::Floor($speedMBps * 3)
        Write-Host "  [V] Memory Speed: $speedStr -> RAM Score: $script:scoreRam" -ForegroundColor Green
    } catch {
        Write-Host "  [!] RAM Test Failed: $_" -ForegroundColor Red
        $script:scoreRam = 0
    }
}

function Test-Disk {
    $targetMB = 5000
    $testFile = Join-Path $env:TEMP ".spectra_disk_test.tmp"
    $drive = (Get-Item $env:TEMP).PSDrive
    $freeMB = [math]::Floor($drive.Free / 1MB)
    if ($freeMB -lt ($targetMB + 1000)) {
        if ($freeMB -le 700) {
            Write-Host "[!] Insufficient disk space. Skipping disk test." -ForegroundColor Red
            $script:scoreDisk = 0
            return
        }
        $targetMB = [math]::Max(256, $freeMB - 512)
        Write-Host "[*] Deep Storage Test (Low disk space: Using $targetMB MB WriteThrough)..." -ForegroundColor Yellow
    } else {
        Write-Host "[*] Deep Storage Test ($targetMB MB Sustained WriteThrough to Exhaust SLC)..." -ForegroundColor Yellow
    }
    $fs = $null
    try {
        $buffer = New-Object byte[] (1MB)
        $rnd = New-Object Random(1)
        $rnd.NextBytes($buffer)
        $time = Measure-Command {
            $fs = New-Object System.IO.FileStream($testFile, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None, 1MB, [System.IO.FileOptions]::WriteThrough)
            for ($i = 0; $i -lt $targetMB; $i++) { $fs.Write($buffer, 0, $buffer.Length) }
        }
    } catch {
        Write-Host "  [!] Disk Test Failed: $_" -ForegroundColor Red
        $script:scoreDisk = 0
        return
    } finally {
        if ($fs) { $fs.Close(); $fs.Dispose() }
        Remove-Item $testFile -Force -ErrorAction SilentlyContinue
    }
    $elapsed = $time.TotalSeconds
    if ($elapsed -le 0) { $elapsed = 0.001 }
    $speedMBps = [math]::Round(($targetMB / $elapsed), 2)
    if ($speedMBps -ge 1024) { $speedStr = "$([math]::Round($speedMBps / 1024, 2)) GB/s" }
    else { $speedStr = "$speedMBps MB/s" }
    $script:scoreDisk = [math]::Floor($speedMBps * 8)
    Write-Host "  [V] Disk Speed: $speedStr -> Disk Score: $script:scoreDisk" -ForegroundColor Green
}

function Test-Network {
    Write-Host "[*] Network Edge Ping & 100MB Enterprise CDN Download..." -ForegroundColor Yellow
    $latency = 999
    $latStr = "Offline/Timeout"
    $latScore = 0
    try {
        $pingResult = Test-Connection -ComputerName 1.1.1.1 -Count 3 -ErrorAction Stop
        $avg = ($pingResult | Measure-Object ResponseTime -Average).Average
        if ($avg -ne $null) { $latency = [math]::Round($avg, 0) }
    } catch {
        try {
            $pingStatus = Get-WmiObject Win32_PingStatus -Filter "Address='1.1.1.1' AND Timeout=3000" | Select-Object -First 1
            if ($pingStatus -and $pingStatus.StatusCode -eq 0) { $latency = $pingStatus.ResponseTime }
        } catch {}
    }
    if ($latency -le 0) { $latency = 1 }
    if ($latency -lt 999) {
        $latScore = [math]::Floor(2000 / $latency)
        $latStr = "$latency ms"
    }
    $urls = @(
        "https://speedtest.tele2.net/100MB.zip",
        "https://proof.ovh.net/files/100Mb.dat",
        "https://speed.hetzner.de/100MB.bin",
        "https://speedtest-sgp1.digitalocean.com/100mb.test"
    )
    $dlMbps = 0
    $bwScore = 0
    $success = $false
    foreach ($url in $urls) {
        $tmpFile = [System.IO.Path]::GetTempFileName()
        try {
            $time = Measure-Command {
                Invoke-WebRequest -Uri $url -OutFile $tmpFile -MaximumRedirection 5 -TimeoutSec 30 -ErrorAction Stop
            }
            $sz = (Get-Item $tmpFile).Length
            Remove-Item $tmpFile -Force
            $elapsed = $time.TotalSeconds
            if ($elapsed -gt 0 -and $sz -gt 50000000) {
                $dlMbps = [math]::Round((100 / $elapsed), 2)
                $bwScore = [math]::Floor($dlMbps * 15)
                $success = $true
                break
            }
        } catch {
            Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
            continue
        }
    }
    if (-not $success) { Write-Host "  [!] All CDN endpoints failed. Check internet connection." -ForegroundColor Yellow }
    $script:scoreNet = $latScore + $bwScore
    Write-Host "  DNS Latency : $latStr | Bandwidth : $dlMbps MB/s" -ForegroundColor Cyan
    Write-Host "  [V] Network Validated -> Net Score: $script:scoreNet" -ForegroundColor Green
}

function Test-Cache {
    Write-Host "[*] Cache Hierarchy Profiling (L1/L2/L3/RAM Approximation)..." -ForegroundColor Yellow
    try {
        $csc = @"
using System;
using System.Diagnostics;
public class CacheProbe {
    static double Chase(int kb, long iters) {
        int count = Math.Max(64, (kb * 1024) / 4);
        int[] arr = new int[count];
        for (int i = 0; i < count; i++) {
            arr[i] = ((i * 7919) + 16) % count;
        }
        int idx = 0;
        for (int w = 0; w < count; w++) idx = arr[idx];
        Stopwatch sw = Stopwatch.StartNew();
        for (long i = 0; i < iters; i++) idx = arr[idx];
        sw.Stop();
        return sw.Elapsed.TotalSeconds / (double)iters * 1e9;
    }
    public static void Main() {
        Console.WriteLine("L1:" + Chase(16, 4000000).ToString("F2"));
        Console.WriteLine("L2:" + Chase(128, 2000000).ToString("F2"));
        Console.WriteLine("L3:" + Chase(4096, 1000000).ToString("F2"));
        Console.WriteLine("RAM:" + Chase(65536, 400000).ToString("F2"));
    }
}
"@
        $tmpDir = $env:TEMP
        $cs = Join-Path $tmpDir "spectra_cache.cs"
        $exe = Join-Path $tmpDir "spectra_cache.exe"
        Set-Content -Path $cs -Value $csc -Encoding ASCII
        $cscPath = (Get-Command csc.exe -ErrorAction SilentlyContinue).Source
        if (-not $cscPath) { $cscPath = Join-Path $env:WINDIR "Microsoft.NET\Framework\v4.0.30319\csc.exe" }
        if (-not (Test-Path $cscPath)) { throw "csc not found" }
        & $cscPath /nologo /out:$exe $cs 2>&1 | Out-Null
        if (-not (Test-Path $exe)) { throw "compile failed" }
        $out = & $exe 2>&1
        Remove-Item $cs -Force -ErrorAction SilentlyContinue
        Remove-Item $exe -Force -ErrorAction SilentlyContinue
        foreach ($line in $out) {
            if ($line -match "^L1:(.+)$") { $script:cacheL1 = $matches[1].Trim() }
            if ($line -match "^L2:(.+)$") { $script:cacheL2 = $matches[1].Trim() }
            if ($line -match "^L3:(.+)$") { $script:cacheL3 = $matches[1].Trim() }
            if ($line -match "^RAM:(.+)$") { $script:cacheRam = $matches[1].Trim() }
        }
        function ScoreLat($v, $floor) {
            if ($v -and [double]::TryParse($v, [ref][double]0)) {
                $d = [double]$v
                if ($d -le 0) { return 0 }
                $use = $d; if ($d -lt $floor) { $use = $floor }
                return [math]::Floor(5000 / $use)
            }
            return 0
        }
        $script:scoreCache = (ScoreLat $script:cacheL1 0.5) + (ScoreLat $script:cacheL2 2) + (ScoreLat $script:cacheL3 8) + (ScoreLat $script:cacheRam 50)
        Write-Host "  ┌─────────────────────────────────────────┐" -ForegroundColor Cyan
        Write-Host "  │ Cache Latency Profile (ns/access)       │" -ForegroundColor Cyan
        Write-Host "  ├─────────────────────────────────────────┤" -ForegroundColor Cyan
        Write-Host "  │ L1 Data Cache      $($script:cacheL1) ns              │" -ForegroundColor Cyan
        Write-Host "  │ L2 Cache          $($script:cacheL2) ns              │" -ForegroundColor Cyan
        Write-Host "  │ L3 Cache          $($script:cacheL3) ns              │" -ForegroundColor Cyan
        Write-Host "  │ RAM (Main Mem)   $($script:cacheRam) ns              │" -ForegroundColor Cyan
        Write-Host "  └─────────────────────────────────────────┘" -ForegroundColor Cyan
        Write-Host "  [V] Cache Profile Score: $($script:scoreCache)" -ForegroundColor Green
    } catch {
        Write-Host "  [!] Cache profiling unavailable. Error: $_" -ForegroundColor Yellow
        $script:scoreCache = 0
    }
}

function Run-All {
    Test-Cpu; Write-Host ""
    Test-Ram; Write-Host ""
    Test-Disk; Write-Host ""
    Test-Network; Write-Host ""
    Test-Cache; Write-Host ""
    $total = $script:scoreCpu + $script:scoreRam + $script:scoreDisk + $script:scoreNet + $script:scoreCache
    Write-Host "=================================================================" -ForegroundColor Magenta
    Write-Host "                     🏆 FINAL SPECTRA SCORE 🏆                   " -ForegroundColor White
    Write-Host "=================================================================" -ForegroundColor Magenta
    Write-Host "  CPU Score      : $script:scoreCpu" -ForegroundColor Cyan
    Write-Host "  RAM Score      : $script:scoreRam" -ForegroundColor Cyan
    Write-Host "  Disk Score     : $script:scoreDisk" -ForegroundColor Cyan
    Write-Host "  Network Score  : $script:scoreNet" -ForegroundColor Cyan
    Write-Host "  Cache Score    : $script:scoreCache" -ForegroundColor Cyan
    Write-Host "-----------------------------------------------------------------"
    Write-Host "  TOTAL SCORE    : $total" -ForegroundColor Yellow
    Write-Host "=================================================================" -ForegroundColor Magenta
}

# --- [ INTERACTIVE MENU LOOP ] ---
do {
    Draw-Banner
    Get-SysInfo
    Write-Host "Select an operation to perform:" -ForegroundColor White
    Write-Host "  1. 🚀 Run Full Singularity Benchmark Suite" -ForegroundColor Green
    Write-Host "  2. 🧠 Test CPU ($($script:cpuMBperThread)MB Singularity Multi-Core Load)" -ForegroundColor Cyan
    Write-Host "  3. ⚡ Test RAM ($($script:ramChunkSizeMB * $script:ramChunkCount)MB Allocation Latency & Bandwidth)" -ForegroundColor Cyan
    Write-Host "  4. 💾 Test Storage (5GB SLC Cache Exhaustion)" -ForegroundColor Cyan
    Write-Host "  5. 🌐 Test Network (Global Edge & 100MB CDN)" -ForegroundColor Cyan
    Write-Host "  6. 🎯 Test Cache (L1/L2/L3 Latency Profile)" -ForegroundColor Cyan
    Write-Host "  0. ❌ Exit" -ForegroundColor Red
    Write-Host "-----------------------------------------------------------------" -ForegroundColor Cyan
    try {
        $choice = Read-Host "Enter your choice [0-6]"
    } catch {
        $choice = "0"
    }
    if ($null -eq $choice -or $choice.Trim() -eq "") { continue }
    switch ($choice.Trim()) {
        "1" { Write-Host ""; Run-All; Pause-Continue }
        "2" { Write-Host ""; Test-Cpu; Pause-Continue }
        "3" { Write-Host ""; Test-Ram; Pause-Continue }
        "4" { Write-Host ""; Test-Disk; Pause-Continue }
        "5" { Write-Host ""; Test-Network; Pause-Continue }
        "6" { Write-Host ""; Test-Cache; Pause-Continue }
        "0" { Write-Host "`nThank you for using SpectraBench!" -ForegroundColor Green }
        default {
            Write-Host "`n[!] Invalid selection. Please choose 0-6." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($choice.Trim() -ne "0")
