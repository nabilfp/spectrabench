#!/bin/bash

# ===========================================================================
# Project      : SpectraBench (v1.1-Multilanguage)
# Description  : Zero-Dependency Cross-Platform System Benchmark
# Author       : Nabil
# Architecture : Pure Bash & AWK (Linux Native)
# ===========================================================================

# --- [ TRAP: GRACEFUL EXIT ] ---
trap 'echo -e "\n\n\033[0;31m[!] Benchmark aborted. Cleaning up...\033[0m"; rm -f /dev/shm/.spectra_* /tmp/.spectra_*; exit 1' SIGINT SIGTERM

# --- [ ANTI-SPAM UTILITY ] ---
function clear_input_buffer() {
    while read -r -t 0.1; do :; done
}

# --- [ REQUIRE ROOT ] ---
if [[ $EUID -ne 0 ]]; then
   echo -e "\033[0;31m[!] Access Denied. SpectraBench requires root (sudo) for raw I/O access.\033[0m"
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

# --- [ LANGUAGE DICTIONARY (i18n) ] ---
function set_lang_en() {
    UI_TITLE="v1.1 Foundation | Linux Native Edition"
    UI_GATHER_SYS="[*] Gathering System Architecture..."
    UI_CPU_TEST="[*] Running CPU Single-Core Test (Prime Sieve 100k)..."
    UI_RAM_TEST="[*] Running Volatile Memory I/O Test (500MB to /dev/shm)..."
    UI_DISK_TEST="[*] Running Storage Drive I/O Test (500MB Sequential)..."
    UI_COMPLETED="[V] Completed in"
    UI_SPEED="Speed"
    UI_SCORE="Score"
    UI_RES_TITLE="🏆 SPECTRA BENCHMARK RESULTS 🏆"
    UI_TOTAL="TOTAL SCORE"
}

function set_lang_id() {
    UI_TITLE="v1.1 Foundation | Edisi Native Linux"
    UI_GATHER_SYS="[*] Mengumpulkan Data Arsitektur Sistem..."
    UI_CPU_TEST="[*] Menjalankan Tes CPU Single-Core (Prime Sieve 100k)..."
    UI_RAM_TEST="[*] Menjalankan Tes I/O Memori Volatil (500MB ke /dev/shm)..."
    UI_DISK_TEST="[*] Menjalankan Tes I/O Penyimpanan (500MB Sekuensial)..."
    UI_COMPLETED="[V] Selesai dalam"
    UI_SPEED="Kecepatan"
    UI_SCORE="Skor"
    UI_RES_TITLE="🏆 HASIL BENCHMARK SPECTRA 🏆"
    UI_TOTAL="TOTAL SKOR"
}

function set_lang_zh() {
    UI_TITLE="v1.1 基础版 | Linux 原生版本"
    UI_GATHER_SYS="[*] 正在收集系统架构信息..."
    UI_CPU_TEST="[*] 正在运行 CPU 单核测试 (素数筛选 100k)..."
    UI_RAM_TEST="[*] 正在运行易失性内存 I/O 测试 (500MB 至 /dev/shm)..."
    UI_DISK_TEST="[*] 正在运行存储驱动器 I/O 测试 (500MB 顺序)..."
    UI_COMPLETED="[V] 完成用时"
    UI_SPEED="速度"
    UI_SCORE="得分"
    UI_RES_TITLE="🏆 SPECTRA 基准测试结果 🏆"
    UI_TOTAL="总分"
}

# --- [ INTERACTIVE BOOTLOADER ] ---
printf '\033c'
echo -e "${CYAN}======================================================${RESET}"
echo -e "${GREEN} 🌍 SELECT YOUR LANGUAGE / PILIH BAHASA / 选择语言 🌍 ${RESET}"
echo -e "${CYAN}======================================================${RESET}"
echo -e "  1. English (Default)"
echo -e "  2. Bahasa Indonesia"
echo -e "  3. Mandarin (中文)"
echo -e "${CYAN}------------------------------------------------------${RESET}"

read -r -p "  [1-3]: " lang_choice
clear_input_buffer 

case $lang_choice in
    2) set_lang_id ;;
    3) set_lang_zh ;;
    *) set_lang_en ;;
esac

