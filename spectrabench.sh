#!/bin/bash

# ===========================================================================
# Project      : SpectraBench (v2.0-MultiThread)
# Description  : Zero-Dependency Cross-Platform System Benchmark
# Author       : Nabil
# Architecture : Pure Bash, Parallel Jobs & Thermal Detection
# ===========================================================================

# --- [ TRAP: GRACEFUL EXIT ] ---
trap 'echo -e "\n\n\033[0;31m[!] Benchmark aborted. Cleaning up...\033[0m"; rm -f /dev/shm/.spectra_* /tmp/.spectra_*; exit 1' SIGINT SIGTERM

# --- [ REQUIRE ROOT ] ---
if [[ $EUID -ne 0 ]]; then
   echo -e "\033[0;31m[!] Access Denied. SpectraBench requires root (sudo).\033[0m"
   exit 1
fi

# --- [ UI COLOR VARIABLES ] ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

function draw_banner() {
    printf '\033c'
    echo -e "${MAGENTA}${BOLD}"
    echo -e "  ██████  ██▓███  ▓█████  ▄████▄  ▄▄▄█████▓ ██▀███   ▄▄▄       "
    echo -e "▒██    ▒ ▓██░  ██▒▓█   ▀ ▒██▀ ▀█  ▓  ██▒ ▓▒▓██ ▒ ██▒▒████▄     "
    echo -e "░ ▓██▄   ▓██░ ██▓▒▒███   ▒▓█    ▄ ▒ ▓██░ ▒░▓██ ░▄█ ▒▒██  ▀█▄   "
    echo -e "  ▒   ██▒▒██▄█▓▒ ▒▒▓█  ▄ ▒▓▓▄ ▄██▒░ ▓██▓ ░ ▒██▀▀█▄  ░██▄▄▄▄██  "
    echo -e "▒██████▒▒▒██▒ ░  ░░▒████▒▒ ▓███▀ ░  ▒██▒ ░ ░██▓ ▒██▒ ▓█   ▓██▒ "
    echo -e "░ ▒░▓  ░ ▒▓▒░ ░  ░░░ ▒░ ░░ ░▒ ▒  ░  ▒ ░░   ░ ▒▓ ░▒▓░ ▒▒   ▓▒█░ ${RESET}"
    echo -e "${CYAN}          v2.0 Multi-Threaded | Linux Native Edition         ${RESET}"
    echo -e "${CYAN}===============================================================${RESET}\n"
}

function get_sys_info() {
    echo -e "${YELLOW}[*] Gathering System Architecture...${RESET}"
    CPU_MODEL=$(awk -F': ' '/model name/ {print $2; exit}' /proc/cpuinfo)
    CPU_CORES=$(nproc)
    RAM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
    OS_NAME=$(cat /etc/os-release | grep "PRETTY_NAME" | cut -d'=' -f2 | tr -d '\"')
    
    echo -e "  ${CYAN}OS       :${RESET} $OS_NAME"
    echo -e "  ${CYAN}CPU      :${RESET} $CPU_MODEL ($CPU_CORES Threads)"
    echo -e "  ${CYAN}RAM      :${RESET} $RAM_TOTAL\n"
    sleep 1.5
}

function get_temp() {
    local t_raw=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -nr | head -1)
    if [[ -n "$t_raw" && "$t_raw" -gt 0 ]]; then
        echo $(( t_raw / 1000 ))
    else
        echo "N/A"
    fi
}

function run_cpu_bench() {
    echo -e "${YELLOW}[*] Running Multi-Core Stress Test (SHA-256 on $CPU_CORES Threads)...${RESET}"
    temp_start=$(get_temp)
    
    start_time=$(date +%s.%N)
    
    # Spawning parallel background jobs equal to CPU Threads
    for ((i=1; i<=CPU_CORES; i++)); do
        dd if=/dev/zero bs=1M count=50 status=none | sha256sum > /dev/null &
    done
    wait # Wait for all background threads to finish
    
    end_time=$(date +%s.%N)
    temp_end=$(get_temp)
    
    elapsed=$(awk "BEGIN {print $end_time - $start_time}")
    # Math: Multiplied by core count to scale the score dynamically
    CPU_SCORE=$(awk "BEGIN {printf \"%d\", (10000 * $CPU_CORES) / $elapsed}")
    
    echo -e "  ${GREEN}[V] Completed in ${elapsed}s -> Score: ${BOLD}${CPU_SCORE}${RESET}"
    
    # Thermal Throttling Logic
    if [[ "$temp_start" != "N/A" && "$temp_end" != "N/A" ]]; then
        if [[ "$temp_end" -ge 85 ]]; then
            echo -e "  ${RED}[!] THERMAL THROTTLING DETECTED (Max: ${temp_end}°C)${RESET}\n"
        else
            echo -e "  ${CYAN}[ Thermals: ${temp_start}°C -> ${temp_end}°C ]${RESET}\n"
        fi
    else
        echo -e "  ${CYAN}[ Thermals: N/A (Locked by OEM) ]${RESET}\n"
    fi
}

