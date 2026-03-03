#!/bin/bash

################################################################################
# Server Performance Statistics Script
# Purpose: Analyze and display basic server performance metrics
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
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "OS Name: $PRETTY_NAME"
    else
        echo "OS Name: $(uname -s)"
    fi
    
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
    
    local cpu_count=$(nproc)
    echo "CPU Count: $cpu_count"
    echo ""
}

################################################################################
# REQUIREMENT: Total CPU Usage
################################################################################
show_cpu_usage() {
    print_section "CPU Usage"
    
    # Get CPU usage using top
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    
    if [ -z "$cpu_usage" ]; then
        # Fallback method if top doesn't work as expected
        cpu_usage=$(ps aux | awk '{sum+=$3} END {print sum}')
    fi
    
    # Display with color coding
    if (( $(echo "$cpu_usage > 80" | bc -l) )); then
        echo -e "Total CPU Usage: ${RED}${cpu_usage}%${NC}"
    elif (( $(echo "$cpu_usage > 50" | bc -l) )); then
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
    
    # Using free command for memory statistics
    local mem_total=$(free -b | grep Mem | awk '{print $2}')
    local mem_used=$(free -b | grep Mem | awk '{print $3}')
    local mem_free=$(free -b | grep Mem | awk '{print $4}')
    
    # Convert to human-readable format
    local mem_total_gb=$(echo "scale=2; $mem_total / 1024 / 1024 / 1024" | bc)
    local mem_used_gb=$(echo "scale=2; $mem_used / 1024 / 1024 / 1024" | bc)
    local mem_free_gb=$(echo "scale=2; $mem_free / 1024 / 1024 / 1024" | bc)
    local mem_percent=$(echo "scale=2; $mem_used * 100 / $mem_total" | bc)
    
    echo "Total Memory: ${mem_total_gb} GB"
    
    # Color coding based on usage percentage
    if (( $(echo "$mem_percent > 80" | bc -l) )); then
        echo -e "Used Memory: ${RED}${mem_used_gb} GB (${mem_percent}%)${NC}"
    elif (( $(echo "$mem_percent > 60" | bc -l) )); then
        echo -e "Used Memory: ${YELLOW}${mem_used_gb} GB (${mem_percent}%)${NC}"
    else
        echo -e "Used Memory: ${GREEN}${mem_used_gb} GB (${mem_percent}%)${NC}"
    fi
    
    echo "Free Memory: ${mem_free_gb} GB"
    echo ""
}

################################################################################
# REQUIREMENT: Total Disk Usage
################################################################################
show_disk_usage() {
    print_section "Disk Usage"
    
    df -h | head -1
    df -h | tail -n +2 | while read line; do
        local disk_usage=$(echo "$line" | awk '{print $(NF-1)}' | sed 's/%//')
        local filesystem=$(echo "$line" | awk '{print $1}')
        
        if (( $(echo "$disk_usage > 80" | bc -l) )); then
            echo -e "${RED}$(echo $line | awk '{printf "%-20s %8s %8s %8s %6s\n", $1, $2, $3, $4, $5}')${NC}"
        elif (( $(echo "$disk_usage > 60" | bc -l) )); then
            echo -e "${YELLOW}$(echo $line | awk '{printf "%-20s %8s %8s %8s %6s\n", $1, $2, $3, $4, $5}')${NC}"
        else
            echo "$(echo $line | awk '{printf "%-20s %8s %8s %8s %6s\n", $1, $2, $3, $4, $5}')"
        fi
    done
    echo ""
}

################################################################################
# REQUIREMENT: Top 5 Processes by CPU Usage
################################################################################
show_top_cpu_processes() {
    print_section "Top 5 Processes by CPU Usage"
    
    ps aux --sort=-%cpu | head -6 | tail -n +2 | awk '{printf "%-8s %6s%% %s\n", $1, $3, $11}' | while read line; do
        local cpu=$(echo "$line" | awk '{print $2}' | sed 's/%//')
        if (( $(echo "$cpu > 50" | bc -l) )); then
            echo -e "${RED}${line}${NC}"
        elif (( $(echo "$cpu > 20" | bc -l) )); then
            echo -e "${YELLOW}${line}${NC}"
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
    
    ps aux --sort=-%mem | head -6 | tail -n +2 | awk '{printf "%-8s %6s%% %s\n", $1, $4, $11}' | while read line; do
        local mem=$(echo "$line" | awk '{print $2}' | sed 's/%//')
        if (( $(echo "$mem > 50" | bc -l) )); then
            echo -e "${RED}${line}${NC}"
        elif (( $(echo "$mem > 10" | bc -l) )); then
            echo -e "${YELLOW}${line}${NC}"
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
        who | awk '{printf "%-12s %-15s %s\n", $1, $3, $4}'
        echo ""
    fi
}

