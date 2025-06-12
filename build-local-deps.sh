#!/bin/bash

# MIB 监控平台本地依赖构建脚本 v2.0
# 用于在本地构建前端依赖和准备离线部署包
# 解决 Docker 构建时的网络问题
# 支持完整的离线部署包生成

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置变量
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build-cache"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OFFLINE_DIR="$PROJECT_DIR/mibweb-offline-deployment-$TIMESTAMP"
DOCKER_IMAGES_DIR="$OFFLINE_DIR/docker-images"
CONFIGS_DIR="$OFFLINE_DIR/configs"
SCRIPTS_DIR="$OFFLINE_DIR/scripts"
PROJECT_FILES_DIR="$OFFLINE_DIR/project-files"
DOCS_DIR="$OFFLINE_DIR/docs"
TOOLS_DIR="$OFFLINE_DIR/tools"

# 命令行参数
SKIP_FRONTEND=false
SKIP_BACKEND=false
SKIP_DOCKER=false
CONFIG_ONLY=false
VERBOSE=false
COMPRESS_OUTPUT=true
INCLUDE_MONITORING=false

log_info() {
    echo -e "${BLUE}[信息]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

log_error() {
    echo -e "${RED}[错误]${NC} $1"
}

# 检查必要工具
check_prerequisites() {
    log_info "检查必要工具..."
    
    # 检查 Node.js
    if ! command -v node >/dev/null 2>&1; then
        log_error "未找到 Node.js，请先安装 Node.js 18+"
        echo "安装方法:"
        echo "  • macOS: brew install node"
        echo "  • Ubuntu: curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt-get install -y nodejs"
        echo "  • CentOS: curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash - && sudo yum install -y nodejs"
        exit 1
    fi
    
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [[ $NODE_VERSION -lt 16 ]]; then
        log_error "Node.js 版本过低 (当前: $(node --version))，需要 16+"
        exit 1
    fi
    
    log_success "Node.js 版本: $(node --version)"
    
    # 检查 npm
    if ! command -v npm >/dev/null 2>&1; then
        log_error "未找到 npm"
        exit 1
    fi
    
    log_success "npm 版本: $(npm --version)"
    
    # 检查 Docker
    if ! command -v docker >/dev/null 2>&1; then
        log_warning "未找到 Docker，将跳过镜像构建"
        SKIP_DOCKER=true
    else
        log_success "Docker 版本: $(docker --version)"
        SKIP_DOCKER=false
    fi
}

# 配置 npm 镜像源
setup_npm_registry() {
    log_info "配置 npm 镜像源..."
    
    # 备份原始配置
    npm config get registry > .npm-registry-backup 2>/dev/null || echo "https://registry.npmjs.org/" > .npm-registry-backup
    
    # 只设置基本的 registry，避免使用已废弃的配置项
    npm config set registry https://registry.npmmirror.com
    
    # 使用环境变量方式设置其他镜像（兼容性更好）
    export ELECTRON_MIRROR="https://npmmirror.com/mirrors/electron/"
    export SASS_BINARY_SITE="https://npmmirror.com/mirrors/node-sass/"
    export PHANTOMJS_CDNURL="https://npmmirror.com/mirrors/phantomjs/"
    export CHROMEDRIVER_CDNURL="https://npmmirror.com/mirrors/chromedriver"
    export OPERADRIVER_CDNURL="https://npmmirror.com/mirrors/operadriver"
    export FSE_BINARY_HOST_MIRROR="https://npmmirror.com/mirrors/fsevents"
    
    log_success "npm 镜像源配置完成"
}

# 恢复 npm 配置
restore_npm_registry() {
    if [[ -f ".npm-registry-backup" ]]; then
        log_info "恢复 npm 配置..."
        ORIGINAL_REGISTRY=$(cat .npm-registry-backup)
        npm config set registry "$ORIGINAL_REGISTRY"
        
        # 清理环境变量（这些变量只在当前 shell 会话中有效）
        unset ELECTRON_MIRROR
        unset SASS_BINARY_SITE
        unset PHANTOMJS_CDNURL
        unset CHROMEDRIVER_CDNURL
        unset OPERADRIVER_CDNURL
        unset FSE_BINARY_HOST_MIRROR
        
        rm -f .npm-registry-backup
        log_success "npm 配置已恢复"
    fi
}

# 清理和准备
clean_and_prepare() {
    log_info "清理和准备构建环境..."
    
    # 清理旧的构建文件
    rm -rf node_modules .next dist build
    rm -rf build-cache offline-package
    
    # 创建构建缓存目录
    mkdir -p build-cache/{node_modules,docker-images,configs}
    
    log_success "构建环境准备完成"
}

# 安装前端依赖
install_frontend_deps() {
    log_info "安装前端依赖..."
    
    # 设置 npm 缓存目录
    export NPM_CONFIG_CACHE="$(pwd)/build-cache/npm-cache"
    
    # 检查是否存在 package-lock.json，决定使用哪种安装方式
    if [[ -f "package-lock.json" ]]; then
        log_info "发现 package-lock.json，使用 npm ci 安装..."
        npm ci --prefer-offline --no-audit --no-fund
    else
        log_info "未发现 package-lock.json，使用 npm install 安装..."
        npm install --prefer-offline --no-audit --no-fund
    fi
    
    # 复制 node_modules 到缓存
    log_info "缓存依赖文件..."
    cp -r node_modules build-cache/
    
    log_success "前端依赖安装完成"
}

# 构建前端应用
build_frontend() {
    log_info "构建前端应用..."
    
    # 设置环境变量
    export NODE_ENV=production
    export NEXT_TELEMETRY_DISABLED=1
    
    # 构建应用
    npm run build
    
    # 复制构建结果到缓存
    cp -r .next build-cache/
    
    log_success "前端应用构建完成"
}

# 创建优化的 Dockerfile
create_optimized_dockerfile() {
    log_info "创建优化的 Dockerfile..."
    
    cat > Dockerfile.local << 'EOF'
# MIB 监控平台 - 本地构建优化版
FROM node:18-alpine AS base

# 安装系统依赖
RUN apk add --no-cache \
    libc6-compat \
    curl \
    bash \
    docker-cli \
    && rm -rf /var/cache/apk/*

# 设置工作目录
WORKDIR /app

# 创建非 root 用户
RUN addgroup --system --gid 1001 nodejs \
    && adduser --system --uid 1001 nextjs

# 复制预构建的依赖
COPY --chown=nextjs:nodejs build-cache/node_modules ./node_modules
COPY --chown=nextjs:nodejs build-cache/.next ./.next

# 复制应用文件
COPY --chown=nextjs:nodejs package*.json ./
COPY --chown=nextjs:nodejs next.config.js ./
COPY --chown=nextjs:nodejs public ./public
COPY --chown=nextjs:nodejs app ./app
COPY --chown=nextjs:nodejs components ./components
COPY --chown=nextjs:nodejs lib ./lib
COPY --chown=nextjs:nodejs styles ./styles

# 设置权限
RUN chown -R nextjs:nodejs /app

# 切换到非 root 用户
USER nextjs

# 暴露端口
EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000/api/health || exit 1

# 启动应用
CMD ["npm", "start"]
EOF
    
    log_success "优化的 Dockerfile 创建完成"
}

# 构建 Docker 镜像
build_docker_images() {
    if [[ "$SKIP_DOCKER" == "true" ]]; then
        log_warning "跳过 Docker 镜像构建"
        return 0
    fi
    
    log_info "构建 Docker 镜像..."
    
    # 构建前端镜像
    docker build -f Dockerfile.local -t mib-frontend:local .
    
    # 保存镜像到文件
    log_info "导出 Docker 镜像..."
    docker save mib-frontend:local | gzip > build-cache/docker-images/mib-frontend-local.tar.gz
    
    # 构建其他必要镜像（如果有自定义后端）
    if [[ -d "backend" && -f "backend/Dockerfile" ]]; then
        log_info "构建后端镜像..."
        docker build -t mib-backend:local ./backend
        docker save mib-backend:local | gzip > build-cache/docker-images/mib-backend-local.tar.gz
    fi
    
    log_success "Docker 镜像构建完成"
}

# 下载外部镜像
download_external_images() {
    if [[ "$SKIP_DOCKER" == "true" ]]; then
        log_warning "跳过外部镜像下载"
        return 0
    fi
    
    log_info "下载外部 Docker 镜像..."
    
    # 基础镜像（必需）
    BASE_IMAGES=(
        "postgres:15-alpine"
        "redis:7-alpine"
        "nginx:alpine"
    )
    
    # 监控组件镜像（可选）
    MONITORING_IMAGES=(
        "victoriametrics/victoria-metrics:latest"
        "grafana/grafana:latest"
        "prom/alertmanager:latest"
        "prom/node-exporter:latest"
        "flashcatcloud/categraf:latest"
        "victoriametrics/vmagent:latest"
        "victoriametrics/vmalert:latest"
        "prom/snmp-exporter:latest"
    )
    
    # 下载基础镜像
    log_info "下载基础镜像..."
    for image in "${BASE_IMAGES[@]}"; do
        log_info "下载镜像: $image"
        docker pull "$image"
        
        # 生成文件名
        filename=$(echo "$image" | sed 's/[:/]/-/g')
        docker save "$image" | gzip > "build-cache/docker-images/${filename}.tar.gz"
    done
    
    # 根据配置决定是否下载监控组件镜像
    if [[ "$INCLUDE_MONITORING" == "true" ]]; then
        log_info "下载监控组件镜像..."
        for image in "${MONITORING_IMAGES[@]}"; do
            log_info "下载镜像: $image"
            docker pull "$image"
            
            # 生成文件名
            filename=$(echo "$image" | sed 's/[:/]/-/g')
            docker save "$image" | gzip > "build-cache/docker-images/${filename}.tar.gz"
        done
        log_success "监控组件镜像下载完成"
    else
        log_info "跳过监控组件镜像下载（使用 --include-monitoring 参数可包含）"
    fi
    
    log_success "外部镜像下载完成"
}

# 创建配置文件
create_config_files() {
    log_info "创建配置文件..."
    
    # 创建数据库初始化脚本
    mkdir -p build-cache/configs/database
    cat > build-cache/configs/database/init.sql << 'EOF'
-- MIB 平台数据库初始化脚本

-- 创建监控组件表
CREATE TABLE IF NOT EXISTS monitoring_components (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    display_name VARCHAR(200) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL,
    default_port INTEGER,
    config_template JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建组件版本表
CREATE TABLE IF NOT EXISTS component_versions (
    id SERIAL PRIMARY KEY,
    component_id INTEGER REFERENCES monitoring_components(id),
    version VARCHAR(50) NOT NULL,
    docker_image VARCHAR(200) NOT NULL,
    is_stable BOOLEAN DEFAULT false,
    release_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建安装记录表
CREATE TABLE IF NOT EXISTS installations (
    id SERIAL PRIMARY KEY,
    component_id INTEGER REFERENCES monitoring_components(id),
    version_id INTEGER REFERENCES component_versions(id),
    config JSONB NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    container_id VARCHAR(100),
    ports JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 插入默认监控组件
INSERT INTO monitoring_components (name, display_name, description, category, default_port, config_template) VALUES
('node-exporter', 'Node Exporter', '系统指标收集器', 'exporter', 9100, '{"path.rootfs":"/host"}'),
('categraf', 'Categraf', '多功能监控采集器', 'agent', 9100, '{"interval":"10s"}'),
('vmAgent', 'VMAgent', 'VictoriaMetrics 代理', 'agent', 8429, '{"remoteWrite.url":"http://victoriametrics:8428/api/v1/write"}'),
('victoriametrics', 'VictoriaMetrics', '时序数据库', 'storage', 8428, '{"retentionPeriod":"12"}'),
('grafana', 'Grafana', '可视化面板', 'visualization', 3000, '{"admin.password":"admin"}'),
('snmp-exporter', 'SNMP Exporter', 'SNMP 监控导出器', 'exporter', 9116, '{"config.file":"/etc/snmp_exporter/snmp.yml"}'),
('alertmanager', 'Alertmanager', '告警管理器', 'alerting', 9093, '{"config.file":"/etc/alertmanager/alertmanager.yml"}')
ON CONFLICT (name) DO NOTHING;
EOF
    
    # 创建 Grafana 配置
    mkdir -p build-cache/configs/grafana/{provisioning/{datasources,dashboards},dashboards}
    
    cat > build-cache/configs/grafana/provisioning/datasources/victoriametrics.yml << 'EOF'
apiVersion: 1
datasources:
  - name: VictoriaMetrics
    type: prometheus
    access: proxy
    url: http://victoriametrics:8428
    isDefault: true
    editable: true
EOF
    
    cat > build-cache/configs/grafana/provisioning/dashboards/default.yml << 'EOF'
apiVersion: 1
providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/dashboards
EOF
    
    # 创建 Alertmanager 配置
    mkdir -p build-cache/configs/alertmanager
    cat > build-cache/configs/alertmanager/alertmanager.yml << 'EOF'
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alertmanager@mib-platform.local'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

receivers:
  - name: 'web.hook'
    webhook_configs:
      - url: 'http://backend:8080/api/alerts/webhook'
EOF
    
    log_success "配置文件创建完成"
}

# 创建离线部署包
create_offline_package() {
    log_info "创建离线部署包..."
    
    # 创建离线包目录
    mkdir -p offline-package
    
    # 复制构建缓存
    cp -r build-cache offline-package/
    
    # 复制项目文件
    cp -r {\
        package*.json,\
        next.config.js,\
        public,\
        app,\
        components,\
        lib,\
        styles,\
        Dockerfile.local,\
        docker-compose.complete.yml\
    } offline-package/ 2>/dev/null || true
    
    # 复制部署脚本
    cp deploy-zero-config.sh offline-package/ 2>/dev/null || true
    cp quick-start.sh offline-package/ 2>/dev/null || true
    
    # 创建离线安装脚本
    cat > offline-package/install-offline.sh << 'EOF'
#!/bin/bash

# MIB 平台离线安装脚本

set -e

log_info() {
    echo -e "\033[0;34m[信息]\033[0m $1"
}

log_success() {
    echo -e "\033[0;32m[成功]\033[0m $1"
}

log_error() {
    echo -e "\033[0;31m[错误]\033[0m $1"
}

# 检查 Docker
if ! command -v docker >/dev/null 2>&1; then
    log_error "请先安装 Docker"
    exit 1
fi

if ! command -v docker-compose >/dev/null 2>&1; then
    log_error "请先安装 Docker Compose"
    exit 1
fi

log_info "开始离线安装..."

# 加载 Docker 镜像
if [[ -d "build-cache/docker-images" ]]; then
    log_info "加载 Docker 镜像..."
    for image_file in build-cache/docker-images/*.tar.gz; do
        if [[ -f "$image_file" ]]; then
            log_info "加载: $(basename "$image_file")"
            docker load < "$image_file"
        fi
    done
    log_success "Docker 镜像加载完成"
fi

# 复制配置文件
if [[ -d "build-cache/configs" ]]; then
    log_info "复制配置文件..."
    cp -r build-cache/configs/* .
    log_success "配置文件复制完成"
fi

# 启动服务
log_info "启动服务..."
docker-compose -f docker-compose.complete.yml up -d

log_success "离线安装完成！"
log_info "访问地址: http://localhost:3000"
EOF
    
    chmod +x offline-package/install-offline.sh
    
    # 创建说明文件
    cat > offline-package/README.md << 'EOF'
# MIB 监控平台离线部署包

## 快速开始

1. 确保已安装 Docker 和 Docker Compose
2. 运行安装脚本:
   ```bash
   chmod +x install-offline.sh
   ./install-offline.sh
   ```

## 包含内容

- 预构建的前端应用
- 所有必要的 Docker 镜像
- 完整的配置文件
- 自动化部署脚本

## 系统要求

- Docker 20.10+
- Docker Compose 2.0+
- 4GB+ 内存
- 20GB+ 磁盘空间

## 访问地址

- 主界面: http://localhost:3000
- Grafana: http://localhost:3001
- API: http://localhost:8080
EOF
    
    # 打包
    log_info "压缩离线包..."
    tar -czf "mib-platform-offline-$(date +%Y%m%d-%H%M%S).tar.gz" offline-package/
    
    log_success "离线部署包创建完成"
}

# 显示结果
show_result() {
    echo
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                    本地构建完成！                            ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo
    
    if [[ "$INCLUDE_MONITORING" == "true" ]]; then
        echo -e "${BLUE}🎯 构建模式: 完整版 (包含监控组件)${NC}"
    else
        echo -e "${BLUE}🎯 构建模式: 基础版 (仅Web UI)${NC}"
    fi
    echo
    
    echo "📦 构建产物:"
    echo "  • 前端依赖: build-cache/node_modules/"
    echo "  • 构建结果: build-cache/.next/"
    if [[ "$SKIP_DOCKER" != "true" ]]; then
        echo "  • Docker 镜像: build-cache/docker-images/"
        if [[ "$INCLUDE_MONITORING" == "true" ]]; then
            echo "    - 基础镜像: PostgreSQL, Redis, Nginx"
            echo "    - 监控镜像: VictoriaMetrics, Grafana, Alertmanager等"
        else
            echo "    - 基础镜像: PostgreSQL, Redis, Nginx"
        fi
    fi
    echo "  • 配置文件: build-cache/configs/"
    echo "  • 离线部署包: mib-platform-offline-*.tar.gz"
    echo
    echo "🚀 下一步:"
    echo "  1. 将离线包传输到目标服务器"
    echo "  2. 解压并运行 install-offline.sh"
    echo "  3. 或者使用 deploy-zero-config.sh 进行在线部署"
    echo
    echo "💡 提示:"
    if [[ "$INCLUDE_MONITORING" == "true" ]]; then
        echo "  • 离线包包含完整的监控组件和依赖"
        echo "  • 支持一键部署完整的SNMP监控平台"
    else
        echo "  • 离线包仅包含Web UI和基础组件"
        echo "  • 监控组件可在Web界面中按需安装"
        echo "  • 如需预装监控组件，请使用 --include-monitoring 参数重新构建"
    fi
    echo "  • 目标服务器只需要 Docker 环境"
    echo "  • 支持完全离线部署"
    echo
}

# 清理函数
cleanup() {
    log_info "清理临时文件..."
    
    # 恢复 npm 配置
    restore_npm_registry
    
    # 清理临时文件
    rm -f .npm-registry-backup
    
    # 可以选择保留或删除 build-cache
    # rm -rf build-cache
}

# 显示帮助信息
show_usage() {
    echo "MIB 监控平台本地依赖构建工具 v2.0"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --include-monitoring    包含监控组件镜像 (VictoriaMetrics, Grafana, Alertmanager等)"
    echo "  --skip-frontend        跳过前端构建"
    echo "  --skip-backend         跳过后端构建"
    echo "  --skip-docker          跳过Docker镜像构建"
    echo "  --config-only          仅生成配置文件"
    echo "  --verbose              详细输出"
    echo "  --help                 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                           # 仅构建基础Web UI"
    echo "  $0 --include-monitoring      # 构建包含监控组件的完整版本"
    echo "  $0 --skip-docker             # 跳过Docker镜像构建"
    echo ""
}

# 解析命令行参数
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --include-monitoring)
                INCLUDE_MONITORING=true
                shift
                ;;
            --skip-frontend)
                SKIP_FRONTEND=true
                shift
                ;;
            --skip-backend)
                SKIP_BACKEND=true
                shift
                ;;
            --skip-docker)
                SKIP_DOCKER=true
                shift
                ;;
            --config-only)
                CONFIG_ONLY=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# 错误处理
handle_error() {
    log_error "构建过程中发生错误"
    # 确保恢复 npm 配置
    restore_npm_registry
    cleanup
    exit 1
}

# 主函数
main() {
    trap handle_error ERR
    trap cleanup EXIT
    
    # 解析命令行参数
    parse_arguments "$@"
    
    echo -e "${BLUE}MIB 监控平台本地依赖构建工具${NC}"
    echo
    
    if [[ "$INCLUDE_MONITORING" == "true" ]]; then
        log_info "构建模式: 完整版 (包含监控组件)"
    else
        log_info "构建模式: 基础版 (仅Web UI)"
    fi
    echo
    
    check_prerequisites
    setup_npm_registry
    clean_and_prepare
    install_frontend_deps
    build_frontend
    create_optimized_dockerfile
    build_docker_images
    download_external_images
    create_config_files
    create_offline_package
    show_result
}

# 执行主函数
main "$@"