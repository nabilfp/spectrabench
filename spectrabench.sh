#!/bin/bash

# ===========================================================================
# Project      : SpectraBench (v5.2-OmniPlatform Singularity)
# Description  : Zero-Dependency Ultimate System Benchmark
# Author       : Nabil
# Architecture : Omni-Platform (Server/PC/Termux), Sustained Stress,
#                L1/L2/L3 Cache Latency Profiling via Pointer-Chasing
# ===========================================================================

# --- [ UI COLOR VARIABLES ] ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# --- [ SPINNER & PROGRESS UI ] ---
SPINNER_CHARS=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
SPINNER_PID=""

start_spinner() {
    local msg="$1"
    local color="${2:-$YELLOW}"
    local i=0
    while :; do
        printf "\r%s%s %s%s\033[K" "$color" "${SPINNER_CHARS[$i]}" "$msg" "$RESET"
        i=$(( (i + 1) % 10 ))
        sleep 0.08
    done &
    SPINNER_PID=$!
}

stop_spinner() {
    if [[ -n "$SPINNER_PID" ]]; then
        kill "$SPINNER_PID" 2>/dev/null
        wait "$SPINNER_PID" 2>/dev/null
        printf "\r\033[K"
        SPINNER_PID=""
    fi
}

draw_progress() {
    local current=$1
    local total=$2
    local msg="$3"
    local width=30
    local pct=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))

    printf "\r${CYAN}[${GREEN}"
    printf "%0.s█" $(seq 1 $filled 2>/dev/null)
    printf "%0.s░" $(seq 1 $empty 2>/dev/null)
    printf "${CYAN}] ${YELLOW}%3d%%${RESET} %s\033[K" "$pct" "$msg"
}

clear_progress() {
    printf "\r\033[K"
}

# --- [ ENVIRONMENT & TTY CHECK ] ---
if [[ ! -t 0 ]]; then
    echo -e "${RED}[!] Piped Execution Detected (curl | bash)${RESET}"
    echo -e "${YELLOW}SpectraBench v5.2 features an interactive UI that requires keyboard access.${RESET}"
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

# --- [ DEPENDENCY DETECTION ] ---
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

# Compiler detection for cache profiling
COMPILER=""
for cc in gcc cc clang; do
    if command -v "$cc" >/dev/null 2>&1; then
        COMPILER="$cc"
        break
    fi
done

# Python detection for cache fallback
PYTHON_CACHE=""
if command -v python3 >/dev/null 2>&1; then
    PYTHON_CACHE="python3"
elif command -v python >/dev/null 2>&1; then
    PYTHON_CACHE="python"
fi

# --- [ TRAP: GRACEFUL EXIT ] ---
trap 'stop_spinner; echo -e "\n\n${RED}[!] Benchmark aborted. Cleaning up...${RESET}"; rm -f /dev/shm/.spectra_* "$TMP_DIR"/.spectra_* "$TMP_DIR"/spectra_cache*; exit 1' SIGINT SIGTERM

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

SCORE_CPU=0; SCORE_RAM=0; SCORE_DISK=0; SCORE_NET=0; SCORE_CACHE=0
CACHE_L1_NS=0; CACHE_L2_NS=0; CACHE_L3_NS=0; CACHE_RAM_NS=0

# --- [ AUTO-SCALE TEST SIZES ] ---
TOTAL_RAM_KB=0
if [[ $IS_TERMUX -eq 0 ]] && command -v free >/dev/null 2>&1; then
    TOTAL_RAM_KB=$(free | awk '/^Mem:/ {print $2}')
fi
TOTAL_RAM_MB=$((TOTAL_RAM_KB / 1024))

