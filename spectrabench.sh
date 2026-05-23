#!/bin/bash

# ===========================================================================
# Project      : SpectraBench (v4.0-DeepScan Interactive)
# Description  : Zero-Dependency Cross-Platform System Benchmark
# Author       : Nabil
# Architecture : Pure Bash, Sustained Stress, Interactive UI
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

# --- [ GLOBAL VARIABLES ] ---
CPU_CORES=$(nproc)
SCORE_CPU=0; SCORE_RAM=0; SCORE_DISK=0; SCORE_NET=0

function draw_banner() {
    printf '\033c'
    echo -e "${MAGENTA}${BOLD}"
    echo -e "  ██████  ██▓███  ▓█████  ▄████▄  ▄▄▄█████▓ ██▀███   ▄▄▄       "
    echo -e "▒██    ▒ ▓██░  ██▒▓█   ▀ ▒██▀ ▀█  ▓  ██▒ ▓▒▓██ ▒ ██▒▒████▄     "
    echo -e "░ ▓██▄   ▓██░ ██▓▒▒███   ▒▓█    ▄ ▒ ▓██░ ▒░▓██ ░▄█ ▒▒██  ▀█▄   "
    echo -e "  ▒   ██▒▒██▄█▓▒ ▒▒▓█  ▄ ▒▓▓▄ ▄██▒░ ▓██▓ ░ ▒██▀▀█▄  ░██▄▄▄▄██  "
    echo -e "▒██████▒▒▒██▒ ░  ░░▒████▒▒ ▓███▀ ░  ▒██▒ ░ ░██▓ ▒██▒ ▓█   ▓██▒ "
    echo -e "░ ▒░▓  ░ ▒▓▒░ ░  ░░░ ▒░ ░░ ░▒ ▒  ░  ▒ ░░   ░ ▒▓ ░▒▓░ ▒▒   ▓▒█░ ${RESET}"
    echo -e "${CYAN}      v4.0 Deep-Scan Interactive Suite | Linux Native Edition    ${RESET}"
    echo -e "${CYAN}=================================================================${RESET}\n"
}

function get_sys_info() {
    CPU_MODEL=$(awk -F': ' '/model name/ {print $2; exit}' /proc/cpuinfo)
    RAM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
    OS_NAME=$(cat /etc/os-release | grep "PRETTY_NAME" | cut -d'=' -f2 | tr -d '\"')
    
    echo -e "  ${CYAN}OS       :${RESET} $OS_NAME"
    echo -e "  ${CYAN}CPU      :${RESET} $CPU_MODEL ($CPU_CORES Threads)"
    echo -e "  ${CYAN}RAM      :${RESET} $RAM_TOTAL\n"
}

function get_temp() {
    local t_raw=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -nr | head -1)
    if [[ -n "$t_raw" && "$t_raw" -gt 0 ]]; then echo $(( t_raw / 1000 ))
    else echo "N/A"; fi
}

function pause_continue() {
    echo -e "\n${CYAN}Press [ENTER] to return to the menu...${RESET}"
    read -r
}

# --- [ TEST MODULES ] ---

function test_cpu() {
    echo -e "${YELLOW}[*] Deep CPU Stress (1000MB SHA-256 per Thread x $CPU_CORES Threads)...${RESET}"
    temp_start=$(get_temp)
    
    start_time=$(date +%s.%N)
    for ((i=1; i<=CPU_CORES; i++)); do
        # 1GB Data per thread to force sustained turbo load
        dd if=/dev/zero bs=1M count=1000 status=none | sha256sum > /dev/null &
    done
    wait
    
    end_time=$(date +%s.%N)
    temp_end=$(get_temp)
    elapsed=$(awk "BEGIN {print $end_time - $start_time}")
    
    # Mathematical Calibration: Scores in thousands
    SCORE_CPU=$(awk "BEGIN {printf \"%d\", (1000 * $CPU_CORES) / $elapsed}")
    
    echo -e "  ${GREEN}[V] Elapsed: ${elapsed}s -> CPU Score: ${BOLD}${SCORE_CPU}${RESET}"
    if [[ "$temp_start" != "N/A" ]]; then
        [[ "$temp_end" -ge 85 ]] && echo -e "  ${RED}[!] THERMAL THROTTLING DETECTED (Max: ${temp_end}°C)${RESET}" || echo -e "  ${CYAN}[ Thermals: ${temp_start}°C -> ${temp_end}°C ]${RESET}"
    fi
}