function run_ram_bench() {
    echo -e "${YELLOW}[*] Running Volatile Memory I/O Test (500MB to /dev/shm)...${RESET}"
    RAM_FILE="/dev/shm/.spectra_ram_test"
    
    RAM_SPEED_FULL=$(LC_ALL=C dd if=/dev/zero of=$RAM_FILE bs=1M count=500 2>&1 | awk '/copied/ {print $(NF-1), $NF}')
    rm -f $RAM_FILE
    
    raw_val=$(echo "$RAM_SPEED_FULL" | awk '{print $1}')
    unit=$(echo "$RAM_SPEED_FULL" | awk '{print $2}')
    
    if [[ "$unit" == *"GB/s"* ]]; then
        raw_val=$(awk "BEGIN {print $raw_val * 1024}")
    elif [[ "$unit" == *"kB/s"* ]]; then
        raw_val=$(awk "BEGIN {print $raw_val / 1024}")
    fi
    
    RAM_SCORE=$(awk "BEGIN {printf \"%d\", $raw_val * 12}")
    echo -e "  ${GREEN}[V] Memory Speed: $RAM_SPEED_FULL -> Score: ${BOLD}${RAM_SCORE}${RESET}\n"
}

function run_disk_bench() {
    echo -e "${YELLOW}[*] Running Storage Drive I/O Test (500MB Sequential)...${RESET}"
    DISK_FILE="/tmp/.spectra_disk_test"
    
    DISK_SPEED_FULL=$(LC_ALL=C dd if=/dev/zero of=$DISK_FILE bs=1M count=500 conv=fdatasync 2>&1 | awk '/copied/ {print $(NF-1), $NF}')
    rm -f $DISK_FILE
    
    raw_val=$(echo "$DISK_SPEED_FULL" | awk '{print $1}')
    unit=$(echo "$DISK_SPEED_FULL" | awk '{print $2}')
    
    if [[ "$unit" == *"GB/s"* ]]; then
        raw_val=$(awk "BEGIN {print $raw_val * 1024}")
    elif [[ "$unit" == *"kB/s"* ]]; then
        raw_val=$(awk "BEGIN {print $raw_val / 1024}")
    fi
    
    DISK_SCORE=$(awk "BEGIN {printf \"%d\", $raw_val * 8}")
    echo -e "  ${GREEN}[V] Disk Speed: $DISK_SPEED_FULL -> Score: ${BOLD}${DISK_SCORE}${RESET}\n"
}

function show_results() {
    TOTAL_SCORE=$((CPU_SCORE + RAM_SCORE + DISK_SCORE))
    echo -e "${MAGENTA}===============================================================${RESET}"
    echo -e "${BOLD}                 🏆 SPECTRA BENCHMARK RESULTS 🏆               ${RESET}"
    echo -e "${MAGENTA}===============================================================${RESET}"
    echo -e "  ${CYAN}CPU Score      :${RESET} $CPU_SCORE"
    echo -e "  ${CYAN}RAM Score      :${RESET} $RAM_SCORE"
    echo -e "  ${CYAN}Disk Score     :${RESET} $DISK_SCORE"
    echo -e "---------------------------------------------------------------"
    echo -e "  ${YELLOW}${BOLD}TOTAL SCORE    : $TOTAL_SCORE${RESET}"
    echo -e "${MAGENTA}===============================================================${RESET}"
}

draw_banner
get_sys_info
run_cpu_bench
run_ram_bench
run_disk_bench
show_results