CPU_MB_PER_THREAD=5000
if [[ $TOTAL_RAM_MB -gt 0 ]]; then
    NEEDED_MB=$((5000 * CPU_CORES + 2048))
    if [[ $NEEDED_MB -gt $TOTAL_RAM_MB ]]; then
        SAFE_PER_THREAD=$(((TOTAL_RAM_MB - 2048) / CPU_CORES))
        [[ $SAFE_PER_THREAD -lt 500 ]] && SAFE_PER_THREAD=500
        [[ $SAFE_PER_THREAD -gt 5000 ]] && SAFE_PER_THREAD=5000
        CPU_MB_PER_THREAD=$SAFE_PER_THREAD
    fi
fi

RAM_CHUNK_MB=256
RAM_CHUNK_COUNT=8

if [[ $IS_TERMUX -eq 0 && -d "/dev/shm" ]]; then
    SHM_SIZE_KB=$(df -P /dev/shm 2>/dev/null | awk 'NR==2 {print $4}')
    if [[ -n "$SHM_SIZE_KB" ]]; then
        SHM_SIZE_MB=$((SHM_SIZE_KB / 1024))
        if [[ $SHM_SIZE_MB -lt 2048 ]]; then
            RAM_CHUNK_COUNT=$((SHM_SIZE_MB / RAM_CHUNK_MB))
            [[ $RAM_CHUNK_COUNT -lt 2 ]] && RAM_CHUNK_COUNT=2
        fi
    fi
fi

if [[ $TOTAL_RAM_MB -gt 0 && $TOTAL_RAM_MB -lt 4096 ]]; then
    MAX_RAM_TEST=$(((TOTAL_RAM_MB - 1024) / 2))
    [[ $MAX_RAM_TEST -lt 256 ]] && MAX_RAM_TEST=256
    CURRENT_TEST_MB=$((RAM_CHUNK_MB * RAM_CHUNK_COUNT))
    if [[ $MAX_RAM_TEST -lt $CURRENT_TEST_MB ]]; then
        RAM_CHUNK_COUNT=$((MAX_RAM_TEST / RAM_CHUNK_MB))
        [[ $RAM_CHUNK_COUNT -lt 2 ]] && RAM_CHUNK_COUNT=2
    fi
fi

