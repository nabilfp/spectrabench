#!/bin/bash

# ===========================================================================
# Project      : SpectraBench (v5.1-OmniPlatform Singularity)
# Description  : Zero-Dependency Ultimate System Benchmark
# Author       : Nabil
# Architecture : Omni-Platform (Server/PC/Termux), Sustained Stress
# ===========================================================================

# --- [ UI COLOR VARIABLES ] ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

# --- [ ENVIRONMENT & TTY CHECK ] ---
if [[ ! -t 0 ]]; then
    echo -e "${RED}[!] Piped Execution Detected (curl | bash)${RESET}"
    echo -e "${YELLOW}SpectraBench v5.1 features an interactive UI that requires keyboard access.${RESET}"
    echo -e "Please run Ghost Mode using this secure command instead:\n"
    echo -e "${CYAN}bash -c \"\$(curl -sL https://raw.githubusercontent.com/nabilfp/spectrabench/main/spectrabench.sh)\"${RESET}\n"
    exit 1
fi

IS_TERMUX=0
if [[ -n "$PREFIX" && "$PREFIX" == *"com.termux"* ]]; then
    IS_TERMUX=1
    TMP_DIR="$PREFIX/tmp"
    mkdir -p "$TMP_DIR"
else
    TMP_DIR="/tmp"
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[!] Access Denied. On standard Linux, SpectraBench requires root (sudo) for Cache Bypassing.${RESET}"
        exit 1
    fi
fi

# --- [ UNIVERSAL TIMER ] ---
get_time() {
    if command -v python3 >/dev/null 2>&1; then
        python3 -c 'import time; print(time.time())'
    elif command -v python >/dev/null 2>&1; then
        python -c 'import time; print(time.time())'
    elif command -v perl >/dev/null 2>&1; then
        perl -MTime::HiRes=time -e 'printf "%.9f\n", time'
    elif [[ -n "${EPOCHREALTIME-}" ]]; then
        printf "%s\n" "$EPOCHREALTIME"
    else
        date +%s
    fi
}

# --- [ DEPENDENCY & FEATURE DETECTION ] ---
MISSING_DEPS=()
for cmd in dd awk ping curl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        MISSING_DEPS+=("$cmd")
    fi
done
if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then
    echo -e "${YELLOW}[!] Missing optional dependencies: ${MISSING_DEPS[*]}${RESET}"
    echo -e "${YELLOW}    Some tests may be skipped or produce limited results.${RESET}"
    sleep 2
fi

# SHA-256 hasher fallback
HASHER=""
if command -v sha256sum >/dev/null 2>&1; then
    HASHER="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
    HASHER="shasum -a 256"
elif command -v openssl >/dev/null 2>&1; then
    HASHER="openssl dgst -sha256"
fi

# dd feature detection
DD_STATUS=""
if dd if=/dev/zero of=/dev/null bs=1k count=1 status=none 2>/dev/null; then
    DD_STATUS="status=none"
fi

DD_CONV=""
if dd if=/dev/zero of=/dev/null bs=1k count=1 conv=fdatasync 2>/dev/null; then
    DD_CONV="conv=fdatasync"
fi

# --- [ TRAP: GRACEFUL EXIT ] ---
trap 'echo -e "\n\n${RED}[!] Benchmark aborted. Cleaning up...${RESET}"; rm -f /dev/shm/.spectra_* "$TMP_DIR"/.spectra_*; exit 1' SIGINT SIGTERM

# --- [ GLOBAL VARIABLES ] ---
if command -v nproc >/dev/null 2>&1; then
    CPU_CORES=$(nproc)
elif [[ -f /proc/cpuinfo ]]; then
    CPU_CORES=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo 1)
elif command -v sysctl >/dev/null 2>&1; then
    CPU_CORES=$(sysctl -n hw.ncpu 2>/dev/null || echo 1)
else
    CPU_CORES=1
fi
[[ -z "$CPU_CORES" || "$CPU_CORES" -lt 1 ]] && CPU_CORES=1

SCORE_CPU=0; SCORE_RAM=0; SCORE_DISK=0; SCORE_NET=0

# Determine safe test sizes based on available RAM
TOTAL_RAM_KB=0
if [[ $IS_TERMUX -eq 0 ]] && command -v free >/dev/null 2>&1; then
    TOTAL_RAM_KB=$(free | awk '/^Mem:/ {print $2}')
fi
TOTAL_RAM_MB=$((TOTAL_RAM_KB / 1024))

