#!/bin/bash

# MIB Platform 功能测试脚本
# 用于验证平台各项功能是否正常工作

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
API_BASE_URL="http://localhost:8080/api/v1"
FRONTEND_URL="http://localhost:3000"
GRAFANA_URL="http://localhost:3001"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查服务是否运行
check_service() {
    local service_name=$1
    local url=$2
    local expected_status=${3:-200}
    
    log_info "检查 $service_name 服务..."
    
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "$expected_status"; then
        log_success "$service_name 服务正常运行"
        return 0
    else
        log_error "$service_name 服务不可用"
        return 1
    fi
}

# 测试 API 端点
test_api_endpoint() {
    local endpoint=$1
    local method=${2:-GET}
    local expected_status=${3:-200}
    local data=${4:-""}
    
    log_info "测试 API: $method $endpoint"
    
    local curl_cmd="curl -s -o /dev/null -w '%{http_code}' -X $method"
    
    if [ "$method" = "POST" ] && [ -n "$data" ]; then
        curl_cmd="$curl_cmd -H 'Content-Type: application/json' -d '$data'"
    fi
    
    local status_code=$(eval "$curl_cmd '$API_BASE_URL$endpoint'")
    
    if [ "$status_code" = "$expected_status" ]; then
        log_success "API 测试通过: $endpoint"
        return 0
    else
        log_error "API 测试失败: $endpoint (状态码: $status_code, 期望: $expected_status)"
        return 1
    fi
}

# 测试文件上传
test_file_upload() {
    log_info "测试 MIB 文件上传功能..."
    
    # 创建测试 MIB 文件
    cat > /tmp/test.mib << 'EOF'
TEST-MIB DEFINITIONS ::= BEGIN

IMPORTS
    MODULE-IDENTITY, OBJECT-TYPE, Integer32
        FROM SNMPv2-SMI;

testMIB MODULE-IDENTITY
    LAST-UPDATED "202412010000Z"
    ORGANIZATION "Test Organization"
    CONTACT-INFO "test@example.com"
    DESCRIPTION "Test MIB for platform testing"
    ::= { 1 3 6 1 4 1 99999 }

testObject OBJECT-TYPE
    SYNTAX Integer32
    MAX-ACCESS read-only
    STATUS current
    DESCRIPTION "Test object"
    ::= { testMIB 1 }

END
EOF
    
    # 上传文件
    local response=$(curl -s -X POST \
        -F "file=@/tmp/test.mib" \
        "$API_BASE_URL/mibs/upload")
    
    if echo "$response" | grep -q "success"; then
        log_success "MIB 文件上传测试通过"
        rm -f /tmp/test.mib
        return 0
    else
        log_error "MIB 文件上传测试失败"
        rm -f /tmp/test.mib
        return 1
    fi
}

# 测试配置生成
test_config_generation() {
    log_info "测试配置生成功能..."
    
    local config_data='{
        "config_type": "snmp_exporter",
        "config_name": "test-config",
        "device_info": {
            "ip": "192.168.1.1",
            "community": "public",
            "version": "v2c"
        },
        "selected_oids": ["1.3.6.1.2.1.1.1.0", "1.3.6.1.2.1.1.3.0"]
    }'
    
    local response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$config_data" \
        "$API_BASE_URL/configs/generate")
    
    if echo "$response" | grep -q "success"; then
        log_success "配置生成测试通过"
        return 0
    else
        log_error "配置生成测试失败"
        return 1
    fi
}

# 测试设备管理
test_device_management() {
    log_info "测试设备管理功能..."
    
    local device_data='{
        "name": "Test Device",
        "ip_address": "192.168.1.100",
        "device_type": "router",
        "snmp_version": "v2c",
        "community": "public"
    }'
    
    # 创建设备
    local response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$device_data" \
        "$API_BASE_URL/devices")
    
    if echo "$response" | grep -q "Test Device"; then
        log_success "设备创建测试通过"
        
        # 获取设备列表
        local devices=$(curl -s "$API_BASE_URL/devices")
        if echo "$devices" | grep -q "Test Device"; then
            log_success "设备列表获取测试通过"
            return 0
        else
            log_error "设备列表获取测试失败"
            return 1
        fi
    else
        log_error "设备创建测试失败"
        return 1
    fi
}