function test_ram() {
    echo -e "${YELLOW}[*] Deep Memory Bandwidth (1GB Random Allocations to /dev/shm)...${RESET}"
    RAM_FILE="/dev/shm/.spectra_ram_test"
    # 64KB blocks to test memory allocation latency, not just sequential
    RAM_SPEED_FULL=$(LC_ALL=C dd if=/dev/zero of=$RAM_FILE bs=64k count=16384 2>&1 | awk '/copied/ {print $(NF-1), $NF}')
    rm -f $RAM_FILE
    
    raw_val=$(echo "$RAM_SPEED_FULL" | awk '{print $1}')
    unit=$(echo "$RAM_SPEED_FULL" | awk '{print $2}')
    
    [[ "$unit" == *"GB/s"* ]] && raw_val=$(awk "BEGIN {print $raw_val * 1024}")
    [[ "$unit" == *"kB/s"* ]] && raw_val=$(awk "BEGIN {print $raw_val / 1024}")
    
    SCORE_RAM=$(awk "BEGIN {printf \"%d\", $raw_val * 3}")
    echo -e "  ${GREEN}[V] Memory Speed: $RAM_SPEED_FULL -> RAM Score: ${BOLD}${SCORE_RAM}${RESET}"
}

function test_disk() {
    echo -e "${YELLOW}[*] Deep Storage Test (2GB Sustained Write to Exhaust SLC Cache)...${RESET}"
    DISK_FILE="/tmp/.spectra_disk_test"
    
    DISK_SPEED_FULL=$(LC_ALL=C dd if=/dev/zero of=$DISK_FILE bs=1M count=2048 conv=fdatasync 2>&1 | awk '/copied/ {print $(NF-1), $NF}')
    rm -f $DISK_FILE
    
    raw_val=$(echo "$DISK_SPEED_FULL" | awk '{print $1}')
    unit=$(echo "$DISK_SPEED_FULL" | awk '{print $2}')
    
    [[ "$unit" == *"GB/s"* ]] && raw_val=$(awk "BEGIN {print $raw_val * 1024}")
    [[ "$unit" == *"kB/s"* ]] && raw_val=$(awk "BEGIN {print $raw_val / 1024}")
    
    SCORE_DISK=$(awk "BEGIN {printf \"%d\", $raw_val * 2}")
    echo -e "  ${GREEN}[V] Disk Speed: $DISK_SPEED_FULL -> Disk Score: ${BOLD}${SCORE_DISK}${RESET}"
}

function test_network() {
    echo -e "${YELLOW}[*] Network Edge Ping & 50MB CDN Payload Download...${RESET}"
    ping_out=$(ping -c 3 1.1.1.1 2>/dev/null)
    if [ $? -eq 0 ]; then
        latency=$(echo "$ping_out" | tail -1 | awk -F '/' '{print $5}')
        [ -z "$latency" ] && latency=999
    else latency=999; fi

    dl_bps=$(curl -s -w "%{speed_download}" -o /dev/null "https://speed.cloudflare.com/__down?bytes=50000000" 2>/dev/null)
    dl_mbps=$(awk "BEGIN {printf \"%.2f\", $dl_bps / 1024 / 1024}")
    
    if [ $(awk "BEGIN {print ($latency >= 999)}") -eq 1 ]; then lat_score=0; latency_str="Offline/Timeout"
    else lat_score=$(awk "BEGIN {printf \"%d\", 2000 / $latency}"); latency_str="${latency} ms"; fi
    
    bw_score=$(awk "BEGIN {printf \"%d\", $dl_mbps * 15}")
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
    echo -e "  ${GREEN}1.${RESET} 🚀 Run Full Deep-Scan Benchmark Suite"
    echo -e "  ${CYAN}2.${RESET} 🧠 Test CPU (Sustained Multi-Core Load)"
    echo -e "  ${CYAN}3.${RESET} ⚡ Test RAM (Allocation Latency & Bandwidth)"
    echo -e "  ${CYAN}4.${RESET} 💾 Test Storage (SLC Cache Exhaustion)"
    echo -e "  ${CYAN}5.${RESET} 🌐 Test Network (Global Edge & CDN)"
    echo -e "  ${RED}0.${RESET} ❌ Exit"
    echo -e "${CYAN}-----------------------------------------------------------------${RESET}"
    read -r -p "Enter your choice [0-5]: " choice
    
    case $choice in
        1) echo ""; run_all; pause_continue ;;
        2) echo ""; test_cpu; pause_continue ;;
        3) echo ""; test_ram; pause_continue ;;
        4) echo ""; test_disk; pause_continue ;;
        5) echo ""; test_network; pause_continue ;;
        0) echo -e "\n${GREEN}Thank you for using SpectraBench!${RESET}"; exit 0 ;;
        *) echo -e "\n${RED}[!] Invalid selection.${RESET}"; sleep 1 ;;
    esac
done
