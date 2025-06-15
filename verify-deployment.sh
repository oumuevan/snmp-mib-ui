#!/bin/bash

# SNMP MIB Platform 部署验证脚本
# 用于验证部署是否成功和功能是否正常

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 计数器
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
    ((PASSED_TESTS++))
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
    ((FAILED_TESTS++))
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
    ((TOTAL_TESTS++))
}

# 检查服务是否运行
check_service() {
    local service_name=$1
    local url=$2
    local expected_status=${3:-200}
    
    log_step "检查 $service_name 服务"
    
    if command -v curl &> /dev/null; then
        local status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" || echo "000")
        if [ "$status_code" = "$expected_status" ]; then
            log_success "$service_name 服务正常运行 (HTTP $status_code)"
        else
            log_error "$service_name 服务异常 (HTTP $status_code)"
        fi
    else
        log_warning "curl 未安装，跳过 $service_name 检查"
    fi
}

# 检查端口是否开放
check_port() {
    local service_name=$1
    local host=$2
    local port=$3
    
    log_step "检查 $service_name 端口"
    
    if command -v nc &> /dev/null; then
        if nc -z "$host" "$port" 2>/dev/null; then
            log_success "$service_name 端口 $port 开放"
        else
            log_error "$service_name 端口 $port 未开放"
        fi
    elif command -v telnet &> /dev/null; then
        if timeout 3 telnet "$host" "$port" 2>/dev/null | grep -q "Connected"; then
            log_success "$service_name 端口 $port 开放"
        else
            log_error "$service_name 端口 $port 未开放"
        fi
    else
        log_warning "nc 和 telnet 都未安装，跳过端口检查"
    fi
}

# 检查 Docker 容器状态
check_docker_containers() {
    log_step "检查 Docker 容器状态"
    
    if command -v docker &> /dev/null; then
        local containers=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(snmp-mib|mibweb)" || true)
        if [ -n "$containers" ]; then
            log_success "Docker 容器运行正常"
            echo "$containers"
        else
            log_error "未找到运行中的 Docker 容器"
        fi
    else
        log_warning "Docker 未安装，跳过容器检查"
    fi
}

# 检查 Kubernetes Pod 状态
check_k8s_pods() {
    log_step "检查 Kubernetes Pod 状态"
    
    if command -v kubectl &> /dev/null; then
        local pods=$(kubectl get pods -n monitoring 2>/dev/null | grep snmp-mib || true)
        if [ -n "$pods" ]; then
            log_success "Kubernetes Pod 运行正常"
            echo "$pods"
        else
            log_warning "未找到 Kubernetes Pod 或集群未配置"
        fi
    else
        log_warning "kubectl 未安装，跳过 K8s 检查"
    fi
}

# 检查数据库连接
check_database() {
    log_step "检查数据库连接"
    
    # 检查 PostgreSQL
    if command -v docker &> /dev/null; then
        local postgres_container=$(docker ps --filter "name=postgres" --format "{{.Names}}" | head -1)
        if [ -n "$postgres_container" ]; then
            if docker exec "$postgres_container" pg_isready -U postgres &>/dev/null; then
                log_success "PostgreSQL 数据库连接正常"
            else
                log_error "PostgreSQL 数据库连接失败"
            fi
        else
            log_warning "未找到 PostgreSQL 容器"
        fi
    fi
    
    # 检查 Redis
    if command -v docker &> /dev/null; then
        local redis_container=$(docker ps --filter "name=redis" --format "{{.Names}}" | head -1)
        if [ -n "$redis_container" ]; then
            if docker exec "$redis_container" redis-cli ping | grep -q "PONG"; then
                log_success "Redis 缓存连接正常"
            else
                log_error "Redis 缓存连接失败"
            fi
        else
            log_warning "未找到 Redis 容器"
        fi
    fi
}

# 检查 API 端点
check_api_endpoints() {
    local base_url="http://localhost:8080"
    
    # 健康检查
    log_step "检查 API 健康状态"
    local health_response=$(curl -s "$base_url/health" 2>/dev/null || echo "")
    if echo "$health_response" | grep -q "healthy"; then
        log_success "API 健康检查通过"
    else
        log_error "API 健康检查失败"
    fi
    
    # API 版本信息
    log_step "检查 API 版本信息"
    local version_response=$(curl -s "$base_url/api/v1/version" 2>/dev/null || echo "")
    if [ -n "$version_response" ]; then
        log_success "API 版本信息获取成功"
    else
        log_warning "API 版本信息获取失败"
    fi
    
    # MIB 列表 API
    log_step "检查 MIB 管理 API"
    local mibs_response=$(curl -s -w "%{http_code}" -o /dev/null "$base_url/api/v1/mibs" 2>/dev/null || echo "000")
    if [ "$mibs_response" = "200" ] || [ "$mibs_response" = "401" ]; then
        log_success "MIB 管理 API 可访问"
    else
        log_error "MIB 管理 API 不可访问 (HTTP $mibs_response)"
    fi
}

# 检查前端应用
check_frontend() {
    local frontend_url="http://localhost:3000"
    
    log_step "检查前端应用"
    local frontend_response=$(curl -s -w "%{http_code}" -o /dev/null "$frontend_url" 2>/dev/null || echo "000")
    if [ "$frontend_response" = "200" ]; then
        log_success "前端应用运行正常"
    else
        log_error "前端应用访问失败 (HTTP $frontend_response)"
    fi
}