# 测试 SNMP 操作
test_snmp_operations() {
    log_info "测试 SNMP 操作功能..."
    
    local snmp_data='{
        "target": "127.0.0.1",
        "community": "public",
        "version": "v2c",
        "oid": "1.3.6.1.2.1.1.1.0"
    }'
    
    # 测试 SNMP GET (可能失败，因为本地没有 SNMP 代理)
    local response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$snmp_data" \
        "$API_BASE_URL/snmp/get")
    
    # 检查响应格式而不是成功与否
    if echo "$response" | grep -q -E "(error|result|timeout)"; then
        log_success "SNMP 操作接口测试通过"
        return 0
    else
        log_error "SNMP 操作接口测试失败"
        return 1
    fi
}

# 主测试函数
main() {
    echo "=========================================="
    echo "MIB Platform 功能测试"
    echo "=========================================="
    
    local failed_tests=0
    local total_tests=0
    
    # 基础服务检查
    echo -e "\n${BLUE}1. 基础服务检查${NC}"
    
    ((total_tests++))
    if ! check_service "前端服务" "$FRONTEND_URL"; then
        ((failed_tests++))
    fi
    
    ((total_tests++))
    if ! check_service "后端健康检查" "$API_BASE_URL/../health"; then
        ((failed_tests++))
    fi
    
    ((total_tests++))
    if ! check_service "Grafana" "$GRAFANA_URL"; then
        ((failed_tests++))
    fi
    
    # API 端点测试
    echo -e "\n${BLUE}2. API 端点测试${NC}"
    
    local api_endpoints=(
        "/mibs"
        "/devices"
        "/configs"
        "/snmp/test"
    )
    
    for endpoint in "${api_endpoints[@]}"; do
        ((total_tests++))
        if ! test_api_endpoint "$endpoint"; then
            ((failed_tests++))
        fi
    done
    
    # 功能测试
    echo -e "\n${BLUE}3. 功能测试${NC}"
    
    ((total_tests++))
    if ! test_file_upload; then
        ((failed_tests++))
    fi
    
    ((total_tests++))
    if ! test_config_generation; then
        ((failed_tests++))
    fi
    
    ((total_tests++))
    if ! test_device_management; then
        ((failed_tests++))
    fi
    
    ((total_tests++))
    if ! test_snmp_operations; then
        ((failed_tests++))
    fi
    
    # 测试结果汇总
    echo -e "\n=========================================="
    echo "测试结果汇总"
    echo "=========================================="
    
    local passed_tests=$((total_tests - failed_tests))
    
    echo "总测试数: $total_tests"
    echo -e "通过测试: ${GREEN}$passed_tests${NC}"
    echo -e "失败测试: ${RED}$failed_tests${NC}"
    
    if [ $failed_tests -eq 0 ]; then
        echo -e "\n${GREEN}🎉 所有测试通过！平台功能正常。${NC}"
        exit 0
    else
        echo -e "\n${RED}❌ 有 $failed_tests 个测试失败，请检查相关功能。${NC}"
        exit 1
    fi
}

# 帮助信息
show_help() {
    echo "MIB Platform 功能测试脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示帮助信息"
    echo "  -u, --url      指定 API 基础 URL (默认: http://localhost:8080/api/v1)"
    echo "  -f, --frontend 指定前端 URL (默认: http://localhost:3000)"
    echo "  -g, --grafana  指定 Grafana URL (默认: http://localhost:3001)"
    echo ""
    echo "示例:"
    echo "  $0                                    # 使用默认配置运行测试"
    echo "  $0 -u http://192.168.1.100:8080/api/v1  # 指定远程服务器"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -u|--url)
            API_BASE_URL="$2"
            shift 2
            ;;
        -f|--frontend)
            FRONTEND_URL="$2"
            shift 2
            ;;
        -g|--grafana)
            GRAFANA_URL="$2"
            shift 2
            ;;
        *)
            log_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 运行主测试
main