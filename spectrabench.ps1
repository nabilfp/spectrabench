<#
.SYNOPSIS
Project      : SpectraBench (v1.0-Core)
Description  : Zero-Dependency Cross-Platform System Benchmark
Author       : Nabil
Architecture : PowerShell with JIT Native C# Injection (Anti-DCE Build)
#>

# --- [ REQUIRE ADMIN ] ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] Access Denied. SpectraBench requires Administrator privileges (Run as Admin)." -ForegroundColor Red
    Exit
}

$Host.UI.RawUI.WindowTitle = "SpectraBench v1.0 (Windows Edition)"

# --- [ THE ENGINE: JIT NATIVE C# COMPILATION IN RAM ] ---
$csharpCode = @"
using System;
using System.IO;
using System.Diagnostics;

public class SpectraCore {
    public static double RunCpu() {
        Stopwatch sw = Stopwatch.StartNew();
        int c = 0;
        for (int i = 2; i <= 100000; i++) {
            bool p = true;
            for (int j = 2; j * j <= i; j++) {
                if (i % j == 0) { p = false; break; }
            }
            if (p) c++;
        }
        sw.Stop();
        double e = sw.Elapsed.TotalSeconds;
        if (e == 0) e = 0.001;
        
        // Anti-Dead Code Elimination (DCE) Trick: Forces compiler to fully execute the loop
        return e + (c * 0.0); 
    }

    public static double RunRam() {
        Stopwatch sw = Stopwatch.StartNew();
        using (MemoryStream ms = new MemoryStream()) {
            byte[] buf = new byte[1024 * 1024];
            for (int i = 0; i < 500; i++) {
                ms.Write(buf, 0, buf.Length);
            }
        }
        sw.Stop();
        double e = sw.Elapsed.TotalSeconds;
        return e == 0 ? 0.001 : e;
    }

    public static double RunDisk(string path) {
        Stopwatch sw = Stopwatch.StartNew();
        using (FileStream fs = new FileStream(path, FileMode.Create, FileAccess.Write, FileShare.None, 1024 * 1024, FileOptions.WriteThrough)) {
            byte[] buf = new byte[1024 * 1024];
            for (int i = 0; i < 500; i++) {
                fs.Write(buf, 0, buf.Length);
            }
        }
        sw.Stop();
        double e = sw.Elapsed.TotalSeconds;
        return e == 0 ? 0.001 : e;
    }
}
"@

# Inject and Compile in Memory securely
if (-not ("SpectraCore" -as [type])) {
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
    Write-Host "             v1.0 Core | Windows Native Edition            " -ForegroundColor Cyan
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Get-SysInfo {
    Write-Host "[*] Gathering System Architecture..." -ForegroundColor Yellow
    $os = (Get-CimInstance Win32_OperatingSystem).Caption
    $cpu = (Get-CimInstance Win32_Processor).Name
    $cores = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
    $ramRaw = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
    $ram = [math]::Round($ramRaw / 1GB, 2)

    Write-Host "  OS       : $os" -ForegroundColor Cyan
    Write-Host "  CPU      : $cpu ($cores Threads)" -ForegroundColor Cyan
    Write-Host "  RAM      : $ram GB`n" -ForegroundColor Cyan
    Start-Sleep -Seconds 1
}

function Run-CpuBench {
    Write-Host "[*] Running CPU Single-Core Test (Prime Sieve 100k)..." -ForegroundColor Yellow
    $elapsed = [SpectraCore]::RunCpu()
    $elapsedRound = [math]::Round($elapsed, 5)
    $script:cpuScore = [math]::Floor(50000 / $elapsed)
    Write-Host "  [V] Completed in $($elapsedRound)s -> Score: $script:cpuScore`n" -ForegroundColor Green
}

function Run-RamBench {
    Write-Host "[*] Running Volatile Memory I/O Test (500MB Native RAM)..." -ForegroundColor Yellow
    $elapsed = [SpectraCore]::RunRam()
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
    $elapsed = [SpectraCore]::RunDisk($testFile)
    Remove-Item $testFile -Force
    
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
