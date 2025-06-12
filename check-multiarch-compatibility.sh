#!/bin/bash

# Multi-Architecture Compatibility Checker
# 全面检查项目的多架构兼容性

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_check() {
    echo -e "${PURPLE}[CHECK]${NC} $1"
}

# 全局变量
COMPATIBILITY_ISSUES=0
WARNINGS=0
CHECKS_PASSED=0

# 显示横幅
show_banner() {
    echo -e "${CYAN}"
    echo "═══════════════════════════════════════════════════════════════"
    echo "    🔍 MIB Web Platform - Multi-Architecture Compatibility Check"
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

# 检查 Docker 文件中的硬编码架构
check_dockerfile_architecture() {
    log_check "检查 Dockerfile 中的硬编码架构..."
    
    local files=(
        "Dockerfile"
        "Dockerfile.china"
        "Dockerfile.multiarch"
        "backend/Dockerfile"
    )
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            log_info "检查文件: $file"
            
            # 检查硬编码的 GOARCH
            if grep -q "GOARCH=amd64" "$file" 2>/dev/null; then
                log_error "发现硬编码架构: $file 包含 GOARCH=amd64"
                COMPATIBILITY_ISSUES=$((COMPATIBILITY_ISSUES + 1))
            else
                log_success "$file: 无硬编码架构问题"
                CHECKS_PASSED=$((CHECKS_PASSED + 1))
            fi
            
            # 检查是否使用了多架构构建参数
            if grep -q "TARGETARCH\|BUILDPLATFORM\|TARGETPLATFORM" "$file" 2>/dev/null; then
                log_success "$file: 支持多架构构建参数"
                CHECKS_PASSED=$((CHECKS_PASSED + 1))
            else
                log_warning "$file: 未使用多架构构建参数"
                WARNINGS=$((WARNINGS + 1))
            fi
        fi
    done
}

# 检查 Docker Compose 文件的架构支持
check_docker_compose_architecture() {
    log_check "检查 Docker Compose 文件的架构支持..."
    
    local files=(
        "docker-compose.yml"
        "docker-compose.china.yml"
        "docker-compose.multiarch.yml"
    )
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            log_info "检查文件: $file"
            
            # 检查是否指定了 platform
            if grep -q "platform:" "$file" 2>/dev/null; then
                log_success "$file: 包含平台指定"
                CHECKS_PASSED=$((CHECKS_PASSED + 1))
                
                # 检查是否支持多架构
                if grep -q "linux/arm64\|linux/amd64\|\${TARGETARCH}" "$file" 2>/dev/null; then
                    log_success "$file: 支持多架构平台"
                    CHECKS_PASSED=$((CHECKS_PASSED + 1))
                else
                    log_warning "$file: 平台支持有限"
                    WARNINGS=$((WARNINGS + 1))
                fi
            else
                log_warning "$file: 未指定平台，将使用默认架构"
                WARNINGS=$((WARNINGS + 1))
            fi
        fi
    done
}

# 检查构建脚本的架构兼容性
check_build_scripts() {
    log_check "检查构建脚本的架构兼容性..."
    
    local scripts=(
        "deploy.sh"
        "deploy-china.sh"
        "deploy-multiarch.sh"
        "backend/Makefile"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            log_info "检查脚本: $script"
            
            # 检查架构检测逻辑
            if grep -q "uname -m\|dpkg --print-architecture\|GOARCH\|TARGETARCH" "$script" 2>/dev/null; then
                log_success "$script: 包含架构检测逻辑"
                CHECKS_PASSED=$((CHECKS_PASSED + 1))
            else
                log_warning "$script: 缺少架构检测逻辑"
                WARNINGS=$((WARNINGS + 1))
            fi
            
            # 检查是否有硬编码的架构
            if grep -q "GOARCH=amd64" "$script" 2>/dev/null && ! grep -q "GOARCH=arm64" "$script" 2>/dev/null; then
                log_error "$script: 包含硬编码的 AMD64 架构"
                COMPATIBILITY_ISSUES=$((COMPATIBILITY_ISSUES + 1))
            fi
        fi
    done
}

# 检查启动脚本的架构优化
check_startup_scripts() {
    log_check "检查启动脚本的架构优化..."
    
    local scripts=(
        "start.sh"
        "start-china.sh"
        "start-multiarch.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            log_info "检查启动脚本: $script"
            
            # 检查架构特定优化
            if grep -q "arm64\|amd64\|armv7" "$script" 2>/dev/null; then
                log_success "$script: 包含架构特定优化"
                CHECKS_PASSED=$((CHECKS_PASSED + 1))
            else
                log_warning "$script: 缺少架构特定优化"
                WARNINGS=$((WARNINGS + 1))
            fi
        fi
    done
}

# 检查文档的架构支持说明
check_documentation() {
    log_check "检查文档的架构支持说明..."
    
    local docs=(
        "README.md"
        "DEPLOYMENT-GUIDE.md"
        "ARM64-DEPLOYMENT-GUIDE.md"
    )
    
    for doc in "${docs[@]}"; do
        if [ -f "$doc" ]; then
            log_info "检查文档: $doc"
            
            # 检查是否提到多架构支持
            if grep -qi "arm64\|amd64\|architecture\|架构" "$doc" 2>/dev/null; then
                log_success "$doc: 包含架构支持说明"
                CHECKS_PASSED=$((CHECKS_PASSED + 1))
            else
                log_warning "$doc: 缺少架构支持说明"
                WARNINGS=$((WARNINGS + 1))
            fi
        fi
    done
}

# 检查依赖包的架构兼容性
check_dependencies() {
    log_check "检查依赖包的架构兼容性..."
    
    # 检查 package.json
    if [ -f "package.json" ]; then
        log_info "检查 Node.js 依赖..."
        
        # 检查是否有架构特定的依赖
        if grep -q "optionalDependencies\|cpu\|os" package.json 2>/dev/null; then
            log_success "package.json: 包含架构特定配置"
            CHECKS_PASSED=$((CHECKS_PASSED + 1))
        else
            log_warning "package.json: 未发现架构特定配置"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
    
    # 检查 Go 模块
    if [ -f "backend/go.mod" ]; then
        log_info "检查 Go 依赖..."
        
        # 检查是否有架构相关的依赖
        if grep -q "golang.org/x/arch\|golang.org/x/sys" backend/go.mod 2>/dev/null; then
            log_success "go.mod: 包含架构相关依赖"
            CHECKS_PASSED=$((CHECKS_PASSED + 1))
        else
            log_warning "go.mod: 未发现明确的架构相关依赖"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
}

# 检查配置文件的架构兼容性
check_configuration_files() {
    log_check "检查配置文件的架构兼容性..."
    
    local configs=(
        ".env.example"
        "nginx/nginx.conf"
        "redis/redis.conf"
    )
    
    for config in "${configs[@]}"; do
        if [ -f "$config" ]; then
            log_info "检查配置: $config"
            
            # 检查是否有架构特定的配置
            if grep -qi "arch\|platform\|cpu" "$config" 2>/dev/null; then
                log_success "$config: 包含架构相关配置"
                CHECKS_PASSED=$((CHECKS_PASSED + 1))
            else
                log_info "$config: 架构无关配置（正常）"
                CHECKS_PASSED=$((CHECKS_PASSED + 1))
            fi
        fi
    done
}

# 检查数据库初始化脚本
check_database_scripts() {
    log_check "检查数据库初始化脚本..."
    
    local db_scripts=(
        "database/init/*.sql"
        "init-scripts/*.sql"
        "backend/migrations/*.sql"
    )
    
    local found_scripts=false
    for pattern in "${db_scripts[@]}"; do
        for script in $pattern; do
            if [ -f "$script" ]; then
                found_scripts=true
                log_info "检查数据库脚本: $script"
                
                # 数据库脚本通常是架构无关的
                log_success "$script: 数据库脚本架构无关（正常）"
                CHECKS_PASSED=$((CHECKS_PASSED + 1))
            fi
        done
    done
    
    if [ "$found_scripts" = false ]; then
        log_warning "未找到数据库初始化脚本"
        WARNINGS=$((WARNINGS + 1))
    fi
}

# 检查 CI/CD 配置
check_cicd_configuration() {
    log_check "检查 CI/CD 配置的多架构支持..."
    
    local cicd_files=(
        ".github/workflows/*.yml"
        ".github/workflows/*.yaml"
        ".gitlab-ci.yml"
        "Jenkinsfile"
    )
    
    local found_cicd=false
    for pattern in "${cicd_files[@]}"; do
        for file in $pattern; do
            if [ -f "$file" ]; then
                found_cicd=true
                log_info "检查 CI/CD 配置: $file"
                
                # 检查是否配置了多架构构建
                if grep -q "matrix\|strategy\|platform" "$file" 2>/dev/null; then
                    log_success "$file: 包含多架构构建配置"
                    CHECKS_PASSED=$((CHECKS_PASSED + 1))
                else
                    log_warning "$file: 缺少多架构构建配置"
                    WARNINGS=$((WARNINGS + 1))
                fi
            fi
        done
    done
    
    if [ "$found_cicd" = false ]; then
        log_info "未找到 CI/CD 配置文件"
    fi
}

# 验证多架构 Docker 构建
test_multiarch_build() {
    log_check "测试多架构 Docker 构建能力..."
    
    # 检查 Docker Buildx 是否可用
    if command -v docker &> /dev/null; then
        if docker buildx version &> /dev/null; then
            log_success "Docker Buildx 可用"
            CHECKS_PASSED=$((CHECKS_PASSED + 1))
            
            # 检查支持的平台
            local platforms=$(docker buildx ls | grep -o 'linux/[^,]*' | sort -u | tr '\n' ' ')
            if [ -n "$platforms" ]; then
                log_success "支持的平台: $platforms"
                CHECKS_PASSED=$((CHECKS_PASSED + 1))
            else
                log_warning "无法检测支持的平台"
                WARNINGS=$((WARNINGS + 1))
            fi
        else
            log_warning "Docker Buildx 不可用"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        log_warning "Docker 未安装，跳过构建测试"
        WARNINGS=$((WARNINGS + 1))
    fi
}

# 生成兼容性报告
generate_compatibility_report() {
    local report_file="multiarch-compatibility-report.md"
    
    log_info "生成兼容性报告: $report_file"
    
    cat > "$report_file" << EOF
# Multi-Architecture Compatibility Report

生成时间: $(date)
检查的项目: MIB Web Platform

## 📊 检查结果摘要

- ✅ 通过检查: $CHECKS_PASSED
- ⚠️  警告: $WARNINGS
- ❌ 兼容性问题: $COMPATIBILITY_ISSUES

## 🔍 详细检查项目

### Docker 文件架构兼容性
- 检查 Dockerfile 中的硬编码架构
- 验证多架构构建参数使用

### Docker Compose 配置
- 检查平台指定
- 验证多架构支持

### 构建脚本
- 架构检测逻辑
- 硬编码架构检查

### 启动脚本
- 架构特定优化
- 性能调优配置

### 文档完整性
- 架构支持说明
- 部署指南覆盖

### 依赖包兼容性
- Node.js 依赖检查
- Go 模块检查

### 配置文件
- 架构相关配置
- 环境变量设置

### CI/CD 配置
- 多架构构建支持
- 自动化测试覆盖

## 🎯 建议改进

EOF

    if [ $COMPATIBILITY_ISSUES -gt 0 ]; then
        cat >> "$report_file" << EOF
### ❌ 需要修复的问题

1. 移除所有硬编码的架构配置
2. 使用 Docker Buildx 多架构构建参数
3. 更新构建脚本以支持架构检测

EOF
    fi
    
    if [ $WARNINGS -gt 0 ]; then
        cat >> "$report_file" << EOF
### ⚠️ 建议优化的项目

1. 添加架构特定的性能优化
2. 完善文档中的架构支持说明
3. 配置 CI/CD 多架构构建

EOF
    fi
    
    cat >> "$report_file" << EOF
## 🚀 多架构部署建议

### 推荐的部署方式

1. **自动检测部署**
   ```bash
   bash deploy-multiarch.sh
   ```

2. **架构特定部署**
   - AMD64: `bash deploy.sh`
   - ARM64: `bash deploy-china.sh`
   - 多架构: `bash deploy-multiarch.sh`

### Docker 多架构构建

```bash
# 创建多架构构建器
docker buildx create --name multiarch --use

# 构建多架构镜像
docker buildx build --platform linux/amd64,linux/arm64 -t mibweb:latest .
```

## 📚 相关文档

- [ARM64 部署指南](./ARM64-DEPLOYMENT-GUIDE.md)
- [部署指南](./DEPLOYMENT-GUIDE.md)
- [故障排除](./docs/troubleshooting.md)
EOF

    log_success "兼容性报告已生成: $report_file"
}

# 显示检查结果
show_results() {
    echo -e "${CYAN}"
    echo "═══════════════════════════════════════════════════════════════"
    echo "    📋 Multi-Architecture Compatibility Check Results"
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "${NC}"
    
    echo "📊 检查统计:"
    echo -e "  ${GREEN}✅ 通过检查: $CHECKS_PASSED${NC}"
    echo -e "  ${YELLOW}⚠️  警告: $WARNINGS${NC}"
    echo -e "  ${RED}❌ 兼容性问题: $COMPATIBILITY_ISSUES${NC}"
    echo ""
    
    if [ $COMPATIBILITY_ISSUES -eq 0 ] && [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}🎉 恭喜！项目完全兼容多架构部署！${NC}"
    elif [ $COMPATIBILITY_ISSUES -eq 0 ]; then
        echo -e "${YELLOW}⚠️  项目基本兼容多架构，但有一些建议优化的地方${NC}"
    else
        echo -e "${RED}❌ 发现兼容性问题，需要修复后才能进行多架构部署${NC}"
    fi
    
    echo ""
    echo "📄 详细报告已生成: multiarch-compatibility-report.md"
    echo ""
    echo "🚀 推荐的部署命令:"
    if [ $COMPATIBILITY_ISSUES -eq 0 ]; then
        echo "  bash deploy-multiarch.sh  # 自动检测架构并部署"
    else
        echo "  请先修复兼容性问题，然后运行: bash deploy-multiarch.sh"
    fi
}

# 主函数
main() {
    show_banner
    
    # 执行所有检查
    check_dockerfile_architecture
    check_docker_compose_architecture
    check_build_scripts
    check_startup_scripts
    check_documentation
    check_dependencies
    check_configuration_files
    check_database_scripts
    check_cicd_configuration
    test_multiarch_build
    
    # 生成报告和显示结果
    generate_compatibility_report
    show_results
    
    # 设置退出码
    if [ $COMPATIBILITY_ISSUES -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# 执行主函数
main "$@"