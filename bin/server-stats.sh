#!/usr/bin/env bash
# =============================================================================
# server-stats.sh
# A script to report basic server performance statistics.
# Requirements:
#   - Bash >=4.0
#   - Linux (Ubuntu)
#   - Coreutils available (`ps`, `df`, `free`)
# Usage:
#   ./server-stats.sh
# =============================================================================

set -euo pipefail

# Compute total CPU usage over a 1-second interval
report_cpu() {
  read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
  prev_idle=$idle
  prev_total=$((user + nice + system + idle + iowait + irq + softirq + steal))

  sleep 1

  read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
  total=$((user + nice + system + idle + iowait + irq + softirq + steal))

  diff_idle=$((idle - prev_idle))
  diff_total=$((total - prev_total))
  diff_usage=$(( (1000 * (diff_total - diff_idle) / diff_total + 5) / 10 ))
  echo "Total CPU Usage: ${diff_usage}%"
}

# Report memory usage: Total, Used, Free, Percentage
report_memory() {
  # Read memory stats
  while read -r key value _; do
    case "$key" in
      MemTotal:) total=$value;;
      MemFree:) free=$value;;
      Buffers:) buffers=$value;;
      Cached:) cached=$value;;
    esac
  done < /proc/meminfo

  # Calculate used = total - free - buffers - cached
  used=$((total - free - buffers - cached))
  percent=$(awk "BEGIN {printf \"%.1f\", ${used}/${total}*100}")

  # Convert kB to human-readable MB/GB
  total_human=$(awk "BEGIN {printf \"%.2fMB\", ${total}/1024}")
  used_human=$(awk "BEGIN {printf \"%.2fMB\", ${used}/1024}")
  free_human=$(awk "BEGIN {printf \"%.2fMB\", ${free}/1024}")

  echo "Mem: ${total_human} total, ${used_human} used (${percent}%), ${free_human} free"
}

# Report disk usage across non-virtual filesystems
report_disk() {
  df -h --output=target,size,used,avail,pcent -x tmpfs -x devtmpfs | sed '1d' | \
    awk '{printf "%s: %s/%s (%s)\n", $1, $3, $2, $5}'
}

# Top 5 processes by CPU usage
report_top_cpu() {
  ps -eo pid,comm,pcpu --sort=-pcpu | head -n6 | sed '1d'
}

# Top 5 processes by memory usage
report_top_mem() {
  ps -eo pid,comm,pmem --sort=-pmem | head -n6 | sed '1d'
}

main() {
  echo "=== CPU Usage ==="
  report_cpu

  echo -e "\n=== Memory Usage ==="
  report_memory

  echo -e "\n=== Disk Usage ==="
  report_disk

  echo -e "\n=== Top 5 by CPU ==="
  printf "PID   COMMAND     %%CPU\n"
  report_top_cpu

  echo -e "\n=== Top 5 by MEM ==="
  printf "PID   COMMAND     %%MEM\n"
  report_top_mem
}

main "$@"