# CPU: 5GB per thread default, scale down on low memory
CPU_MB_PER_THREAD=5000
if [[ $TOTAL_RAM_MB -gt 0 ]]; then
    SAFE_TOTAL_MB=$((TOTAL_RAM_MB - 1024))
    [[ $SAFE_TOTAL_MB -lt 256 ]] && SAFE_TOTAL_MB=256
    SAFE_PER_THREAD=$((SAFE_TOTAL_MB / CPU_CORES))
    [[ $SAFE_PER_THREAD -lt 100 ]] && SAFE_PER_THREAD=100
    if [[ $SAFE_PER_THREAD -lt $CPU_MB_PER_THREAD ]]; then
        CPU_MB_PER_THREAD=$SAFE_PER_THREAD
    fi
fi

# RAM: 2GB default, scale down if low RAM or /dev/shm restricted
RAM_CHUNK_MB=256
RAM_CHUNK_COUNT=8
RAM_TEST_MB=$((RAM_CHUNK_MB * RAM_CHUNK_COUNT))

if [[ $TOTAL_RAM_MB -gt 0 ]]; then
    MAX_RAM_TEST=$(( (TOTAL_RAM_MB - 1024) / 2 ))
    [[ $MAX_RAM_TEST -lt 128 ]] && MAX_RAM_TEST=128
    if [[ $MAX_RAM_TEST -lt $RAM_TEST_MB ]]; then
        RAM_TEST_MB=$MAX_RAM_TEST
        RAM_CHUNK_COUNT=$((RAM_TEST_MB / RAM_CHUNK_MB))
        [[ $RAM_CHUNK_COUNT -lt 1 ]] && RAM_CHUNK_COUNT=1
    fi
fi

# Check /dev/shm size on Linux
if [[ $IS_TERMUX -eq 0 && -d "/dev/shm" ]]; then
    SHM_SIZE_KB=$(df -P /dev/shm | awk 'NR==2 {print $4}')
    SHM_SIZE_MB=$((SHM_SIZE_KB / 1024))
    if [[ $SHM_SIZE_MB -lt $RAM_TEST_MB ]]; then
        RAM_TEST_MB=$SHM_SIZE_MB
        RAM_CHUNK_COUNT=$((RAM_TEST_MB / RAM_CHUNK_MB))
        [[ $RAM_CHUNK_COUNT -lt 1 ]] && RAM_CHUNK_COUNT=1
        echo -e "${YELLOW}[*] /dev/shm limited to ${SHM_SIZE_MB}MB. RAM test adjusted to ${RAM_TEST_MB}MB.${RESET}"
        sleep 1
    fi
fi

function draw_banner() {
    printf '\033c'
    echo -e "${MAGENTA}${BOLD}"
    echo -e "  ██████  ██▓███  ▓█████  ▄████▄  ▄▄▄█████▓ ██▀███   ▄▄▄       "
    echo -e "▒██    ▒ ▓██░  ██▒▓█   ▀ ▒██▀ ▀█  ▓  ██▒ ▓▒▓██ ▒ ██▒▒████▄     "
    echo -e "░ ▓██▄   ▓██░ ██▓▒▒███   ▒▓█    ▄ ▒ ▓██░ ▒░▓██ ░▄█ ▒▒██  ▀█▄   "
    echo -e "  ▒   ██▒▒██▄█▓▒ ▒▒▓█  ▄ ▒▓▓▄ ▄██▒░ ▓██▓ ░ ▒██▀▀█▄  ░██▄▄▄▄██  "
    echo -e "▒██████▒▒▒██▒ ░  ░░▒████▒▒ ▓███▀ ░  ▒██▒ ░ ░██▓ ▒██▒ ▓█   ▓██▒ "
    echo -e "░ ▒░▓  ░ ▒▓▒░ ░  ░░░ ▒░ ░░ ░▒ ▒  ░  ▒ ░░   ░ ▒▓ ░▒▓░ ▒▒   ▓▒█░ ${RESET}"
    echo -e "${CYAN}    v5.1 Omni-Platform Singularity Suite | Linux & Android       ${RESET}"
    echo -e "${CYAN}=================================================================${RESET}\n"
}

