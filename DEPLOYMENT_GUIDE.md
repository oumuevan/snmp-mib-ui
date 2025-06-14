# MIB Platform 部署指南

## 概述

MIB Platform 是一个企业级 SNMP 监控管理平台，支持 MIB 文件管理、配置生成、告警规则管理和监控组件安装。

## 系统要求

### 最低配置
- CPU: 4 核
- 内存: 8GB
- 存储: 50GB
- 操作系统: Ubuntu 20.04+ / CentOS 8+ / Debian 11+

### 推荐配置
- CPU: 8 核
- 内存: 16GB
- 存储: 100GB SSD
- 操作系统: Ubuntu 22.04 LTS

## 快速部署

### 1. 使用 Docker Compose (推荐)

```bash
# 克隆项目
git clone <repository-url>
cd snmp-mib-ui

# 启动完整监控栈
docker-compose -f docker-compose.monitoring.yml up -d

# 查看服务状态
docker-compose -f docker-compose.monitoring.yml ps
```

### 2. 服务访问地址

| 服务 | 地址 | 用户名/密码 |
|------|------|-------------|
| MIB Platform 前端 | http://localhost:3000 | - |
| MIB Platform 后端 | http://localhost:8080 | - |
| Grafana | http://localhost:3001 | admin/admin |
| VictoriaMetrics | http://localhost:8428 | - |
| Alertmanager | http://localhost:9093 | - |
| SNMP Exporter | http://localhost:9116 | - |

## 详细部署步骤

### 1. 环境准备

#### 安装 Docker 和 Docker Compose

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# 安装 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

#### 安装 SNMP 工具 (可选)

```bash
# 运行安装脚本
sudo ./backend/scripts/install-snmp-tools.sh
```

### 2. 配置文件准备

#### 创建环境变量文件

```bash
# 创建 .env 文件
cat > .env << EOF
# 数据库配置
POSTGRES_DB=mib_platform
POSTGRES_USER=mib_user
POSTGRES_PASSWORD=your_secure_password

# Redis 配置
REDIS_URL=redis://redis:6379

# 应用配置
DATABASE_URL=postgres://mib_user:your_secure_password@postgres:5432/mib_platform?sslmode=disable
PROMETHEUS_URL=http://victoriametrics:8428
API_URL=http://localhost:8080/api/v1

# 安全配置
JWT_SECRET=your_jwt_secret_key
ENCRYPTION_KEY=your_32_char_encryption_key

# 邮件配置 (告警通知)
SMTP_HOST=smtp.company.com
SMTP_PORT=587
SMTP_USER=alerts@company.com
SMTP_PASSWORD=smtp_password
EOF
```

#### 创建目录结构

```bash
# 创建必要的目录
sudo mkdir -p /opt/monitoring/{mibs,config/{snmp_exporter,categraf/input.snmp}}
sudo chown -R $USER:$USER /opt/monitoring
```

### 3. 启动服务

#### 分步启动 (推荐用于生产环境)

```bash
# 1. 启动基础服务
docker-compose -f docker-compose.monitoring.yml up -d postgres redis

# 2. 等待数据库启动
sleep 30

# 3. 启动应用服务
docker-compose -f docker-compose.monitoring.yml up -d mib-backend mib-frontend

# 4. 启动监控服务
docker-compose -f docker-compose.monitoring.yml up -d victoriametrics vmagent

# 5. 启动可视化和告警服务
docker-compose -f docker-compose.monitoring.yml up -d grafana vmalert alertmanager

# 6. 启动 SNMP 相关服务
docker-compose -f docker-compose.monitoring.yml up -d snmp-exporter categraf node-exporter
```

#### 一键启动

```bash
docker-compose -f docker-compose.monitoring.yml up -d
```

### 4. 验证部署

#### 检查服务状态

```bash
# 查看所有服务状态
docker-compose -f docker-compose.monitoring.yml ps

# 查看服务日志
docker-compose -f docker-compose.monitoring.yml logs -f mib-backend
```

#### 健康检查

```bash
# 检查后端 API
curl http://localhost:8080/health

# 检查前端
curl http://localhost:3000

# 检查 VictoriaMetrics
curl http://localhost:8428/metrics
```

## 高级配置

### 1. SSL/TLS 配置

#### 生成自签名证书

```bash
mkdir -p monitoring/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout monitoring/nginx/ssl/nginx.key \
  -out monitoring/nginx/ssl/nginx.crt \
  -subj "/C=CN/ST=State/L=City/O=Organization/CN=mib-platform.local"
```

