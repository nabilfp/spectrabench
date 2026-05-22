<#
.SYNOPSIS
Project      : SpectraBench (v2.0-MultiThread)
Description  : Zero-Dependency Cross-Platform System Benchmark
Author       : Nabil
Architecture : PowerShell with Embedded C# Parallel Engine
#>

# --- [ REQUIRE ADMIN ] ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] Access Denied. SpectraBench requires Administrator privileges (Run as Admin)." -ForegroundColor Red
    Exit
}

$Host.UI.RawUI.WindowTitle = "SpectraBench v2.0 (Windows Edition)"

# --- [ THE ENGINE: NATIVE PARALLELISM INJECTION ] ---
$csharpCode = @"
using System;
using System.Threading.Tasks;
using System.Security.Cryptography;
using System.Diagnostics;

public class SpectraMultiCore {
    public static double RunStress(int cores) {
        Stopwatch sw = Stopwatch.StartNew();
        Parallel.For(0, cores, i => {
            byte[] data = new byte[50 * 1024 * 1024]; // 50MB per thread
            using (SHA256 sha = SHA256.Create()) {
                sha.ComputeHash(data);
            }
        });
        sw.Stop();
        return sw.Elapsed.TotalSeconds == 0 ? 0.001 : sw.Elapsed.TotalSeconds;
    }
}
"@
if (-not ("SpectraMultiCore" -as [type])) {
    Add-Type -TypeDefinition $csharpCode -Language CSharp
}