# --- [ MAIN FUNCTIONS ] ---
function draw_banner() {
    printf '\033c'
    echo -e "${MAGENTA}${BOLD}"
    echo "  ██████  ██▓███  ▓█████  ▄████▄  ▄▄▄█████▓ ██▀███   ▄▄▄       "
    echo "▒██    ▒ ▓██░  ██▒▓█   ▀ ▒██▀ ▀█  ▓  ██▒ ▓▒▓██ ▒ ██▒▒████▄     "
    echo "░ ▓██▄   ▓██░ ██▓▒▒███   ▒▓█    ▄ ▒ ▓██░ ▒░▓██ ░▄█ ▒▒██  ▀█▄   "
    echo "  ▒   ██▒▒██▄█▓▒ ▒▒▓█  ▄ ▒▓▓▄ ▄██▒░ ▓██▓ ░ ▒██▀▀█▄  ░██▄▄▄▄██  "
    echo "▒██████▒▒▒██▒ ░  ░░▒████▒▒ ▓███▀ ░  ▒██▒ ░ ░██▓ ▒██▒ ▓█   ▓██▒ "
    echo "░ ▒░▓  ░ ▒▓▒░ ░  ░░░ ▒░ ░░ ░▒ ▒  ░  ▒ ░░   ░ ▒▓ ░▒▓░ ▒▒   ▓▒█░ "
    echo "${CYAN}             ${UI_TITLE}            ${RESET}"
    echo -e "${CYAN}===============================================================${RESET}\n"
}

function get_sys_info() {
    echo -e "${YELLOW}${UI_GATHER_SYS}${RESET}"
    CPU_MODEL=$(awk -F': ' '/model name/ {print $2; exit}' /proc/cpuinfo)
    CPU_CORES=$(nproc)
    RAM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
    OS_NAME=$(cat /etc/os-release | grep "PRETTY_NAME" | cut -d'=' -f2 | tr -d '\"')
    
    echo -e "  ${CYAN}OS       :${RESET} $OS_NAME"
    echo -e "  ${CYAN}CPU      :${RESET} $CPU_MODEL ($CPU_CORES Cores)"
    echo -e "  ${CYAN}RAM      :${RESET} $RAM_TOTAL\n"
    sleep 1.5
}

function run_cpu_bench() {
    echo -e "${YELLOW}${UI_CPU_TEST}${RESET}"
    start_time=$(date +%s.%N)
    awk 'BEGIN{ for(i=2; i<=100000; i++){ p=1; for(j=2; j*j<=i; j++){ if(i%j==0){ p=0; break } } if(p) c++ } }'
    end_time=$(date +%s.%N)
    
    elapsed=$(awk "BEGIN {print $end_time - $start_time}")
    CPU_SCORE=$(awk "BEGIN {printf \"%d\", 50000 / $elapsed}")
    echo -e "  ${GREEN}${UI_COMPLETED} ${elapsed}s -> ${UI_SCORE}: ${BOLD}${CPU_SCORE}${RESET}\n"
}

function run_ram_bench() {
    echo -e "${YELLOW}${UI_RAM_TEST}${RESET}"
    RAM_FILE="/dev/shm/.spectra_ram_test"
    RAM_SPEED=$(dd if=/dev/zero of=$RAM_FILE bs=1M count=500 2>&1 | awk '/copied/ {print $10, $11}')
    rm -f $RAM_FILE
    
    raw_speed=$(echo "$RAM_SPEED" | awk '{print $1}')
    RAM_SCORE=$(awk "BEGIN {printf \"%d\", $raw_speed * 12}")
    echo -e "  ${GREEN}[V] Memory ${UI_SPEED}: $RAM_SPEED -> ${UI_SCORE}: ${BOLD}${RAM_SCORE}${RESET}\n"
}

function run_disk_bench() {
    echo -e "${YELLOW}${UI_DISK_TEST}${RESET}"
    DISK_FILE="/tmp/.spectra_disk_test"
    DISK_SPEED=$(dd if=/dev/zero of=$DISK_FILE bs=1M count=500 conv=fdatasync 2>&1 | awk '/copied/ {print $10, $11}')
    rm -f $DISK_FILE
    
    raw_speed=$(echo "$DISK_SPEED" | awk '{print $1}')
    DISK_SCORE=$(awk "BEGIN {printf \"%d\", $raw_speed * 8}")
    echo -e "  ${GREEN}[V] Disk ${UI_SPEED}: $DISK_SPEED -> ${UI_SCORE}: ${BOLD}${DISK_SCORE}${RESET}\n"
}

function show_results() {
    TOTAL_SCORE=$((CPU_SCORE + RAM_SCORE + DISK_SCORE))
    echo -e "${MAGENTA}===============================================================${RESET}"
    echo -e "${BOLD}                 ${UI_RES_TITLE}               ${RESET}"
    echo -e "${MAGENTA}===============================================================${RESET}"
    echo -e "  ${CYAN}CPU ${UI_SCORE}     :${RESET} $CPU_SCORE"
    echo -e "  ${CYAN}RAM ${UI_SCORE}     :${RESET} $RAM_SCORE"
    echo -e "  ${CYAN}Disk ${UI_SCORE}    :${RESET} $DISK_SCORE"
    echo -e "---------------------------------------------------------------"
    echo -e "  ${YELLOW}${BOLD}${UI_TOTAL}   : $TOTAL_SCORE${RESET}"
    echo -e "${MAGENTA}===============================================================${RESET}"
}

draw_banner
get_sys_info
run_cpu_bench
run_ram_bench
run_disk_bench
show_results
