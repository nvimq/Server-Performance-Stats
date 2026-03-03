#!/bin/bash

################################################################################
# Server Performance Statistics Script (macOS Version)
# Purpose: Analyze and display basic server performance metrics on macOS
# Author: Performance Analysis Tool
# Description: Displays CPU, Memory, Disk usage, and top processes
################################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print header with colors
print_header() {
    echo -e "${CYAN}================================================================================${NC}"
    echo -e "${CYAN}                    SERVER PERFORMANCE STATISTICS${NC}"
    echo -e "${CYAN}================================================================================${NC}"
    echo ""
}

# Print section headers
print_section() {
    echo -e "${BLUE}>>> $1${NC}"
}

# Print separator
print_separator() {
    echo -e "${CYAN}-------------------------------------------------------------------------------${NC}"
}

################################################################################
# STRETCH GOAL: OS Information and System Details
################################################################################
show_system_info() {
    print_section "System Information"
    
    local os_version=$(sw_vers -productVersion)
    local os_name=$(sw_vers -productName)
    
    echo "OS Name: $os_name"
    echo "OS Version: $os_version"
    echo "Hostname: $(hostname)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo ""
}

################################################################################
# STRETCH GOAL: Uptime
################################################################################
show_uptime() {
    print_section "System Uptime"
    
    # Get uptime in a readable format
    local uptime_seconds=$(sysctl -n kern.boottime | awk '{print $4}' | sed 's/,//')
    local current_time=$(date +%s)
    local uptime=$((current_time - uptime_seconds))
    
    local days=$((uptime / 86400))
    local hours=$(((uptime % 86400) / 3600))
    local minutes=$(((uptime % 3600) / 60))
    
    echo "Uptime: ${days}d ${hours}h ${minutes}m"
    
    # Alternative format using uptime command
    uptime
    echo ""
}

################################################################################
# STRETCH GOAL: Load Average
################################################################################
show_load_average() {
    print_section "Load Average"
    
    local load=$(uptime | awk -F'load average:' '{print $2}')
    echo "Load Average: $load"
    
    local cpu_count=$(sysctl -n hw.ncpu)
    echo "CPU Count: $cpu_count"
    echo ""
}

################################################################################
# REQUIREMENT: Total CPU Usage
################################################################################
show_cpu_usage() {
    print_section "CPU Usage"
    
    # Get CPU usage using top - macOS compatible
    local cpu_usage=$(top -l 1 | grep "CPU usage" | head -1 | awk '{print $3}' | sed 's/%//')
    
    if [ -z "$cpu_usage" ]; then
        # Fallback: use ps to calculate
        cpu_usage=$(ps aux | awk 'BEGIN {sum=0} {sum+=$3} END {print int(sum)}')
    fi
    
    # Display with color coding
    if (( $(echo "$cpu_usage > 80" | bc -l 2>/dev/null) )) || [ "$cpu_usage" -gt 80 ] 2>/dev/null; then
        echo -e "Total CPU Usage: ${RED}${cpu_usage}%${NC}"
    elif (( $(echo "$cpu_usage > 50" | bc -l 2>/dev/null) )) || [ "$cpu_usage" -gt 50 ] 2>/dev/null; then
        echo -e "Total CPU Usage: ${YELLOW}${cpu_usage}%${NC}"
    else
        echo -e "Total CPU Usage: ${GREEN}${cpu_usage}%${NC}"
    fi
    echo ""
}