################################################################################
# STRETCH GOAL: Failed Login Attempts
################################################################################
show_failed_logins() {
    print_section "Failed Login Attempts (Last 10)"
    
    if [ -f /var/log/auth.log ]; then
        local failed_count=$(grep "Failed password" /var/log/auth.log 2>/dev/null | wc -l)
        echo "Total failed login attempts: $failed_count"
        echo ""
        echo "Recent failed attempts:"
        grep "Failed password" /var/log/auth.log 2>/dev/null | tail -10 | awk '{print $1, $2, $3, $11}' | head -5 || echo "No recent failed attempts"
    else
        echo "Auth log file not accessible"
    fi
    echo ""
}

################################################################################
# STRETCH GOAL: Network Information
################################################################################
show_network_info() {
    print_section "Network Information"
    
    if command -v ip &> /dev/null; then
        ip addr show | grep -E "inet |link/ether" | awk '{
            if ($1 == "inet") {
                gsub(/\/.*/,"",$2)
                print "IP Address: " $2
            } else if ($1 == "link/ether") {
                print "MAC Address: " $2
            }
        }' | sort -u
    else
        ifconfig | grep -E "inet |HWaddr" | head -5
    fi
    echo ""
}

################################################################################
# STRETCH GOAL: Process Count
################################################################################
show_process_info() {
    print_section "Process Information"
    
    local total_proc=$(ps aux | wc -l)
    local running_proc=$(ps aux | grep -E "S|Ss" | wc -l)
    local zombie_proc=$(ps aux | grep -E "Z" | wc -l)
    
    echo "Total Processes: $((total_proc - 1))"
    echo "Running Processes: $running_proc"
    if [ "$zombie_proc" -gt 1 ]; then
        echo -e "Zombie Processes: ${RED}$((zombie_proc - 1))${NC}"
    else
        echo "Zombie Processes: 0"
    fi
    echo ""
}

################################################################################
# STRETCH GOAL: Swap Usage
################################################################################
show_swap_usage() {
    print_section "Swap Usage"
    
    local swap_total=$(free -b | grep Swap | awk '{print $2}')
    local swap_used=$(free -b | grep Swap | awk '{print $3}')
    
    if [ "$swap_total" -gt 0 ]; then
        local swap_total_gb=$(echo "scale=2; $swap_total / 1024 / 1024 / 1024" | bc)
        local swap_used_gb=$(echo "scale=2; $swap_used / 1024 / 1024 / 1024" | bc)
        local swap_percent=$(echo "scale=2; $swap_used * 100 / $swap_total" | bc)
        
        echo "Total Swap: ${swap_total_gb} GB"
        if (( $(echo "$swap_percent > 50" | bc -l) )); then
            echo -e "Used Swap: ${RED}${swap_used_gb} GB (${swap_percent}%)${NC}"
        else
            echo "Used Swap: ${swap_used_gb} GB (${swap_percent}%)"
        fi
    else
        echo "No swap configured"
    fi
    echo ""
}

################################################################################
# STRETCH GOAL: Disk I/O Statistics
################################################################################
show_disk_io() {
    print_section "Disk I/O Statistics"
    
    if command -v iostat &> /dev/null; then
        iostat -x 1 2 | tail -n +4 | head -5 | awk '{printf "%-10s %6s%% %8s\n", $1, $4, $8}'
    else
        echo "iostat not available. Install sysstat package for more details."
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
    show_swap_usage
    
    if [ "$verbose" = true ]; then
        show_failed_logins
        show_network_info
        show_disk_io
    fi
    
    print_separator
    echo -e "${CYAN}Report generated on $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo ""
}

# Run main function
main "$@"
