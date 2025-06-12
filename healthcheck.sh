#!/bin/bash

# Docker health check script for MIB Web UI
# This script performs comprehensive health checks for the application

set -e

# Configuration
HEALTH_CHECK_URL="http://localhost:3000/api/health"
TIMEOUT=10
RETRIES=3
LOG_FILE="/tmp/healthcheck.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    log "${RED}ERROR: $1${NC}"
    exit 1
}

# Success message
success() {
    log "${GREEN}SUCCESS: $1${NC}"
}

# Warning message
warning() {
    log "${YELLOW}WARNING: $1${NC}"
}

# Check if curl is available
if ! command -v curl &> /dev/null; then
    error_exit "curl is not installed or not in PATH"
fi

# Function to check HTTP endpoint
check_http_endpoint() {
    local url="$1"
    local expected_status="$2"
    local description="$3"
    
    log "Checking $description at $url"
    
    for i in $(seq 1 $RETRIES); do
        if response=$(curl -s -w "HTTPSTATUS:%{http_code}" --max-time $TIMEOUT "$url" 2>/dev/null); then
            http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
            body=$(echo "$response" | sed -e 's/HTTPSTATUS:.*//g')
            
            if [ "$http_code" -eq "$expected_status" ]; then
                success "$description check passed (HTTP $http_code)"
                return 0
            else
                warning "$description returned HTTP $http_code (expected $expected_status)"
            fi
        else
            warning "Attempt $i/$RETRIES: Failed to connect to $description"
        fi
        
        if [ $i -lt $RETRIES ]; then
            sleep 2
        fi
    done
    
    error_exit "$description check failed after $RETRIES attempts"
}

# Function to check detailed health endpoint
check_detailed_health() {
    log "Performing detailed health check"
    
    if response=$(curl -s --max-time $TIMEOUT "${HEALTH_CHECK_URL}?detailed=true" 2>/dev/null); then
        # Parse JSON response (basic parsing without jq)
        status=$(echo "$response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        
        case "$status" in
            "healthy")
                success "Application is healthy"
                return 0
                ;;
            "degraded")
                warning "Application is degraded but functional"
                return 0
                ;;
            "unhealthy")
                error_exit "Application is unhealthy"
                ;;
            *)
                warning "Unknown health status: $status"
                ;;
        esac
    else
        error_exit "Failed to get detailed health status"
    fi
}

# Function to check process
check_process() {
    log "Checking if Node.js process is running"
    
    if pgrep -f "node" > /dev/null; then
        success "Node.js process is running"
    else
        error_exit "Node.js process is not running"
    fi
}

# Function to check memory usage
check_memory() {
    log "Checking memory usage"
    
    if command -v free &> /dev/null; then
        memory_usage=$(free | grep Mem | awk '{printf "%.2f", $3/$2 * 100.0}')
        memory_usage_int=${memory_usage%.*}
        
        if [ "$memory_usage_int" -gt 90 ]; then
            error_exit "Memory usage is critical: ${memory_usage}%"
        elif [ "$memory_usage_int" -gt 75 ]; then
            warning "Memory usage is high: ${memory_usage}%"
        else
            success "Memory usage is normal: ${memory_usage}%"
        fi
    else
        warning "Cannot check memory usage (free command not available)"
    fi
}

# Function to check disk space
check_disk_space() {
    log "Checking disk space"
    
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    if [ "$disk_usage" -gt 90 ]; then
        error_exit "Disk usage is critical: ${disk_usage}%"
    elif [ "$disk_usage" -gt 80 ]; then
        warning "Disk usage is high: ${disk_usage}%"
    else
        success "Disk usage is normal: ${disk_usage}%"
    fi
}

# Function to check network connectivity
check_network() {
    log "Checking network connectivity"
    
    if ping -c 1 8.8.8.8 &> /dev/null; then
        success "Network connectivity is working"
    else
        warning "Network connectivity check failed"
    fi
}

# Main health check function
main() {
    log "Starting comprehensive health check for MIB Web UI"
    log "================================================"
    
    # Basic checks
    check_process
    check_memory
    check_disk_space
    check_network
    
    # HTTP endpoint checks
    check_http_endpoint "http://localhost:3000" 200 "Main application"
    check_http_endpoint "$HEALTH_CHECK_URL" 200 "Health endpoint"
    
    # Detailed health check
    check_detailed_health
    
    log "================================================"
    success "All health checks passed successfully"
    
    # Cleanup old log files (keep last 10)
    if [ -f "$LOG_FILE" ]; then
        tail -n 1000 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
}

# Run health check with error handling
if main; then
    exit 0
else
    exit 1
fi