#### Nginx 配置

```nginx
# monitoring/nginx/nginx.conf
events {
    worker_connections 1024;
}

http {
    upstream mib-frontend {
        server mib-frontend:3000;
    }
    
    upstream mib-backend {
        server mib-backend:8080;
    }
    
    upstream grafana {
        server grafana:3000;
    }

    server {
        listen 80;
        server_name mib-platform.local;
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl;
        server_name mib-platform.local;

        ssl_certificate /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx.key;

        location / {
            proxy_pass http://mib-frontend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location /api/ {
            proxy_pass http://mib-backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location /grafana/ {
            proxy_pass http://grafana/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
```

### 2. 数据持久化

#### 备份配置

```bash
# 创建备份脚本
cat > backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/backups/mib-platform"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# 备份数据库
docker exec mib-postgres pg_dump -U mib_user mib_platform > $BACKUP_DIR/db_$DATE.sql

# 备份配置文件
tar -czf $BACKUP_DIR/configs_$DATE.tar.gz /opt/monitoring

# 清理旧备份 (保留7天)
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
EOF

chmod +x backup.sh

# 添加到 crontab
echo "0 2 * * * /path/to/backup.sh" | crontab -
```

### 3. 监控和告警

#### 自定义告警规则

```yaml
# monitoring/vmalert/rules/mib-platform.yml
groups:
  - name: mib-platform
    rules:
      - alert: MIBBackendDown
        expr: up{job="mib-backend"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "MIB Platform Backend is down"
          description: "MIB Platform Backend has been down for more than 1 minute"

      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage detected"
          description: "Memory usage is above 90% for more than 5 minutes"

      - alert: SNMPDeviceDown
        expr: snmp_up == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "SNMP device {{ $labels.instance }} is down"
          description: "SNMP device {{ $labels.instance }} has been unreachable for more than 2 minutes"
```

## 故障排除

### 常见问题

#### 1. 服务启动失败

```bash
# 查看详细日志
docker-compose -f docker-compose.monitoring.yml logs service-name

# 检查端口占用
netstat -tulpn | grep :port

# 重启服务
docker-compose -f docker-compose.monitoring.yml restart service-name
```

#### 2. 数据库连接问题

```bash
# 检查数据库状态
docker exec mib-postgres pg_isready -U mib_user

# 重置数据库
docker-compose -f docker-compose.monitoring.yml down
docker volume rm snmp-mib-ui_postgres_data
docker-compose -f docker-compose.monitoring.yml up -d postgres
```

#### 3. SNMP 工具问题

```bash
# 测试 SNMP 连接
snmpwalk -v2c -c public 192.168.1.1 1.3.6.1.2.1.1

# 检查 MIB 文件
snmptranslate -Td SNMPv2-MIB::sysDescr
```

### 性能优化

#### 1. 数据库优化

```sql
-- 在 PostgreSQL 中执行
-- 创建索引
CREATE INDEX idx_oids_oid ON oids(oid);
CREATE INDEX idx_devices_ip ON devices(ip_address);
CREATE INDEX idx_configs_type ON configs(type);

-- 优化配置
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
SELECT pg_reload_conf();
```

#### 2. 监控优化

```yaml
# 调整采集间隔
global:
  scrape_interval: 30s  # 增加间隔减少负载
  evaluation_interval: 30s

# 限制指标保留时间
command:
  - "--storageDataPath=/victoria-metrics-data"
  - "--retentionPeriod=30d"  # 保留30天数据
```

## 安全建议

### 1. 网络安全

- 使用防火墙限制访问端口
- 配置 VPN 访问内部服务
- 启用 SSL/TLS 加密

### 2. 认证和授权

- 修改默认密码
- 启用双因素认证
- 定期轮换密钥

### 3. 数据安全

- 定期备份数据
- 加密敏感配置
- 监控异常访问

## 维护和更新

### 1. 定期维护

```bash
# 清理 Docker 资源
docker system prune -f

# 更新镜像
docker-compose -f docker-compose.monitoring.yml pull
docker-compose -f docker-compose.monitoring.yml up -d
```

### 2. 版本升级

```bash
# 备份当前版本
./backup.sh

# 拉取新版本
git pull origin main

# 重新构建和部署
docker-compose -f docker-compose.monitoring.yml build
docker-compose -f docker-compose.monitoring.yml up -d
```

## 支持和联系

如有问题，请联系：
- 技术支持: support@company.com
- 文档: https://docs.mib-platform.com
- 问题反馈: https://github.com/company/mib-platform/issues