################################################################################
# REQUIREMENT: Total Memory Usage
################################################################################
show_memory_usage() {
    print_section "Memory Usage"
    
    # Get memory statistics on macOS
    local mem_total=$(sysctl -n hw.memsize)
    
    # Get memory usage using vm_stat
    local vm_stat=$(vm_stat | grep -E "Pages free|Pages active|Pages inactive|Pages wired down")
    
    # Parse vm_stat output (each page is 4KB on most Macs)
    local pages_free=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
    local pages_active=$(vm_stat | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
    local pages_inactive=$(vm_stat | grep "Pages inactive" | awk '{print $3}' | sed 's/\.//')
    local pages_wired=$(vm_stat | grep "Pages wired down" | awk '{print $4}' | sed 's/\.//')
    local pages_compressed=$(vm_stat | grep "Pages occupied by compressor" | awk '{print $5}' | sed 's/\.//')
    
    if [ -z "$pages_compressed" ]; then
        pages_compressed=0
    fi
    
    # Page size in bytes (typically 4096)
    local page_size=4096
    
    # Calculate in bytes
    local mem_free=$((pages_free * page_size))
    local mem_active=$((pages_active * page_size))
    local mem_inactive=$((pages_inactive * page_size))
    local mem_wired=$((pages_wired * page_size))
    local mem_compressed=$((pages_compressed * page_size))
    
    # Used memory = active + wired + compressed
    local mem_used=$((mem_active + mem_wired + mem_compressed))
    
    # Convert to human-readable format (GB)
    local mem_total_gb=$(printf "%.2f" "$(echo "scale=2; $mem_total / 1024 / 1024 / 1024" | bc 2>/dev/null || echo 0)")
    local mem_used_gb=$(printf "%.2f" "$(echo "scale=2; $mem_used / 1024 / 1024 / 1024" | bc 2>/dev/null || echo 0)")
    local mem_free_gb=$(printf "%.2f" "$(echo "scale=2; $mem_free / 1024 / 1024 / 1024" | bc 2>/dev/null || echo 0)")
    
    # Calculate percentage
    if [ "$mem_total" -gt 0 ]; then
        local mem_percent=$(printf "%.1f" "$(echo "scale=1; $mem_used * 100 / $mem_total" | bc 2>/dev/null || echo 0)")
    else
        local mem_percent=0
    fi
    
    echo "Total Memory: ${mem_total_gb} GB"
    
    # Color coding based on usage percentage
    local percent_int=${mem_percent%.*}
    if [ "$percent_int" -gt 80 ] 2>/dev/null; then
        echo -e "Used Memory: ${RED}${mem_used_gb} GB (${mem_percent}%)${NC}"
    elif [ "$percent_int" -gt 60 ] 2>/dev/null; then
        echo -e "Used Memory: ${YELLOW}${mem_used_gb} GB (${mem_percent}%)${NC}"
    else
        echo -e "Used Memory: ${GREEN}${mem_used_gb} GB (${mem_percent}%)${NC}"
    fi
    
    echo "Free Memory: ${mem_free_gb} GB"
    echo "  - Active: $(printf '%.2f' "$(echo "scale=2; $mem_active / 1024 / 1024 / 1024" | bc 2>/dev/null || echo 0)") GB"
    echo "  - Inactive: $(printf '%.2f' "$(echo "scale=2; $mem_inactive / 1024 / 1024 / 1024" | bc 2>/dev/null || echo 0)") GB"
    echo "  - Wired: $(printf '%.2f' "$(echo "scale=2; $mem_wired / 1024 / 1024 / 1024" | bc 2>/dev/null || echo 0)") GB"
    echo "  - Compressed: $(printf '%.2f' "$(echo "scale=2; $mem_compressed / 1024 / 1024 / 1024" | bc 2>/dev/null || echo 0)") GB"
    echo ""
}

################################################################################
# REQUIREMENT: Total Disk Usage
################################################################################
show_disk_usage() {
    print_section "Disk Usage"
    
    df -h / | tail -1 | awk '{
        filesystem = $1
        total = $2
        used = $3
        available = $4
        percent = $5
        
        # Extract percentage number
        percent_num = substr(percent, 1, length(percent)-1)
        
        printf "%-25s %8s %8s %8s %6s\n", filesystem, total, used, available, percent
    }'
    
    echo ""
    echo "All Mounted Volumes:"
    df -h | tail -n +2 | while read line; do
        local disk_usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
        
        if [ -z "$disk_usage" ]; then
            continue
        fi
        
        if [ "$disk_usage" -gt 80 ] 2>/dev/null; then
            echo -e "${RED}$(echo "$line" | awk '{printf "%-25s %8s %8s %8s %6s\n", $1, $2, $3, $4, $5}')${NC}"
        elif [ "$disk_usage" -gt 60 ] 2>/dev/null; then
            echo -e "${YELLOW}$(echo "$line" | awk '{printf "%-25s %8s %8s %8s %6s\n", $1, $2, $3, $4, $5}')${NC}"
        else
            echo "$(echo "$line" | awk '{printf "%-25s %8s %8s %8s %6s\n", $1, $2, $3, $4, $5}')"
        fi
    done
    echo ""
}

