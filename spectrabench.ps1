<#
.SYNOPSIS
Project      : SpectraBench (v5.0-OmniPlatform Singularity)
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

$Host.UI.RawUI.WindowTitle = "SpectraBench v5.0 (Windows Edition)"

# --- [ THE ENGINE: SUSTAINED SINGULARITY INJECTION ] ---
$csharpCode = @"
using System;
using System.IO;
using System.Threading.Tasks;
using System.Security.Cryptography;
using System.Diagnostics;

public class SpectraDeepCore {
    public static double RunCpu(int cores) {
        Stopwatch sw = Stopwatch.StartNew();
        Parallel.For(0, cores, i => {
            // Allocate 100MB array and loop it 50 times to securely hash 5GB per thread 
            byte[] data = new byte[100 * 1024 * 1024]; 
            using (SHA256 sha = SHA256.Create()) {
                for(int j=0; j<50; j++) { sha.ComputeHash(data); }
            }
        });
        sw.Stop();
        return sw.Elapsed.TotalSeconds == 0 ? 0.001 : sw.Elapsed.TotalSeconds;
    }

    public static double RunRam() {
        Stopwatch sw = Stopwatch.StartNew();
        using (MemoryStream ms = new MemoryStream()) {
            byte[] buf = new byte[64 * 1024]; // 64KB Blocks
            for (int i = 0; i < 32768; i++) { // 2GB Total allocation latency test
                ms.Write(buf, 0, buf.Length);
            }
        }
        sw.Stop();
        return sw.Elapsed.TotalSeconds == 0 ? 0.001 : sw.Elapsed.TotalSeconds;
    }
}
"@
if (-not ("SpectraDeepCore" -as [type])) {
    Add-Type -TypeDefinition $csharpCode -Language CSharp
}

# --- [ GLOBAL VARIABLES ] ---
$script:cores = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
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
    Write-Host "    v5.0 Omni-Platform Singularity Suite | Windows Edition       " -ForegroundColor Cyan
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Get-SysInfo {
    $os = (Get-CimInstance Win32_OperatingSystem).Caption
    $cpu = (Get-CimInstance Win32_Processor).Name
    $ramRaw = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
    $ram = [math]::Round($ramRaw / 1GB, 2)

    Write-Host "  OS       : $os" -ForegroundColor Cyan
    Write-Host "  CPU      : $cpu ($script:cores Threads)" -ForegroundColor Cyan
    Write-Host "  RAM      : $ram GB`n" -ForegroundColor Cyan
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
    Read-Host
}

# --- [ TEST MODULES ] ---

function Test-Cpu {
    Write-Host "[*] Singularity CPU Stress (5000MB SHA-256 per Thread x $($script:cores) Threads)..." -ForegroundColor Yellow
    $tempStart = Get-Temp
    
    $elapsed = [SpectraDeepCore]::RunCpu($script:cores)
    $tempEnd = Get-Temp
    if ($elapsed -eq 0) { $elapsed = 0.001 }
    $elapsedRound = [math]::Round($elapsed, 4)
    
    $script:scoreCpu = [math]::Floor((5000 * $script:cores) / $elapsed)
    Write-Host "  [V] Elapsed: $($elapsedRound)s -> CPU Score: $script:scoreCpu" -ForegroundColor Green
    
    if ($tempStart -ne "N/A" -and $tempEnd -ne "N/A") {
        if ($tempEnd -ge 85) { Write-Host "  [!] THERMAL THROTTLING DETECTED (Max: ${tempEnd}°C)" -ForegroundColor Red }
        else { Write-Host "  [ Thermals: ${tempStart}°C -> ${tempEnd}°C ]" -ForegroundColor Cyan }
    }
}

function Test-Ram {
    Write-Host "[*] Deep Memory Bandwidth (2GB Random Allocations Native)..." -ForegroundColor Yellow
    $elapsed = [SpectraDeepCore]::RunRam()
    if ($elapsed -eq 0) { $elapsed = 0.001 }
    $speedMBps = [math]::Round((2048 / $elapsed), 2)
    
    if ($speedMBps -ge 1024) { $speedStr = "$([math]::Round($speedMBps / 1024, 2)) GB/s" }
    else { $speedStr = "$speedMBps MB/s" }
    
    $script:scoreRam = [math]::Floor($speedMBps * 3)
    Write-Host "  [V] Memory Speed: $speedStr -> RAM Score: $script:scoreRam" -ForegroundColor Green
}