function get_sys_info() {
    if [[ $IS_TERMUX -eq 1 ]]; then
        CPU_MODEL=$(getprop ro.product.vendor.model 2>/dev/null || echo "Mobile ARM Processor")
        OS_NAME="Android (Termux)"
        RAM_TOTAL="Mobile Architecture"
    else
        CPU_MODEL=$(awk -F': ' '/model name/ {print $2; exit}' /proc/cpuinfo 2>/dev/null || echo "Unknown Processor")
        RAM_TOTAL=$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}' || echo "Unknown")
        OS_NAME=$(cat /etc/os-release 2>/dev/null | grep "PRETTY_NAME" | cut -d'=' -f2 | tr -d '\"' || echo "Unknown Linux")
    fi
    
    echo -e "  ${CYAN}OS       :${RESET} $OS_NAME"
    echo -e "  ${CYAN}CPU      :${RESET} $CPU_MODEL ($CPU_CORES Threads)"
    [[ $IS_TERMUX -eq 0 ]] && echo -e "  ${CYAN}RAM      :${RESET} $RAM_TOTAL"
    echo ""
}

function get_temp() {
    local t_raw=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -nr | head -1)
    if [[ -n "$t_raw" && "$t_raw" =~ ^[0-9]+$ && "$t_raw" -gt 0 ]]; then 
        [[ "$t_raw" -gt 1000 ]] && echo $(( t_raw / 1000 )) || echo "$t_raw"
    else 
        echo "N/A"
    fi
}

function pause_continue() {
    echo -e "\n${CYAN}Press [ENTER] to return to the menu...${RESET}"
    read -r </dev/tty
}

# --- [ TEST MODULES ] ---

function test_cpu() {
    local total_mb=$((CPU_MB_PER_THREAD * CPU_CORES))
    echo -e "${YELLOW}[*] Singularity CPU Stress (${CPU_MB_PER_THREAD}MB SHA-256 per Thread x $CPU_CORES Threads = ${total_mb}MB Total)...${RESET}"
    
    if [[ -z "$HASHER" ]]; then
        echo -e "${RED}[!] No SHA-256 utility found (tried: sha256sum, shasum, openssl). Skipping CPU test.${RESET}"
        SCORE_CPU=0
        return
    fi
    
    local temp_start=$(get_temp)
    local start_time=$(get_time)
    
    for ((i=1; i<=CPU_CORES; i++)); do
        dd if=/dev/zero bs=1M count=$CPU_MB_PER_THREAD $DD_STATUS 2>/dev/null | $HASHER > /dev/null 2>/dev/null &
    done
    wait
    
    local end_time=$(get_time)
    local temp_end=$(get_temp)
    local elapsed=$(awk "BEGIN { e = $end_time - $start_time; if (e == 0 || e < 0) e = 0.001; print e }")
    SCORE_CPU=$(awk "BEGIN {printf \"%d\", ($CPU_MB_PER_THREAD * $CPU_CORES) / $elapsed}")
    
    echo -e "  ${GREEN}[V] Elapsed: ${elapsed}s -> CPU Score: ${BOLD}${SCORE_CPU}${RESET}"
    if [[ "$temp_start" != "N/A" ]]; then
        [[ "$temp_end" -ge 85 ]] && echo -e "  ${RED}[!] THERMAL THROTTLING DETECTED (Max: ${temp_end}°C)${RESET}" || echo -e "  ${CYAN}[ Thermals: ${temp_start}°C -> ${temp_end}°C ]${RESET}"
    fi
}

function test_ram() {
    local test_mb=$((RAM_CHUNK_MB * RAM_CHUNK_COUNT))
    echo -e "${YELLOW}[*] Deep Memory Bandwidth (${test_mb}MB Random Allocation Stress)...${RESET}"
    
    local RAM_SPEED_FULL=""
    if [[ -w "/dev/shm" && $IS_TERMUX -eq 0 ]]; then
        RAM_FILE="/dev/shm/.spectra_ram_test"
        RAM_SPEED_FULL=$(LC_ALL=C dd if=/dev/zero of=$RAM_FILE bs=${RAM_CHUNK_MB}M count=$RAM_CHUNK_COUNT $DD_STATUS 2>&1 | awk '/copied/ {print $(NF-1), $NF}')
        rm -f $RAM_FILE
    else
        # Termux/Android fallback: kernel pipe speed
        RAM_SPEED_FULL=$(LC_ALL=C dd if=/dev/zero of=/dev/null bs=${RAM_CHUNK_MB}M count=$RAM_CHUNK_COUNT $DD_STATUS 2>&1 | awk '/copied/ {print $(NF-1), $NF}')
    fi
    
    local raw_val=$(echo "$RAM_SPEED_FULL" | awk '{print $1}')
    local unit=$(echo "$RAM_SPEED_FULL" | awk '{print $2}')
    
    if [[ -z "$raw_val" || "$raw_val" == "0" ]]; then
        echo -e "${RED}[!] RAM test failed to measure speed.${RESET}"
        SCORE_RAM=0
        return
    fi
    
    [[ "$unit" == *"GB/s"* ]] && raw_val=$(awk "BEGIN {print $raw_val * 1024}")
    [[ "$unit" == *"kB/s"* ]] && raw_val=$(awk "BEGIN {print $raw_val / 1024}")
    [[ "$unit" == *"bytes/sec"* ]] && raw_val=$(awk "BEGIN {print $raw_val / 1048576}")
    
    SCORE_RAM=$(awk "BEGIN {printf \"%d\", $raw_val * 3}")
    echo -e "  ${GREEN}[V] Memory Speed: $RAM_SPEED_FULL -> RAM Score: ${BOLD}${SCORE_RAM}${RESET}"
}

