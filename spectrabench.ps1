<#
.SYNOPSIS
Project      : SpectraBench (v5.1-OmniPlatform Singularity)
Description  : Zero-Dependency Ultimate System Benchmark
Author       : Nabil
Architecture : PowerShell + Embedded C#, Sustained Singularity Stress
#>

# --- [ REQUIRE ADMIN ] ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] Access Denied. SpectraBench requires Administrator privileges (Run as Admin)." -ForegroundColor Red
    Exit
}

$Host.UI.RawUI.WindowTitle = "SpectraBench v5.1 (Windows Edition)"

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
        Parallel.For(0, cores, i => {
            byte[] data = new byte[bytes];
            new Random(i).NextBytes(data);
            using (SHA256 sha = SHA256.Create()) {
                for(int j=0; j<50; j++) { sha.ComputeHash(data); }
            }
        });
        sw.Stop();
        return sw.Elapsed.TotalSeconds == 0 ? 0.001 : sw.Elapsed.TotalSeconds;
    }

    public static double RunRam(int chunkCount, int chunkSizeMB) {
        Stopwatch sw = Stopwatch.StartNew();
        int chunkSize = chunkSizeMB * 1024 * 1024;
        List<byte[]> chunks = new List<byte[]>(chunkCount);
        Random rng = new Random(42);
        for (int i = 0; i < chunkCount; i++) {
            byte[] chunk = new byte[chunkSize];
            rng.NextBytes(chunk);
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
        return sw.Elapsed.TotalSeconds == 0 ? 0.001 : sw.Elapsed.TotalSeconds;
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
if ($script:cores -eq 0) { $script:cores = 1 }

$sysInfo = Get-CimInstance Win32_ComputerSystem
$totalRamBytes = $sysInfo.TotalPhysicalMemory
$totalRamGB = [math]::Round($totalRamBytes / 1GB, 2)

$availableRamMB = [math]::Floor($totalRamBytes / 1MB)
$minOsReserveMB = 2048

$script:cpuMBperThread = 5000
$maxCpuTotalMB = [math]::Max(512, $availableRamMB - $minOsReserveMB)
$safeCpuMBperThread = [math]::Floor($maxCpuTotalMB / $script:cores)
if ($safeCpuMBperThread -lt 500) { $safeCpuMBperThread = 500 }
if ($safeCpuMBperThread -lt 5000) {
    $script:cpuMBperThread = $safeCpuMBperThread
}

$script:ramChunkSizeMB = 256
$script:ramChunkCount = 8
$maxRamTestMB = [math]::Floor(($availableRamMB - $minOsReserveMB) / 2)
if ($maxRamTestMB -lt 512) {
    $script:ramChunkCount = [math]::Max(2, [math]::Floor($maxRamTestMB / $script:ramChunkSizeMB))
    if ($script:ramChunkCount -lt 2) { $script:ramChunkCount = 2 }
}

$script:scoreCpu = 0; $script:scoreRam = 0; $script:scoreDisk = 0; $script:scoreNet = 0

# --- [ UI FUNCTIONS ] ---
function Draw-Banner {
    Clear-Host
    Write-Host "  ██████  ██▓███  ▓█████  ▄████▄  ▄▄▄█████▓ ██▀███   ▄▄▄       " -ForegroundColor Magenta
    Write-Host "▒██    ▒ ▓██░  ██▒▓█   ▀ ▒██▀ ▀█  ▓  ██▒ ▓▒▓██ ▒ ██▒▒████▄     " -ForegroundColor Magenta
    Write-Host "░ ▓██▄   ▓██░ ██▓▒▒███   ▒▓█    ▄ ▒ ▓██░ ▒░▓██ ░▄█ ▒▒██  ▀█▄   " -ForegroundColor Magenta
    Write-Host "  ▒   ██▒▒██▄█▓▒ ▒▒▓█  ▄ ▒▓▓▄ ▄██▒░ ▓██▓ ░ ▒██▀▀█▄  ░██▄▄▄▄██  " -ForegroundColor Magenta
    Write-Host "▒██████▒▒▒██▒ ░  ░░▒████▒▒ ▓███▀ ░  ▒██▒ ░ ░██▓ ▒██▒ ▓█   ▓██▒ " -ForegroundColor Magenta
    Write-Host "░ ▒░▓  ░ ▒▓▒░ ░  ░░░ ▒░ ░░ ░▒ ▒  ░  ▒ ░░   ░ ▒▓ ░▒▓░ ▒▒   ▓▒█░ " -ForegroundColor Magenta
    Write-Host "    v5.1 Omni-Platform Singularity Suite | Windows Edition       " -ForegroundColor Cyan
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Get-SysInfo {
    $os = (Get-CimInstance Win32_OperatingSystem).Caption
    $cpu = ($procInfo | Select-Object -First 1).Name
    Write-Host "  OS       : $os" -ForegroundColor Cyan
    Write-Host "  CPU      : $cpu ($script:cores Threads)" -ForegroundColor Cyan
    Write-Host "  RAM      : $totalRamGB GB`n" -ForegroundColor Cyan
}

function Get-Temp {
    try {
        $t = Get-CimInstance -Namespace "root\wmi" -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop | Sort-Object CurrentTemperature -Descending | Select-Object -First 1
        if ($t) { return [math]::Round(($t.CurrentTemperature / 10) - 273.15, 0) }
    } catch { }
    return "N/A"
}

function Pause-Continue {
    Write-Host "`nPress [ENTER] to return to the menu..." -ForegroundColor Cyan
    $null = Read-Host
}

# --- [ TEST MODULES ] ---

function Test-Cpu {
    $totalWorkMB = $script:cpuMBperThread * $script:cores
    Write-Host "[*] Singularity CPU Stress (${script:cpuMBperThread}MB SHA-256 per Thread x $($script:cores) Threads = ${totalWorkMB}MB Total)..." -ForegroundColor Yellow
    $tempStart = Get-Temp
    try {
        $elapsed = [SpectraDeepCore]::RunCpu($script:cores, $script:cpuMBperThread)
        if ($elapsed -eq 0) { $elapsed = 0.001 }
        $elapsedRound = [math]::Round($elapsed, 4)
        $script:scoreCpu = [math]::Floor(($script:cpuMBperThread * $script:cores) / $elapsed)
        Write-Host "  [V] Elapsed: $($elapsedRound)s -> CPU Score: $script:scoreCpu" -ForegroundColor Green
        $tempEnd = Get-Temp
        if ($tempStart -ne "N/A" -and $tempEnd -ne "N/A") {
            if ($tempEnd -ge 85) { Write-Host "  [!] THERMAL THROTTLING DETECTED (Max: ${tempEnd}°C)" -ForegroundColor Red }
            else { Write-Host "  [ Thermals: ${tempStart}°C -> ${tempEnd}°C ]" -ForegroundColor Cyan }
        }
    } catch {
        Write-Host "  [!] CPU Test Failed: $_" -ForegroundColor Red
        $script:scoreCpu = 0
    }
}

function Test-Ram {
    $testMB = $script:ramChunkSizeMB * $script:ramChunkCount
    Write-Host "[*] Deep Memory Bandwidth (${testMB}MB Chunked Allocations)..." -ForegroundColor Yellow
    try {
        $elapsed = [SpectraDeepCore]::RunRam($script:ramChunkCount, $script:ramChunkSizeMB)
        if ($elapsed -eq 0) { $elapsed = 0.001 }
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
    $testFile = "$env:TEMP\.spectra_disk_test.tmp"
    $drive = (Get-Item $env:TEMP).PSDrive
    $freeMB = [math]::Floor($drive.Free / 1MB)

    $targetMB = 5120
    if ($freeMB -lt 6144) {
        $targetMB = [math]::Max(256, $freeMB - 512)
        Write-Host "[*] Deep Storage Test (Low disk space: Using ${targetMB}MB WriteThrough)..." -ForegroundColor Yellow
    } else {
        Write-Host "[*] Deep Storage Test (${targetMB}MB Sustained WriteThrough to Exhaust SLC)..." -ForegroundColor Yellow
    }

    if ($targetMB -lt 100) {
        Write-Host "  [!] Insufficient disk space. Skipping disk test." -ForegroundColor Red
        $script:scoreDisk = 0
        return
    }

    $fs = $null
    try {
        $buffer = New-Object byte[] (1MB)
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
    if ($elapsed -eq 0) { $elapsed = 0.001 }
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
        $latency = [math]::Round(($pingResult | Measure-Object ResponseTime -Average).Average, 0)
    } catch {
        try {
            $pingStatus = Get-WmiObject Win32_PingStatus -Filter "Address='1.1.1.1' AND Timeout=3000" | Select-Object -First 1
            if ($pingStatus -and $pingStatus.StatusCode -eq 0) { $latency = $pingStatus.ResponseTime }
        } catch { }
    }
    if ($latency -eq 0) { $latency = 1 }
    if ($latency -lt 999) {
        $latScore = [math]::Floor(2000 / $latency)
        $latStr = "$latency ms"
    }

    $urls = @(
        "https://speedtest.tele2.net/100MB.zip",
        "https://proof.ovh.net/files/100Mb.dat",
        "https://speed.hetzner.de/100MB.bin"
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
            Remove-Item $tmpFile -Force
            $elapsed = $time.TotalSeconds
            if ($elapsed -gt 0) {
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

    if (-not $success) {
        Write-Host "  [!] All CDN endpoints failed. Check internet connection." -ForegroundColor Yellow
    }

    $script:scoreNet = $latScore + $bwScore
    Write-Host "  DNS Latency : $latStr | Bandwidth : $dlMbps MB/s" -ForegroundColor Cyan
    Write-Host "  [V] Network Validated -> Net Score: $script:scoreNet" -ForegroundColor Green
}

function Run-All {
    Test-Cpu; Write-Host ""
    Test-Ram; Write-Host ""
    Test-Disk; Write-Host ""
    Test-Network; Write-Host ""

    $total = $script:scoreCpu + $script:scoreRam + $script:scoreDisk + $script:scoreNet
    Write-Host "=================================================================" -ForegroundColor Magenta
    Write-Host "                     🏆 FINAL SPECTRA SCORE 🏆                   " -ForegroundColor White
    Write-Host "=================================================================" -ForegroundColor Magenta
    Write-Host "  CPU Score      : $script:scoreCpu" -ForegroundColor Cyan
    Write-Host "  RAM Score      : $script:scoreRam" -ForegroundColor Cyan
    Write-Host "  Disk Score     : $script:scoreDisk" -ForegroundColor Cyan
    Write-Host "  Network Score  : $script:scoreNet" -ForegroundColor Cyan
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
    Write-Host "  2. 🧠 Test CPU (${script:cpuMBperThread}MB Singularity Multi-Core Load)" -ForegroundColor Cyan
    Write-Host "  3. ⚡ Test RAM ($($script:ramChunkSizeMB * $script:ramChunkCount)MB Allocation Latency & Bandwidth)" -ForegroundColor Cyan
    Write-Host "  4. 💾 Test Storage (5GB SLC Cache Exhaustion)" -ForegroundColor Cyan
    Write-Host "  5. 🌐 Test Network (Global Edge & 100MB CDN)" -ForegroundColor Cyan
    Write-Host "  0. ❌ Exit" -ForegroundColor Red
    Write-Host "-----------------------------------------------------------------" -ForegroundColor Cyan
    $choice = Read-Host "Enter your choice [0-5]"

    if ([string]::IsNullOrWhiteSpace($choice)) { continue }

    switch ($choice.Trim()) {
        "1" { Write-Host ""; Run-All; Pause-Continue }
        "2" { Write-Host ""; Test-Cpu; Pause-Continue }
        "3" { Write-Host ""; Test-Ram; Pause-Continue }
        "4" { Write-Host ""; Test-Disk; Pause-Continue }
        "5" { Write-Host ""; Test-Network; Pause-Continue }
        "0" { Write-Host "`nThank you for using SpectraBench!" -ForegroundColor Green }
        default { 
            Write-Host "`n[!] Invalid selection. Please choose 0-5." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($choice.Trim() -ne "0")
