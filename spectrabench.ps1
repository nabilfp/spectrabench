<#
.SYNOPSIS
Project      : SpectraBench (v1.1-Multilanguage)
Description  : Zero-Dependency Cross-Platform System Benchmark
Author       : Nabil
Architecture : Pure PowerShell (Windows Native)
#>

# --- [ REQUIRE ADMIN ] ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] Access Denied. SpectraBench requires Administrator (Run as Admin) for accurate I/O." -ForegroundColor Red
    Exit
}

$Host.UI.RawUI.WindowTitle = "SpectraBench v1.1"

# --- [ LANGUAGE DICTIONARY (i18n) ] ---
function Set-LangEn {
    $script:UI_TITLE = "v1.1 Foundation | Windows Native Edition"
    $script:UI_GATHER_SYS = "[*] Gathering System Architecture..."
    $script:UI_CPU_TEST = "[*] Running CPU Single-Core Test (Prime Sieve 100k)..."
    $script:UI_RAM_TEST = "[*] Running Volatile Memory I/O Test (Array Allocation)..."
    $script:UI_DISK_TEST = "[*] Running Storage Drive I/O Test (500MB Sequential)..."
    $script:UI_COMPLETED = "[V] Completed in"
    $script:UI_SPEED = "Speed"
    $script:UI_SCORE = "Score"
    $script:UI_RES_TITLE = "🏆 SPECTRA BENCHMARK RESULTS 🏆"
    $script:UI_TOTAL = "TOTAL SCORE"
}

function Set-LangId {
    $script:UI_TITLE = "v1.1 Foundation | Edisi Native Windows"
    $script:UI_GATHER_SYS = "[*] Mengumpulkan Data Arsitektur Sistem..."
    $script:UI_CPU_TEST = "[*] Menjalankan Tes CPU Single-Core (Prime Sieve 100k)..."
    $script:UI_RAM_TEST = "[*] Menjalankan Tes I/O Memori Volatil (Alokasi Array)..."
    $script:UI_DISK_TEST = "[*] Menjalankan Tes I/O Penyimpanan (500MB Sekuensial)..."
    $script:UI_COMPLETED = "[V] Selesai dalam"
    $script:UI_SPEED = "Kecepatan"
    $script:UI_SCORE = "Skor"
    $script:UI_RES_TITLE = "🏆 HASIL BENCHMARK SPECTRA 🏆"
    $script:UI_TOTAL = "TOTAL SKOR"
}

function Set-LangZh {
    $script:UI_TITLE = "v1.1 基础版 | Windows 原生版本"
    $script:UI_GATHER_SYS = "[*] 正在收集系统架构信息..."
    $script:UI_CPU_TEST = "[*] 正在运行 CPU 单核测试 (素数筛选 100k)..."
    $script:UI_RAM_TEST = "[*] 正在运行易失性内存 I/O 测试 (数组分配)..."
    $script:UI_DISK_TEST = "[*] 正在运行存储驱动器 I/O 测试 (500MB 顺序)..."
    $script:UI_COMPLETED = "[V] 完成用时"
    $script:UI_SPEED = "速度"
    $script:UI_SCORE = "得分"
    $script:UI_RES_TITLE = "🏆 SPECTRA 基准测试结果 🏆"
    $script:UI_TOTAL = "总分"
}

# --- [ INTERACTIVE BOOTLOADER ] ---
Clear-Host
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host " 🌍 SELECT YOUR LANGUAGE / PILIH BAHASA / 选择语言 🌍 " -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  1. English (Default)"
Write-Host "  2. Bahasa Indonesia"
Write-Host "  3. Mandarin (中文)"
Write-Host "------------------------------------------------------" -ForegroundColor Cyan

$langChoice = Read-Host "  [1-3]"
switch ($langChoice) {
    "2" { Set-LangId }
    "3" { Set-LangZh }
    default { Set-LangEn }
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
    Write-Host "             $script:UI_TITLE            " -ForegroundColor Cyan
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Get-SysInfo {
    Write-Host $script:UI_GATHER_SYS -ForegroundColor Yellow
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
    Write-Host $script:UI_CPU_TEST -ForegroundColor Yellow
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
    Write-Host "  $script:UI_COMPLETED $($elapsed)s -> $script:UI_SCORE: $script:cpuScore`n" -ForegroundColor Green
}

function Run-RamBench {
    Write-Host $script:UI_RAM_TEST -ForegroundColor Yellow
    $time = Measure-Command {
        $size = 250MB
        $bytes = New-Object byte[] $size
        $rnd = New-Object Random
        $rnd.NextBytes($bytes)
        [System.GC]::Collect()
    }
    $elapsed = [math]::Round($time.TotalSeconds, 3)
    $speedMBps = [math]::Round((250 / $elapsed), 2)
    $script:ramScore = [math]::Floor($speedMBps * 12)
    Write-Host "  [V] Memory $script:UI_SPEED: $speedMBps MB/s -> $script:UI_SCORE: $script:ramScore`n" -ForegroundColor Green
}

function Run-DiskBench {
    Write-Host $script:UI_DISK_TEST -ForegroundColor Yellow
    $testFile = "$env:TEMP\.spectra_disk_test.tmp"
    $time = Measure-Command {
        $fs = [System.IO.File]::Create($testFile)
        $buffer = New-Object byte[] 1MB
        for ($i = 0; $i -lt 500; $i++) {
            $fs.Write($buffer, 0, $buffer.Length)
        }
        $fs.Flush()
        $fs.Close()
    }
    Remove-Item $testFile -Force
    $elapsed = [math]::Round($time.TotalSeconds, 3)
    $speedMBps = [math]::Round((500 / $elapsed), 2)
    $script:diskScore = [math]::Floor($speedMBps * 8)
    Write-Host "  [V] Disk $script:UI_SPEED: $speedMBps MB/s -> $script:UI_SCORE: $script:diskScore`n" -ForegroundColor Green
}

function Show-Results {
    $totalScore = $script:cpuScore + $script:ramScore + $script:diskScore
    Write-Host "===============================================================" -ForegroundColor Magenta
    Write-Host "                 $script:UI_RES_TITLE               " -ForegroundColor White
    Write-Host "===============================================================" -ForegroundColor Magenta
    Write-Host "  CPU $script:UI_SCORE     : $script:cpuScore" -ForegroundColor Cyan
    Write-Host "  RAM $script:UI_SCORE     : $script:ramScore" -ForegroundColor Cyan
    Write-Host "  Disk $script:UI_SCORE    : $script:diskScore" -ForegroundColor Cyan
    Write-Host "---------------------------------------------------------------"
    Write-Host "  $script:UI_TOTAL   : $totalScore" -ForegroundColor Yellow
    Write-Host "===============================================================" -ForegroundColor Magenta
}

Draw-Banner
Get-SysInfo
Run-CpuBench
Run-RamBench
Run-DiskBench
Show-Results