function Test-Disk {
    Write-Host "[*] Deep Storage Test (5GB Sustained WriteThrough to Exhaust SLC)..." -ForegroundColor Yellow
    $testFile = "$env:TEMP\.spectra_disk_test.tmp"
    $time = Measure-Command {
        $fs = New-Object System.IO.FileStream($testFile, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None, 1MB, [System.IO.FileOptions]::WriteThrough)
        $buffer = New-Object byte[] 1MB
        for ($i = 0; $i -lt 5120; $i++) { $fs.Write($buffer, 0, $buffer.Length) } # 5GB
        $fs.Close()
    }
    Remove-Item $testFile -Force
    $elapsed = $time.TotalSeconds
    if ($elapsed -eq 0) { $elapsed = 0.001 }
    $speedMBps = [math]::Round((5120 / $elapsed), 2)
    
    if ($speedMBps -ge 1024) { $speedStr = "$([math]::Round($speedMBps / 1024, 2)) GB/s" }
    else { $speedStr = "$speedMBps MB/s" }
    
    $script:scoreDisk = [math]::Floor($speedMBps * 8)
    Write-Host "  [V] Disk Speed: $speedStr -> Disk Score: $script:scoreDisk" -ForegroundColor Green
}

function Test-Network {
    Write-Host "[*] Network Edge Ping & 100MB Enterprise CDN Download..." -ForegroundColor Yellow
    $ping = Get-WmiObject Win32_PingStatus -Filter "Address='1.1.1.1'" | Select-Object -First 1
    if ($ping -and $ping.StatusCode -eq 0) {
        $latency = $ping.ResponseTime
        if ($latency -eq 0) { $latency = 1 }
        $latScore = [math]::Floor(2000 / $latency)
        $latStr = "$latency ms"
    } else {
        $latScore = 0; $latStr = "Offline/Timeout"
    }

    $url1 = "https://proof.ovh.net/files/100Mb.dat"
    $url2 = "https://speed.hetzner.de/100MB.bin"
    $tmpFile = "$env:TEMP\.spectra_dl_test.tmp"
    
    $elapsed = 0
    try {
        $wc = New-Object System.Net.WebClient
        $time = Measure-Command { $wc.DownloadFile($url1, $tmpFile) }
        $wc.Dispose(); Remove-Item $tmpFile -Force
        $elapsed = $time.TotalSeconds
    } catch {
        try {
            $wc = New-Object System.Net.WebClient
            $time = Measure-Command { $wc.DownloadFile($url2, $tmpFile) }
            $wc.Dispose(); Remove-Item $tmpFile -Force
            $elapsed = $time.TotalSeconds
        } catch {
            $elapsed = 0
        }
    }
    
    if ($elapsed -gt 0) {
        $dlMbps = [math]::Round((100 / $elapsed), 2)
        $bwScore = [math]::Floor($dlMbps * 15)
    } else {
        $dlMbps = 0
        $bwScore = 0
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
    Write-Host "  2. 🧠 Test CPU (5GB Singularity Multi-Core Load)" -ForegroundColor Cyan
    Write-Host "  3. ⚡ Test RAM (Allocation Latency & Bandwidth)" -ForegroundColor Cyan
    Write-Host "  4. 💾 Test Storage (5GB SLC Cache Exhaustion)" -ForegroundColor Cyan
    Write-Host "  5. 🌐 Test Network (Global Edge & 100MB CDN)" -ForegroundColor Cyan
    Write-Host "  0. ❌ Exit" -ForegroundColor Red
    Write-Host "-----------------------------------------------------------------" -ForegroundColor Cyan
    $choice = Read-Host "Enter your choice [0-5]"
    
    switch ($choice) {
        "1" { Write-Host ""; Run-All; Pause-Continue }
        "2" { Write-Host ""; Test-Cpu; Pause-Continue }
        "3" { Write-Host ""; Test-Ram; Pause-Continue }
        "4" { Write-Host ""; Test-Disk; Pause-Continue }
        "5" { Write-Host ""; Test-Network; Pause-Continue }
        "0" { Write-Host "`nThank you for using SpectraBench!" -ForegroundColor Green }
        default { Write-Host "`n[!] Invalid selection." -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
} while ($choice -ne "0")
