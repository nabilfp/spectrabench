<#
.SYNOPSIS
Project      : SpectraBench (v1.0-Core)
Description  : Zero-Dependency Cross-Platform System Benchmark
Author       : Nabil
Architecture : Pure PowerShell (Windows Native)
#>

# --- [ REQUIRE ADMIN ] ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] Access Denied. SpectraBench requires Administrator privileges (Run as Admin)." -ForegroundColor Red
    Exit
}

$Host.UI.RawUI.WindowTitle = "SpectraBench v1.0 (Windows Edition)"

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
    $time = Measure-Command {
        $count = 0
        for ($i = 2; $i -le 100000; $i++) {
            $isPrime = $true
            for ($j = 2; $j * $j -le $i; $j++) {
                if ($i % $j -eq 0) { $isPrime = $false; break }
            }
            if ($isPrime) { $count++ }
        }
    }
    $elapsed = [math]::Round($time.TotalSeconds, 3)
    $script:cpuScore = [math]::Floor(50000 / $elapsed)
    Write-Host "  [V] Completed in $($elapsed)s -> Score: $script:cpuScore`n" -ForegroundColor Green
}

function Run-RamBench {
    Write-Host "[*] Running Volatile Memory I/O Test (500MB MemoryStream)..." -ForegroundColor Yellow
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
    
    # Prevent division by zero if it executes in < 0.001s
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
        # Using WriteThrough flag to bypass OS cache for true hardware speed
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