# 检查监控服务
check_monitoring() {
    # Grafana
    log_step "检查 Grafana 监控面板"
    local grafana_response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:3001" 2>/dev/null || echo "000")
    if [ "$grafana_response" = "200" ] || [ "$grafana_response" = "302" ]; then
        log_success "Grafana 监控面板可访问"
    else
        log_warning "Grafana 监控面板不可访问 (HTTP $grafana_response)"
    fi
    
    # VictoriaMetrics
    log_step "检查 VictoriaMetrics 时序数据库"
    local vm_response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:8428" 2>/dev/null || echo "000")
    if [ "$vm_response" = "200" ]; then
        log_success "VictoriaMetrics 时序数据库可访问"
    else
        log_warning "VictoriaMetrics 时序数据库不可访问 (HTTP $vm_response)"
    fi
}

# 检查文件权限和目录
check_file_permissions() {
    log_step "检查文件权限和目录"
    
    # 检查数据目录
    if [ -d "./data" ]; then
        log_success "数据目录存在"
    else
        log_warning "数据目录不存在"
    fi
    
    # 检查上传目录
    if [ -d "./uploads" ]; then
        log_success "上传目录存在"
    else
        log_warning "上传目录不存在"
    fi
    
    # 检查配置文件
    if [ -f ".env" ]; then
        log_success "环境配置文件存在"
    else
        log_warning "环境配置文件不存在，请复制 .env.example 为 .env"
    fi
}

# 性能测试
performance_test() {
    log_step "执行基础性能测试"
    
    local api_url="http://localhost:8080/health"
    local start_time=$(date +%s%N)
    
    for i in {1..10}; do
        curl -s "$api_url" > /dev/null 2>&1 || true
    done
    
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))
    local avg_response_time=$(( duration / 10 ))
    
    if [ $avg_response_time -lt 1000 ]; then
        log_success "API 平均响应时间: ${avg_response_time}ms (良好)"
    elif [ $avg_response_time -lt 3000 ]; then
        log_warning "API 平均响应时间: ${avg_response_time}ms (一般)"
    else
        log_error "API 平均响应时间: ${avg_response_time}ms (较慢)"
    fi
}

# 生成测试报告
generate_report() {
    echo ""
    echo -e "${CYAN}==================== 验证报告 ====================${NC}"
    echo -e "${GREEN}✅ 通过测试: $PASSED_TESTS${NC}"
    echo -e "${RED}❌ 失败测试: $FAILED_TESTS${NC}"
    echo -e "${BLUE}📊 总测试数: $TOTAL_TESTS${NC}"
    
    local success_rate=$(( PASSED_TESTS * 100 / TOTAL_TESTS ))
    echo -e "${YELLOW}📈 成功率: $success_rate%${NC}"
    
    echo ""
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}🎉 所有测试通过！SNMP MIB Platform 部署成功！${NC}"
        echo ""
        echo -e "${CYAN}访问地址:${NC}"
        echo -e "  🌐 前端界面: ${BLUE}http://localhost:3000${NC}"
        echo -e "  🔧 后端 API: ${BLUE}http://localhost:8080${NC}"
        echo -e "  📊 Grafana: ${BLUE}http://localhost:3001${NC} (admin/admin)"
        echo -e "  📈 VictoriaMetrics: ${BLUE}http://localhost:8428${NC}"
    elif [ $success_rate -ge 80 ]; then
        echo -e "${YELLOW}⚠️ 部分功能可能存在问题，但核心功能正常${NC}"
        echo -e "${YELLOW}建议检查失败的测试项目${NC}"
    else
        echo -e "${RED}❌ 部署存在严重问题，请检查日志和配置${NC}"
        echo -e "${RED}建议重新部署或查看故障排除文档${NC}"
    fi
    
    echo -e "${CYAN}=================================================${NC}"
}

# 主函数
main() {
    echo -e "${CYAN}"
    echo "================================================="
    echo "    SNMP MIB Platform 部署验证"
    echo "    检查服务状态和功能完整性"
    echo "================================================="
    echo -e "${NC}"
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 5
    
    # 执行检查
    check_docker_containers
    check_k8s_pods
    check_file_permissions
    
    # 检查端口
    check_port "前端" "localhost" "3000"
    check_port "后端" "localhost" "8080"
    check_port "PostgreSQL" "localhost" "5432"
    check_port "Redis" "localhost" "6379"
    
    # 检查服务
    check_service "前端应用" "http://localhost:3000"
    check_service "后端 API" "http://localhost:8080/health"
    check_service "Grafana" "http://localhost:3001" "302"
    check_service "VictoriaMetrics" "http://localhost:8428"
    
    # 检查数据库
    check_database
    
    # 检查 API
    check_api_endpoints
    
    # 性能测试
    performance_test
    
    # 生成报告
    generate_report
}

# 处理命令行参数
case "${1:-}" in
    "help"|"-h"|"--help")
        echo "用法: $0 [选项]"
        echo ""
        echo "选项:"
        echo "  help, -h, --help    显示此帮助信息"
        echo "  quick               快速检查（跳过性能测试）"
        echo "  full                完整检查（包含性能测试）"
        echo ""
        echo "示例:"
        echo "  $0                  执行完整验证"
        echo "  $0 quick            执行快速验证"
        exit 0
        ;;
    "quick")
        echo "执行快速验证..."
        # 跳过性能测试的快速版本
        ;;
    "full"|"")
        echo "执行完整验证..."
        ;;
    *)
        echo "未知选项: $1"
        echo "使用 '$0 help' 查看帮助信息"
        exit 1
        ;;
esac

# 执行主函数
main