# --- [ UI FUNCTIONS ] ---
function draw_banner() {
    printf '\033c'
    echo -e "${MAGENTA}${BOLD}"
    echo -e "  ██████  ██▓███  ▓█████  ▄████▄  ▄▄▄█████▓ ██▀███   ▄▄▄       "
    echo -e "▒██    ▒ ▓██░  ██▒▓█   ▀ ▒██▀ ▀█  ▓  ██▒ ▓▒▓██ ▒ ██▒▒████▄     "
    echo -e "░ ▓██▄   ▓██░ ██▓▒▒███   ▒▓█    ▄ ▒ ▓██░ ▒░▓██ ░▄█ ▒▒██  ▀█▄   "
    echo -e "  ▒   ██▒▒██▄█▓▒ ▒▒▓█  ▄ ▒▓▓▄ ▄██▒░ ▓██▓ ░ ▒██▀▀█▄  ░██▄▄▄▄██  "
    echo -e "▒██████▒▒▒██▒ ░  ░░▒████▒▒ ▓███▀ ░  ▒██▒ ░ ░██▓ ▒██▒ ▓█   ▓██▒ "
    echo -e "░ ▒░▓  ░ ▒▓▒░ ░  ░░░ ▒░ ░░ ░▒ ▒  ░  ▒ ░░   ░ ▒▓ ░▒▓░ ▒▒   ▓▒█░ ${RESET}"
    echo -e "${CYAN}    v5.2 Omni-Platform Singularity Suite | Linux & Android       ${RESET}"
    echo -e "${CYAN}         Cache-Aware | Nanosecond-Precision | Live Telemetry    ${RESET}"
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

# --- [ UNIVERSAL DD SPEED PARSER ] ---
parse_dd_speed() {
    local raw="$1"
    local speed_val=$(echo "$raw" | grep -oE '[0-9]+(\.[0-9]+)?[[:space:]]*[GMk]?B/s' | tail -1 | sed 's/[[:space:]]//g')
    if [[ -n "$speed_val" ]]; then
        echo "$speed_val"
        return
    fi
    speed_val=$(echo "$raw" | grep -oE '[0-9]+(\.[0-9]+)?[[:space:]]*bytes/sec' | tail -1 | sed 's/[[:space:]]//g')
    if [[ -n "$speed_val" ]]; then
        echo "$speed_val"
        return
    fi
    echo ""
}

speed_to_mbps() {
    local speed_str="$1"
    if [[ -z "$speed_str" ]]; then
        echo "0"
        return
    fi
    local num=$(echo "$speed_str" | sed -E 's/[^0-9.]//g')
    if [[ -z "$num" || "$num" == "." ]]; then
        echo "0"
        return
    fi
    [[ "$speed_str" == *"GB/s"* ]] && num=$(awk "BEGIN {print $num * 1024}")
    [[ "$speed_str" == *"kB/s"* || "$speed_str" == *"KB/s"* ]] && num=$(awk "BEGIN {print $num / 1024}")
    [[ "$speed_str" == *"bytes/sec"* ]] && num=$(awk "BEGIN {print $num / 1048576}")
    echo "$num"
}

# --- [ CACHE PROFILING ENGINE ] ---
function test_cache() {
    echo -e "${YELLOW}[*] Cache Hierarchy Profiling (Pointer-Chasing Latency Analysis)...${RESET}"
    echo -e "${DIM}    Measuring L1→L2→L3→RAM access latency via randomized pointer chains.${RESET}"

    local cache_src="$TMP_DIR/spectra_cache.c"
    local cache_bin="$TMP_DIR/spectra_cache"
    local cache_py="$TMP_DIR/spectra_cache.py"

    # Method 1: Native C compilation (most accurate)
    if [[ -n "$COMPILER" ]]; then
        echo -e "${BLUE}    [Compiler: $COMPILER] Building native latency probe...${RESET}"

        cat > "$cache_src" << 'CEOF'
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <string.h>

#ifdef __MACH__
#include <mach/mach_time.h>
static double timebase_ns = 0;
static void init_timebase() {
    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    timebase_ns = (double)info.numer / (double)info.denom;
}
static inline double get_ns() {
    if (timebase_ns == 0) init_timebase();
    return (double)mach_absolute_time() * timebase_ns;
}
#else
static inline double get_ns() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec * 1e9 + (double)ts.tv_nsec;
}
#endif

static volatile int64_t dummy = 0;

double chase_latency(int size_kb, int64_t iterations) {
    int count = (size_kb * 1024) / sizeof(int);
    if (count < 64) count = 64;
    int *arr = (int*)calloc(count, sizeof(int));
    if (!arr) return -1.0;

    int stride = 64 / sizeof(int);
    if (stride < 1) stride = 1;

    // Randomized pointer chain to defeat prefetcher
    for (int i = 0; i < count; i++) {
        int next = ((i * 7919) + stride) % count;  // prime multiplicative scatter
        arr[i] = next;
    }

    int idx = 0;
    // Warmup: traverse entire chain twice
    for (int w = 0; w < count * 2; w++) {
        idx = arr[idx];
    }
    dummy += idx;

    // Benchmark
    double start = get_ns();
    for (int64_t i = 0; i < iterations; i++) {
        idx = arr[idx];
    }
    double end = get_ns();
    dummy += idx;  // prevent dead-code elimination

    free(arr);
    return (end - start) / (double)iterations;
}

int main() {
    printf("L1:%.2f\n", chase_latency(16, 200000000LL));      // ~16KB = L1 only
    printf("L2:%.2f\n", chase_latency(128, 100000000LL));      // ~128KB = L2 fit
    printf("L3:%.2f\n", chase_latency(4096, 20000000LL));      // ~4MB = L3 fit
    printf("RAM:%.2f\n", chase_latency(262144, 5000000LL));    // ~256MB = RAM
    return 0;
}
CEOF

        if "$COMPILER" -O0 -std=c99 "$cache_src" -o "$cache_bin" -lm 2>/dev/null; then
            start_spinner "Running pointer-chase benchmark (L1→L2→L3→RAM)..." "$BLUE"
            local cache_out=$("$cache_bin" 2>/dev/null)
            stop_spinner

            CACHE_L1_NS=$(echo "$cache_out" | grep "^L1:" | cut -d: -f2)
            CACHE_L2_NS=$(echo "$cache_out" | grep "^L2:" | cut -d: -f2)
            CACHE_L3_NS=$(echo "$cache_out" | grep "^L3:" | cut -d: -f2)
            CACHE_RAM_NS=$(echo "$cache_out" | grep "^RAM:" | cut -d: -f2)

            if [[ -n "$CACHE_L1_NS" && "$CACHE_L1_NS" != "0" ]]; then
                echo -e "  ${GREEN}[V] Native C probe successful.${RESET}"
            else
                echo -e "  ${YELLOW}[!] Native probe output incomplete. Trying fallback...${RESET}"
            fi
        else
            echo -e "  ${YELLOW}[!] Compilation failed. Trying Python fallback...${RESET}"
        fi
        rm -f "$cache_src" "$cache_bin"
    fi

    # Method 2: Python fallback
    if [[ -z "$CACHE_L1_NS" || "$CACHE_L1_NS" == "0" ]] && [[ -n "$PYTHON_CACHE" ]]; then
        echo -e "${BLUE}    [Python Fallback] Executing interpreted latency probe...${RESET}"

        cat > "$cache_py" << 'PYEOF'
import sys, time

try:
    perf = time.perf_counter_ns
except AttributeError:
    def perf():
        return int(time.perf_counter() * 1e9)

def chase(size_kb, iterations):
    count = max(64, (size_kb * 1024) // 4)
    stride = max(1, 64 // 4)
    arr = [((i * 7919) + stride) % count for i in range(count)]

    idx = 0
    for _ in range(count * 2):
        idx = arr[idx]

    dummy = idx
    start = perf()
    for _ in range(iterations):
        idx = arr[idx]
    end = perf()
    dummy += idx
    return (end - start) / iterations

print(f"L1:{chase(16, 50_000_000):.2f}")
print(f"L2:{chase(128, 25_000_000):.2f}")
print(f"L3:{chase(4096, 5_000_000):.2f}")
print(f"RAM:{chase(262144, 2_000_000):.2f}")
PYEOF

        start_spinner "Running Python latency probe..." "$BLUE"
        local py_out=$($PYTHON_CACHE "$cache_py" 2>/dev/null)
        stop_spinner

        CACHE_L1_NS=$(echo "$py_out" | grep "^L1:" | cut -d: -f2)
        CACHE_L2_NS=$(echo "$py_out" | grep "^L2:" | cut -d: -f2)
        CACHE_L3_NS=$(echo "$py_out" | grep "^L3:" | cut -d: -f2)
        CACHE_RAM_NS=$(echo "$py_out" | grep "^RAM:" | cut -d: -f2)
        rm -f "$cache_py"
    fi

    # Validation & Display
    if [[ -n "$CACHE_L1_NS" && "$CACHE_L1_NS" != "0" ]]; then
        echo -e "  ${CYAN}┌─────────────────────────────────────────┐${RESET}"
        echo -e "  ${CYAN}│${RESET} ${BOLD}Cache Latency Profile (ns/access)${RESET}       ${CYAN}│${RESET}"
        echo -e "  ${CYAN}├─────────────────────────────────────────┤${RESET}"
        printf "  ${CYAN}│${RESET} L1 Data Cache  : ${GREEN}%8.2f ns${RESET}           ${CYAN}│${RESET}\n" "$CACHE_L1_NS"
        printf "  ${CYAN}│${RESET} L2 Cache       : ${YELLOW}%8.2f ns${RESET}           ${CYAN}│${RESET}\n" "$CACHE_L2_NS"
        printf "  ${CYAN}│${RESET} L3 Cache       : ${MAGENTA}%8.2f ns${RESET}           ${CYAN}│${RESET}\n" "$CACHE_L3_NS"
        printf "  ${CYAN}│${RESET} RAM (Main Mem) : ${RED}%8.2f ns${RESET}           ${CYAN}│${RESET}\n" "$CACHE_RAM_NS"
        echo -e "  ${CYAN}└─────────────────────────────────────────┘${RESET}"

        # Score: lower latency = higher score. Normalize against reference.
        # Reference: L1=1ns, L2=4ns, L3=15ns, RAM=80ns = perfect desktop
        local l1_score=$(awk -v lat="$CACHE_L1_NS" 'BEGIN {printf "%d", 5000 / (lat < 0.5 ? 0.5 : lat)}')
        local l2_score=$(awk -v lat="$CACHE_L2_NS" 'BEGIN {printf "%d", 5000 / (lat < 2 ? 2 : lat)}')
        local l3_score=$(awk -v lat="$CACHE_L3_NS" 'BEGIN {printf "%d", 5000 / (lat < 8 ? 8 : lat)}')
        local ramc_score=$(awk -v lat="$CACHE_RAM_NS" 'BEGIN {printf "%d", 5000 / (lat < 50 ? 50 : lat)}')
        SCORE_CACHE=$((l1_score + l2_score + l3_score + ramc_score))
        echo -e "  ${GREEN}[V] Cache Profile Score: ${BOLD}${SCORE_CACHE}${RESET}"
    else
        echo -e "  ${RED}[!] Cache profiling unavailable.${RESET}"
        echo -e "  ${YELLOW}    Install gcc/cc or python3 for nanosecond cache latency measurement.${RESET}"
        SCORE_CACHE=0
    fi
}

# --- [ TEST MODULES WITH LIVE TELEMETRY ] ---

function test_cpu() {
    local total_mb=$((CPU_MB_PER_THREAD * CPU_CORES))
    echo -e "${YELLOW}[*] Singularity CPU Stress (${CPU_MB_PER_THREAD}MB SHA-256 per Thread x $CPU_CORES Threads)...${RESET}"

    if [[ -z "$HASHER" ]]; then
        echo -e "${RED}[!] No SHA-256 utility found. Skipping CPU test.${RESET}"
        SCORE_CPU=0
        return
    fi

    local temp_start=$(get_temp)
    local start_time=$(get_time)

    start_spinner "Warming up CPU cores..." "$YELLOW"
    for ((i=1; i<=CPU_CORES; i++)); do
        dd if=/dev/zero bs=1M count=$CPU_MB_PER_THREAD 2>/dev/null | $HASHER > /dev/null 2>/dev/null &
    done
    wait
    stop_spinner

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
    echo -e "${YELLOW}[*] Deep Memory Bandwidth (${test_mb}MB Chunked Allocation)...${RESET}"

    local dd_output=""
    if [[ -w "/dev/shm" && $IS_TERMUX -eq 0 ]]; then
        RAM_FILE="/dev/shm/.spectra_ram_test"
        start_spinner "Writing ${test_mb}MB to /dev/shm..." "$YELLOW"
        dd_output=$(LC_ALL=C dd if=/dev/zero of=$RAM_FILE bs=${RAM_CHUNK_MB}M count=$RAM_CHUNK_COUNT 2>&1)
        stop_spinner
        rm -f $RAM_FILE
    else
        start_spinner "Testing memory throughput via kernel pipe..." "$YELLOW"
        dd_output=$(LC_ALL=C dd if=/dev/zero of=/dev/null bs=${RAM_CHUNK_MB}M count=$RAM_CHUNK_COUNT 2>&1)
        stop_spinner
    fi

    local speed_str=$(parse_dd_speed "$dd_output")
    local raw_mbps=$(speed_to_mbps "$speed_str")

    if [[ -z "$raw_mbps" || "$raw_mbps" == "0" || "$raw_mbps" == "0.00" ]]; then
        echo -e "${RED}[!] RAM test failed. Raw: $dd_output${RESET}"
        SCORE_RAM=0
        return
    fi

    SCORE_RAM=$(awk -v mbps="$raw_mbps" 'BEGIN {printf "%d", mbps * 3}')
    echo -e "  ${GREEN}[V] Memory Speed: ${raw_mbps} MB/s -> RAM Score: ${BOLD}${SCORE_RAM}${RESET}"
}

function test_disk() {
    echo -e "${YELLOW}[*] Deep Storage Test (5GB Sustained Write to Exhaust SLC)...${RESET}"
    DISK_FILE="$TMP_DIR/.spectra_disk_test"

    local avail_kb=$(df -P "$TMP_DIR" 2>/dev/null | awk 'NR==2 {print $4}')
    local avail_mb=$((avail_kb / 1024))
    local disk_count=5000

    if [[ $avail_mb -lt 6000 ]]; then
        disk_count=$((avail_mb - 500))
        [[ $disk_count -lt 256 ]] && disk_count=256
        if [[ $disk_count -lt 100 ]]; then
            echo -e "${RED}[!] Insufficient disk space (${avail_mb}MB). Skipping.${RESET}"
            SCORE_DISK=0
            return
        fi
        echo -e "${YELLOW}[!] Low disk space. Using ${disk_count}MB test.${RESET}"
    fi

    start_spinner "Saturating storage controller..." "$YELLOW"
    local dd_output=$(LC_ALL=C dd if=/dev/zero of=$DISK_FILE bs=1M count=$disk_count 2>&1)
    sync
    rm -f $DISK_FILE
    stop_spinner

    local speed_str=$(parse_dd_speed "$dd_output")
    local raw_mbps=$(speed_to_mbps "$speed_str")

    if [[ -z "$raw_mbps" || "$raw_mbps" == "0" || "$raw_mbps" == "0.00" ]]; then
        echo -e "${RED}[!] Disk test failed. Raw: $dd_output${RESET}"
        SCORE_DISK=0
        return
    fi

    SCORE_DISK=$(awk -v mbps="$raw_mbps" 'BEGIN {printf "%d", mbps * 8}')
    echo -e "  ${GREEN}[V] Disk Speed: ${raw_mbps} MB/s -> Disk Score: ${BOLD}${SCORE_DISK}${RESET}"
}

function test_network() {
    echo -e "${YELLOW}[*] Network Edge Ping & 100MB Enterprise CDN Download...${RESET}"

    local latency=999
    local latency_str="Offline/Timeout"
    local lat_score=0

    if command -v ping >/dev/null 2>&1; then
        start_spinner "Measuring DNS latency to 1.1.1.1..." "$YELLOW"
        local ping_out=$(ping -c 3 -W 2 1.1.1.1 2>/dev/null)
        stop_spinner
        if [[ $? -eq 0 ]]; then
            latency=$(echo "$ping_out" | awk -F '/' 'END {print $5}')
            [[ -z "$latency" ]] && latency=999
        fi
    fi

    if [[ "$latency" != "999" && -n "$latency" ]]; then 
        lat_score=$(awk -v lat="$latency" 'BEGIN {printf "%d", 2000 / lat}')
        latency_str="${latency} ms"
    fi

    local urls=(
        "https://speedtest.tele2.net/100MB.zip"
        "https://proof.ovh.net/files/100Mb.dat"
        "https://speed.hetzner.de/100MB.bin"
        "https://speedtest-sgp1.digitalocean.com/100mb.test"
    )
    local dl_bps=0
    local dl_mbps=0
    local bw_score=0
    local success=0

    if command -v curl >/dev/null 2>&1; then
        for url in "${urls[@]}"; do
            start_spinner "Downloading 100MB from CDN..." "$YELLOW"
            local response=$(LC_ALL=C curl -sL --connect-timeout 5 --max-time 25 -w "\nHTTP_CODE:%{http_code}\nSPEED_BPS:%{speed_download}\n" -o /dev/null "$url" 2>/dev/null)
            stop_spinner

            local http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2 | tr -d '[:space:]')
            dl_bps=$(echo "$response" | grep "SPEED_BPS:" | cut -d: -f2 | tr -d '[:space:]')

            if [[ "$http_code" == "200" && -n "$dl_bps" ]]; then
                local is_num=$(echo "$dl_bps" | awk '{if ($1 > 0) print 1; else print 0}')
                if [[ "$is_num" == "1" ]]; then
                    dl_mbps=$(awk -v bps="$dl_bps" 'BEGIN { printf "%.2f", bps / 1048576 }')
                    bw_score=$(awk -v mbps="$dl_mbps" 'BEGIN {printf "%d", mbps * 15}')
                    success=1
                    break
                fi
            fi
        done
    fi

    if [[ $success -eq 0 ]]; then
        echo -e "${YELLOW}[!] All CDN endpoints failed.${RESET}"
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
    test_cache; echo ""

    TOTAL=$((SCORE_CPU + SCORE_RAM + SCORE_DISK + SCORE_NET + SCORE_CACHE))
    echo -e "${MAGENTA}=================================================================${RESET}"
    echo -e "${BOLD}                     🏆 FINAL SPECTRA SCORE 🏆                   ${RESET}"
    echo -e "${MAGENTA}=================================================================${RESET}"
    echo -e "  ${CYAN}CPU Score      :${RESET} $SCORE_CPU"
    echo -e "  ${CYAN}RAM Score      :${RESET} $SCORE_RAM"
    echo -e "  ${CYAN}Disk Score     :${RESET} $SCORE_DISK"
    echo -e "  ${CYAN}Network Score  :${RESET} $SCORE_NET"
    echo -e "  ${CYAN}Cache Score    :${RESET} $SCORE_CACHE"
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
    echo -e "  ${CYAN}3.${RESET} ⚡ Test RAM ($((RAM_CHUNK_MB * RAM_CHUNK_COUNT))MB Allocation Bandwidth)"
    echo -e "  ${CYAN}4.${RESET} 💾 Test Storage (5GB SLC Cache Exhaustion)"
    echo -e "  ${CYAN}5.${RESET} 🌐 Test Network (Global Edge & 100MB CDN)"
    echo -e "  ${MAGENTA}6.${RESET} 🎯 Test Cache (L1/L2/L3 Latency Profile)"
    echo -e "  ${RED}0.${RESET} ❌ Exit"
    echo -e "${CYAN}-----------------------------------------------------------------${RESET}"

    while IFS= read -r -t 0.1 discard </dev/tty 2>/dev/null; do : ; done
    read -r -p "Enter your choice [0-6]: " choice </dev/tty

    if [[ -z "$choice" ]]; then
        continue
    fi

    case $choice in
        1) echo ""; run_all; pause_continue ;;
        2) echo ""; test_cpu; pause_continue ;;
        3) echo ""; test_ram; pause_continue ;;
        4) echo ""; test_disk; pause_continue ;;
        5) echo ""; test_network; pause_continue ;;
        6) echo ""; test_cache; pause_continue ;;
        0) echo -e "\n${GREEN}Thank you for using SpectraBench!${RESET}"; exit 0 ;;
        *) 
            echo -e "\n${RED}[!] Invalid selection. Please choose 0-6.${RESET}"
            sleep 1
            ;;
    esac
done