################################################################################
# REQUIREMENT: Top 5 Processes by CPU Usage
################################################################################
show_top_cpu_processes() {
    print_section "Top 5 Processes by CPU Usage"
    
    ps aux -m | head -1
    ps aux -m --sort=-%cpu | head -6 | tail -n +2 | while read line; do
        local cpu=$(echo "$line" | awk '{print $3}')
        
        if (( $(echo "$cpu > 50" | bc -l 2>/dev/null) )) || [ "${cpu%.*}" -gt 50 ] 2>/dev/null; then
            echo -e "${RED}$line${NC}"
        elif (( $(echo "$cpu > 20" | bc -l 2>/dev/null) )) || [ "${cpu%.*}" -gt 20 ] 2>/dev/null; then
            echo -e "${YELLOW}$line${NC}"
        else
            echo "$line"
        fi
    done
    echo ""
}

################################################################################
# REQUIREMENT: Top 5 Processes by Memory Usage
################################################################################
show_top_memory_processes() {
    print_section "Top 5 Processes by Memory Usage"
    
    ps aux -m | head -1
    ps aux -m --sort=-%mem | head -6 | tail -n +2 | while read line; do
        local mem=$(echo "$line" | awk '{print $4}')
        
        if (( $(echo "$mem > 50" | bc -l 2>/dev/null) )) || [ "${mem%.*}" -gt 50 ] 2>/dev/null; then
            echo -e "${RED}$line${NC}"
        elif (( $(echo "$mem > 10" | bc -l 2>/dev/null) )) || [ "${mem%.*}" -gt 10 ] 2>/dev/null; then
            echo -e "${YELLOW}$line${NC}"
        else
            echo "$line"
        fi
    done
    echo ""
}

################################################################################
# STRETCH GOAL: Logged In Users
################################################################################
show_logged_in_users() {
    print_section "Logged In Users"
    
    local user_count=$(who | wc -l)
    echo "Number of logged in users: $user_count"
    echo ""
    
    if [ "$user_count" -gt 0 ]; then
        who | awk '{printf "%-12s %-15s %s %s\n", $1, $3, $4, $5}'
        echo ""
    fi
}

################################################################################
# STRETCH GOAL: Process Information
################################################################################
show_process_info() {
    print_section "Process Information"
    
    local total_proc=$(ps aux | wc -l)
    
    echo "Total Processes: $((total_proc - 1))"
    echo ""
}

################################################################################
# STRETCH GOAL: Network Information
################################################################################
show_network_info() {
    print_section "Network Information"
    
    echo "Active Network Interfaces:"
    ifconfig | grep -E "^[a-z]|inet " | sed 's/^[ \t]*/  /'
    echo ""
}

################################################################################
# STRETCH GOAL: System Memory Pressure (macOS specific)
################################################################################
show_memory_pressure() {
    print_section "Memory Pressure"
    
    # Check if memory_pressure diagnostic is available
    if command -v memory_pressure &> /dev/null; then
        memory_pressure
    else
        echo "Use Activity Monitor for detailed memory pressure information"
    fi
    echo ""
}

################################################################################
# STRETCH GOAL: Battery Status (for MacBook)
################################################################################
show_battery_status() {
    print_section "Battery Status (MacBook)"
    
    if command -v pmset &> /dev/null; then
        local battery=$(pmset -g batt)
        
        if echo "$battery" | grep -q "No battery"; then
            echo "No battery detected (Desktop Mac or AC Only)"
        else
            echo "$battery" | head -1
            local percentage=$(echo "$battery" | grep "Internal" | awk '{print $3}' | sed 's/%//')
            local status=$(echo "$battery" | grep "Internal" | awk '{print $4}')
            
            echo "Status: $status"
            if [ "$percentage" -lt 20 ]; then
                echo -e "Battery Level: ${RED}${percentage}%${NC}"
            elif [ "$percentage" -lt 50 ]; then
                echo -e "Battery Level: ${YELLOW}${percentage}%${NC}"
            else
                echo -e "Battery Level: ${GREEN}${percentage}%${NC}"
            fi
        fi
    fi
    echo ""
}

################################################################################
# Main Execution
################################################################################
main() {
    # Check if script is run with -v or --verbose for extended output
    local verbose=false
    if [[ "$1" == "-v" ]] || [[ "$1" == "--verbose" ]]; then
        verbose=true
    fi
    
    print_header
    
    # Core Requirements
    show_system_info
    show_uptime
    show_load_average
    show_cpu_usage
    show_memory_usage
    show_disk_usage
    print_separator
    show_top_cpu_processes
    show_top_memory_processes
    print_separator
    
    # Stretch Goals
    show_logged_in_users
    show_process_info
    
    if [ "$verbose" = true ]; then
        show_network_info
        show_battery_status
        show_memory_pressure
    fi
    
    print_separator
    echo -e "${CYAN}Report generated on $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo ""
}

# Run main function
main "$@"