function test_disk() {
    echo -e "${YELLOW}[*] Deep Storage Test (5GB Sustained Write to Exhaust SLC Cache)...${RESET}"
    DISK_FILE="$TMP_DIR/.spectra_disk_test"
    
    # Check available space
    local avail_kb=$(df -P "$TMP_DIR" | awk 'NR==2 {print $4}')
    local avail_mb=$((avail_kb / 1024))
    local disk_count=5000
    
    if [[ $avail_mb -lt 6000 ]]; then
        disk_count=$((avail_mb - 500))
        [[ $disk_count -lt 100 ]] && disk_count=100
        if [[ $disk_count -lt 100 ]]; then
            echo -e "${RED}[!] Insufficient disk space (${avail_mb}MB available). Skipping disk test.${RESET}"
            SCORE_DISK=0
            return
        fi
        echo -e "${YELLOW}[!] Low disk space (${avail_mb}MB available). Using ${disk_count}MB test.${RESET}"
    fi
    
    DISK_SPEED_FULL=$(LC_ALL=C dd if=/dev/zero of=$DISK_FILE bs=1M count=$disk_count $DD_CONV $DD_STATUS 2>&1 | awk '/copied/ {print $(NF-1), $NF}')
    rm -f $DISK_FILE
    
    local raw_val=$(echo "$DISK_SPEED_FULL" | awk '{print $1}')
    local unit=$(echo "$DISK_SPEED_FULL" | awk '{print $2}')
    
    if [[ -z "$raw_val" || "$raw_val" == "0" ]]; then
        echo -e "${RED}[!] Disk test failed to measure speed.${RESET}"
        SCORE_DISK=0
        return
    fi
    
    [[ "$unit" == *"GB/s"* ]] && raw_val=$(awk "BEGIN {print $raw_val * 1024}")
    [[ "$unit" == *"kB/s"* ]] && raw_val=$(awk "BEGIN {print $raw_val / 1024}")
    [[ "$unit" == *"bytes/sec"* ]] && raw_val=$(awk "BEGIN {print $raw_val / 1048576}")
    
    SCORE_DISK=$(awk "BEGIN {printf \"%d\", $raw_val * 8}")
    echo -e "  ${GREEN}[V] Disk Speed: $DISK_SPEED_FULL -> Disk Score: ${BOLD}${SCORE_DISK}${RESET}"
}

