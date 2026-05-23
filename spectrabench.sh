#!/bin/bash

# ===========================================================================
# Project      : SpectraBench (v5.0-Precision)
# Description  : Zero-Dependency, Sustained-Load Precision Benchmark
# Author       : Nabil
# Architecture : Multi-Pass Averaging, Cache Flush, Sustained Thermal Stress
# ===========================================================================

# --- [ SECURITY: TTY CHECK ] ---
if [[ ! -t 0 ]]; then
    echo -e "\033[0;31m[!] Piped Execution Detected. Please use: sudo bash -c \"\$(curl ...)\"\033[0m"
    exit 1
fi

# --- [ SETUP ] ---
trap 'echo -e "\n\nAborted."; rm -f /dev/shm/.spectra_* /tmp/.spectra_*; exit 1' SIGINT SIGTERM
[[ $EUID -ne 0 ]] && { echo "Must be root."; exit 1; }

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; MAGENTA='\033[0;35m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; RESET='\033[0m'
CORES=$(nproc)

function draw_banner() {
    printf '\033c'
    echo -e "${MAGENTA}${BOLD}v5.0 Precision Suite | Sustained Load Edition${RESET}\n"
}

function get_temp() {
    local t=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -nr | head -1)
    [[ -n "$t" ]] && echo $(( t / 1000 )) || echo "N/A"
}

function test_cpu() {
    echo -e "${YELLOW}[*] PHASE 1: Sustained CPU Stress (5 Passes, 5GB Payload/Thread)...${RESET}"
    local total_score=0
    # Warm-up
    dd if=/dev/zero bs=1M count=1000 | sha256sum > /dev/null
    
    for i in {1..5}; do
        start=$(date +%s.%N)
        for ((j=1; j<=CORES; j++)); do
            dd if=/dev/zero bs=1M count=5000 status=none | sha256sum > /dev/null &
        done
        wait
        end=$(date +%s.%N)
        diff=$(awk "BEGIN {print $end - $start}")
        pass_score=$(awk "BEGIN {printf \"%d\", (5000 * $CORES) / $diff}")
        total_score=$((total_score + pass_score))
        echo -e "    Pass $i: ${diff}s | Score: $pass_score"
    done
    SCORE_CPU=$((total_score / 5))
    echo -e "${GREEN}[V] Final CPU Score: ${BOLD}${SCORE_CPU}${RESET}\n"
}

function test_ram() {
    echo -e "${YELLOW}[*] PHASE 2: Sustained RAM Latency Test...${RESET}"
    # Flush caches for accuracy
    sync; echo 3 > /proc/sys/vm/drop_caches
    RAM_FILE="/dev/shm/.spectra_ram"
    # 2GB read/write to test sustained bandwidth
    speed=$(LC_ALL=C dd if=/dev/zero of=$RAM_FILE bs=1M count=2048 2>&1 | awk '/copied/ {print $(NF-1), $NF}')
    rm -f $RAM_FILE
    raw=$(echo "$speed" | awk '{print $1}')
    SCORE_RAM=$(awk "BEGIN {printf \"%d\", $raw * 3}")
    echo -e "${GREEN}[V] RAM Score: ${BOLD}${SCORE_RAM}${RESET}\n"
}

function test_disk() {
    echo -e "${YELLOW}[*] PHASE 3: Sustained Storage Stress (4GB WriteThrough)...${RESET}"
    DISK_FILE="/tmp/.spectra_disk"
    speed=$(LC_ALL=C dd if=/dev/zero of=$DISK_FILE bs=1M count=4096 conv=fdatasync 2>&1 | awk '/copied/ {print $(NF-1), $NF}')
    rm -f $DISK_FILE
    raw=$(echo "$speed" | awk '{print $1}')
    SCORE_DISK=$(awk "BEGIN {printf \"%d\", $raw * 2}")
    echo -e "${GREEN}[V] Disk Score: ${BOLD}${SCORE_DISK}${RESET}\n"
}

function run_all() {
    test_cpu
    test_ram
    test_disk
    echo -e "${MAGENTA}==================================${RESET}"
    echo -e "${BOLD} TOTAL PRECISION SCORE: $((SCORE_CPU + SCORE_RAM + SCORE_DISK)) ${RESET}"
    echo -e "${MAGENTA}==================================${RESET}"
}

while true; do
    draw_banner
    echo -e "1. Run Precision Suite\n0. Exit"
    read -r -p "Choice: " ch </dev/tty
    [[ $ch == "1" ]] && run_all && pause_continue
    [[ $ch == "0" ]] && exit
done