# --- [ MAIN FUNCTIONS ] ---
function Draw-Banner {
    Clear-Host
    Write-Host "  ██████  ██▓███  ▓█████  ▄████▄  ▄▄▄█████▓ ██▀███   ▄▄▄       " -ForegroundColor Magenta
    Write-Host "▒██    ▒ ▓██░  ██▒▓█   ▀ ▒██▀ ▀█  ▓  ██▒ ▓▒▓██ ▒ ██▒▒████▄     " -ForegroundColor Magenta
    Write-Host "░ ▓██▄   ▓██░ ██▓▒▒███   ▒▓█    ▄ ▒ ▓██░ ▒░▓██ ░▄█ ▒▒██  ▀█▄   " -ForegroundColor Magenta
    Write-Host "  ▒   ██▒▒██▄█▓▒ ▒▒▓█  ▄ ▒▓▓▄ ▄██▒░ ▓██▓ ░ ▒██▀▀█▄  ░██▄▄▄▄██  " -ForegroundColor Magenta
    Write-Host "▒██████▒▒▒██▒ ░  ░░▒████▒▒ ▓███▀ ░  ▒██▒ ░ ░██▓ ▒██▒ ▓█   ▓██▒ " -ForegroundColor Magenta
    Write-Host "░ ▒░▓  ░ ▒▓▒░ ░  ░░░ ▒░ ░░ ░▒ ▒  ░  ▒ ░░   ░ ▒▓ ░▒▓░ ▒▒   ▓▒█░ " -ForegroundColor Magenta
    Write-Host "          v2.0 Multi-Threaded | Windows Native Edition         " -ForegroundColor Cyan
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Get-SysInfo {
    Write-Host "[*] Gathering System Architecture..." -ForegroundColor Yellow
    $os = (Get-CimInstance Win32_OperatingSystem).Caption
    $cpu = (Get-CimInstance Win32_Processor).Name
    $script:cores = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
    $ramRaw = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
    $ram = [math]::Round($ramRaw / 1GB, 2)

    Write-Host "  OS       : $os" -ForegroundColor Cyan
    Write-Host "  CPU      : $cpu ($script:cores Threads)" -ForegroundColor Cyan
    Write-Host "  RAM      : $ram GB`n" -ForegroundColor Cyan
    Start-Sleep -Seconds 1
}

function Get-Temp {
    try {
        $t = Get-CimInstance -Namespace "root\wmi" -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop | Sort-Object CurrentTemperature -Descending | Select-Object -First 1
        if ($t) { return [math]::Round(($t.CurrentTemperature / 10) - 273.15, 0) }
    } catch { }
    return "N/A"
}

function Run-CpuBench {
    Write-Host "[*] Running Multi-Core Stress Test (SHA-256 on $($script:cores) Threads)..." -ForegroundColor Yellow
    $tempStart = Get-Temp
    
    $elapsed = [SpectraMultiCore]::RunStress($script:cores)
    
    $tempEnd = Get-Temp
    
    $elapsedRound = [math]::Round($elapsed, 4)
    $script:cpuScore = [math]::Floor((10000 * $script:cores) / $elapsed)
    Write-Host "  [V] Completed in $($elapsedRound)s -> Score: $script:cpuScore" -ForegroundColor Green
    
    if ($tempStart -ne "N/A" -and $tempEnd -ne "N/A") {
        if ($tempEnd -ge 85) {
            Write-Host "  [!] THERMAL THROTTLING DETECTED (Max: ${tempEnd}°C)`n" -ForegroundColor Red
        } else {
            Write-Host "  [ Thermals: ${tempStart}°C -> ${tempEnd}°C ]`n" -ForegroundColor Cyan
        }
    } else {
        Write-Host "  [ Thermals: N/A (Locked by OEM) ]`n" -ForegroundColor Cyan
    }
}

function Run-RamBench {
    Write-Host "[*] Running Volatile Memory I/O Test (500MB Native RAM)..." -ForegroundColor Yellow
    $time = Measure-Command {
        $ms = New-Object System.IO.MemoryStream
        $buffer = New-Object byte[] 1MB
        for ($i = 0; $i -lt 500; $i++) {
            $ms.Write($buffer, 0, $buffer.Length)
        }
        $ms.Dispose()
        [System.GC]::Collect()
    }
    $elapsed = [math]::Round($time.TotalSeconds, 3)
    
    if ($elapsed -eq 0) { $elapsed = 0.001 }
    $speedMBps = [math]::Round((500 / $elapsed), 2)
    
    if ($speedMBps -ge 1024) {
        $speedStr = "$([math]::Round($speedMBps / 1024, 2)) GB/s"
    } else {
        $speedStr = "$speedMBps MB/s"
    }
    
    $script:ramScore = [math]::Floor($speedMBps * 12)
    Write-Host "  [V] Memory Speed: $speedStr -> Score: $script:ramScore`n" -ForegroundColor Green
}

function Run-DiskBench {
    Write-Host "[*] Running Storage Drive I/O Test (500MB WriteThrough)..." -ForegroundColor Yellow
    $testFile = "$env:TEMP\.spectra_disk_test.tmp"
    $time = Measure-Command {
        $fs = New-Object System.IO.FileStream($testFile, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None, 1MB, [System.IO.FileOptions]::WriteThrough)
        $buffer = New-Object byte[] 1MB
        for ($i = 0; $i -lt 500; $i++) {
            $fs.Write($buffer, 0, $buffer.Length)
        }
        $fs.Close()
    }
    Remove-Item $testFile -Force
    $elapsed = [math]::Round($time.TotalSeconds, 3)
    
    if ($elapsed -eq 0) { $elapsed = 0.001 }
    $speedMBps = [math]::Round((500 / $elapsed), 2)
    
    if ($speedMBps -ge 1024) {
        $speedStr = "$([math]::Round($speedMBps / 1024, 2)) GB/s"
    } else {
        $speedStr = "$speedMBps MB/s"
    }
    
    $script:diskScore = [math]::Floor($speedMBps * 8)
    Write-Host "  [V] Disk Speed: $speedStr -> Score: $script:diskScore`n" -ForegroundColor Green
}

function Show-Results {
    $totalScore = $script:cpuScore + $script:ramScore + $script:diskScore
    Write-Host "===============================================================" -ForegroundColor Magenta
    Write-Host "                 🏆 SPECTRA BENCHMARK RESULTS 🏆               " -ForegroundColor White
    Write-Host "===============================================================" -ForegroundColor Magenta
    Write-Host "  CPU Score      : $script:cpuScore" -ForegroundColor Cyan
    Write-Host "  RAM Score      : $script:ramScore" -ForegroundColor Cyan
    Write-Host "  Disk Score     : $script:diskScore" -ForegroundColor Cyan
    Write-Host "---------------------------------------------------------------"
    Write-Host "  TOTAL SCORE    : $totalScore" -ForegroundColor Yellow
    Write-Host "===============================================================" -ForegroundColor Magenta
}

Draw-Banner
Get-SysInfo
Run-CpuBench
Run-RamBench
Run-DiskBench
Show-Results