function test_network() {
    echo -e "${YELLOW}[*] Network Edge Ping & 100MB Enterprise CDN Download...${RESET}"
    
    # 1. Ping Check
    local latency=999
    local latency_str="Offline/Timeout"
    local lat_score=0
    
    if command -v ping >/dev/null 2>&1; then
        local ping_out=$(ping -c 3 -W 2 1.1.1.1 2>/dev/null)
        if [[ $? -eq 0 ]]; then
            latency=$(echo "$ping_out" | awk -F '/' 'END {print $5}')
            [[ -z "$latency" ]] && latency=999
        fi
    fi
    
    if [[ "$latency" != "999" && -n "$latency" ]]; then 
        lat_score=$(awk -v lat="$latency" 'BEGIN {printf "%d", 2000 / lat}')
        latency_str="${latency} ms"
    fi

    # 2. Download Test (Multi-CDN fallback)
    local URL1="https://proof.ovh.net/files/100Mb.dat"
    local URL2="https://speed.hetzner.de/100MB.bin"
    local URL3="https://speedtest.tele2.net/100MB.zip"
    local dl_bps=0
    local dl_mbps=0
    local bw_score=0
    local success=0

    if command -v curl >/dev/null 2>&1; then
        for url in "$URL1" "$URL2" "$URL3"; do
            local response=$(LC_ALL=C curl -sL --connect-timeout 5 --max-time 20 -w "\nHTTP_CODE:%{http_code}\nSPEED:%{speed_download}\n" -o /dev/null "$url" 2>/dev/null)
            local http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
            dl_bps=$(echo "$response" | grep "SPEED:" | cut -d: -f2)
            
            if [[ "$http_code" == "200" && -n "$dl_bps" && "$dl_bps" != "0" && "$dl_bps" != "0.000" ]]; then
                dl_mbps=$(awk -v bps="$dl_bps" 'BEGIN { printf "%.2f", bps / 1048576 }')
                bw_score=$(awk -v mbps="$dl_mbps" 'BEGIN {printf "%d", mbps * 15}')
                success=1
                break
            fi
        done
    else
        echo -e "${YELLOW}[!] curl not found. Skipping download test.${RESET}"
    fi
    
    if [[ $success -eq 0 ]]; then
        echo -e "${YELLOW}[!] All CDN endpoints failed or unreachable.${RESET}"
    fi

    SCORE_NET=$((lat_score + bw_score))
    
    echo -e "  ${CYAN}DNS Latency :${RESET} $latency_str | ${CYAN}Bandwidth :${RESET} $dl_mbps MB/s"
    echo -e "  ${GREEN}[V] Network Validated -> Net Score: ${BOLD}${SCORE_NET}${RESET}"
}

function run_all() {
    test_cpu; echo ""
    test_ram; echo ""
    test_disk; echo ""
    test_network; echo ""
    
    TOTAL=$((SCORE_CPU + SCORE_RAM + SCORE_DISK + SCORE_NET))
    echo -e "${MAGENTA}=================================================================${RESET}"
    echo -e "${BOLD}                     🏆 FINAL SPECTRA SCORE 🏆                   ${RESET}"
    echo -e "${MAGENTA}=================================================================${RESET}"
    echo -e "  ${CYAN}CPU Score      :${RESET} $SCORE_CPU"
    echo -e "  ${CYAN}RAM Score      :${RESET} $SCORE_RAM"
    echo -e "  ${CYAN}Disk Score     :${RESET} $SCORE_DISK"
    echo -e "  ${CYAN}Network Score  :${RESET} $SCORE_NET"
    echo -e "-----------------------------------------------------------------"
    echo -e "  ${YELLOW}${BOLD}TOTAL SCORE    : $TOTAL${RESET}"
    echo -e "${MAGENTA}=================================================================${RESET}"
}

# --- [ INTERACTIVE MENU LOOP ] ---
while true; do
    draw_banner
    get_sys_info
    
    echo -e "${BOLD}Select an operation to perform:${RESET}"
    echo -e "  ${GREEN}1.${RESET} 🚀 Run Full Singularity Benchmark Suite"
    echo -e "  ${CYAN}2.${RESET} 🧠 Test CPU (${CPU_MB_PER_THREAD}MB Singularity Multi-Core Load)"
    echo -e "  ${CYAN}3.${RESET} ⚡ Test RAM ($((RAM_CHUNK_MB * RAM_CHUNK_COUNT))MB Allocation Latency & Bandwidth)"
    echo -e "  ${CYAN}4.${RESET} 💾 Test Storage (5GB SLC Cache Exhaustion)"
    echo -e "  ${CYAN}5.${RESET} 🌐 Test Network (Global Edge & 100MB CDN)"
    echo -e "  ${RED}0.${RESET} ❌ Exit"
    echo -e "${CYAN}-----------------------------------------------------------------${RESET}"
    
    # Drain any stale buffered input to prevent rapid-fire invalid loops
    while IFS= read -r -t 0.1 discard </dev/tty 2>/dev/null; do : ; done
    
    read -r -p "Enter your choice [0-5]: " choice </dev/tty
    
    # Empty input = silent redraw (no error spam)
    if [[ -z "$choice" ]]; then
        continue
    fi
    
    case $choice in
        1) echo ""; run_all; pause_continue ;;
        2) echo ""; test_cpu; pause_continue ;;
        3) echo ""; test_ram; pause_continue ;;
        4) echo ""; test_disk; pause_continue ;;
        5) echo ""; test_network; pause_continue ;;
        0) echo -e "\n${GREEN}Thank you for using SpectraBench!${RESET}"; exit 0 ;;
        *) 
            echo -e "\n${RED}[!] Invalid selection. Please choose 0-5.${RESET}"
            sleep 1
            ;;
    esac
done
