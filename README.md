# MIB Web UI

一个现代化的 SNMP MIB 管理和监控 Web 应用程序，基于 Next.js 14 构建，提供直观的用户界面来管理和监控网络设备。

## 🎯 [📋 快速导航索引](QUICK-START-INDEX.md) - 5分钟找到你需要的一切！

| 🚀 [快速部署](DEPLOYMENT-GUIDE.md#5分钟快速部署) | 🛠️ [开发指南](PROJECT-ENHANCEMENT-PLAN.md) | 🆘 [故障排查](DEPLOYMENT-GUIDE.md#故障排查) | 📚 [完整文档](DEPLOYMENT-GUIDE.md) |
|:---:|:---:|:---:|:---:|

一个现代化的 MIB (Management Information Base) 文件管理和 SNMP 操作平台，专为网络设备管理和监控而设计。

## 🚀 功能特性

### 核心功能
- **MIB 文件管理**: 上传、解析、搜索和管理 MIB 文件
- **OID 浏览器**: 可视化浏览和搜索 OID 树结构
- **SNMP 操作**: 支持 Get、Walk、Set 操作，兼容 SNMPv1/v2c/v3
- **设备管理**: 网络设备的添加、配置和状态监控
- **配置管理**: 设备配置模板和版本控制
- **实时监控**: 设备状态和性能指标的实时监控
- **告警规则**: 智能告警规则配置和管理
- **数据分析**: 网络设备性能分析和报表

### 技术特色
- **现代化架构**: 前端 Next.js + 后端 Go + PostgreSQL + Redis
- **容器化部署**: Docker Compose 一键部署
- **高性能**: 异步处理和缓存优化
- **安全性**: JWT 认证、RBAC 权限控制
- **可扩展**: 微服务架构，支持水平扩展

## ⚡ 快速开始

### 一键部署

```bash
# 克隆项目
git clone https://github.com/your-username/mib-web-ui.git
cd mib-web-ui

# 一键部署
./deploy.sh
```

### 手动部署

```bash
# 启动服务
./start.sh

# 停止服务  
./stop.sh
```

### 访问应用

部署完成后，访问以下地址：

- **Web界面**: http://localhost:3000
- **数据库**: localhost:5432 (用户名: netmon_user, 密码: netmon_pass_2024)
- **Redis**: localhost:6379

## 📋 系统要求

### 最低配置
- **CPU**: 2核心
- **内存**: 4GB RAM
- **存储**: 20GB 可用空间
- **操作系统**: Ubuntu 22.04/24.04 LTS
- **架构**: AMD64 (x86_64) / ARM64 (aarch64) / ARMv7
- **网络**: 稳定的互联网连接

### 推荐配置
- **CPU**: 4核心或更多
- **内存**: 8GB RAM 或更多
- **存储**: 50GB SSD
- **操作系统**: Ubuntu 24.04 LTS
- **架构**: AMD64 (x86_64) / ARM64 (aarch64)
- **网络**: 千兆网络连接

### 支持的架构
| 架构 | 状态 | 说明 |
|------|------|------|
| AMD64 (x86_64) | ✅ 完全支持 | 推荐用于生产环境 |
| ARM64 (aarch64) | ✅ 完全支持 | 支持 Apple Silicon、ARM 服务器 |
| ARMv7 | ⚠️ 部分支持 | 性能受限，适用于轻量级部署 |

## 🛠️ 快速部署

### 方法一：多架构自动部署（推荐）

```bash
# 下载项目
git clone <your-repo-url>
cd web-ui

# 自动检测架构并部署
bash deploy-multiarch.sh
```

### 方法二：架构特定部署

#### AMD64 架构（标准部署）
```bash
# 标准部署脚本
bash deploy.sh
```

#### ARM64 架构（Apple Silicon / ARM 服务器）
```bash
# ARM64 优化部署
bash deploy-china.sh  # 包含 ARM64 支持
# 或使用多架构脚本
bash deploy-multiarch.sh
```

#### 国内服务器优化部署
```bash
# 使用国内优化脚本（支持多架构）
bash deploy-china.sh
```

### Docker 快速部署

```bash
# 克隆项目
git clone <repository-url>
cd web-ui

# 使用 Docker Compose 启动
docker-compose up -d
```

### 手动部署

```bash
# 安装依赖
npm install

# 构建项目
npm run build

# 启动服务
npm start
```

部署脚本将自动完成以下操作：
- 系统环境检查和依赖安装
- Docker 和 Docker Compose 安装
- 防火墙配置
- 应用构建和启动
- 系统服务配置
- 备份和管理脚本创建

### 手动部署

1. **安装 Docker 和 Docker Compose**
```bash
# 安装 Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# 安装 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

2. **配置环境变量**
```bash
cp .env.example .env
# 编辑 .env 文件，设置数据库密码等配置
```

3. **启动服务**
```bash
# 开发环境
docker-compose up -d

# 生产环境
docker-compose -f docker-compose.prod.yml up -d
```

## 🔧 配置说明

### 环境变量

主要配置项说明：

```bash
# 数据库配置
POSTGRES_DB=mibweb
POSTGRES_USER=mibweb
POSTGRES_PASSWORD=your_secure_password

# Redis 配置
REDIS_PASSWORD=your_redis_password

# 应用配置
JWT_SECRET=your_jwt_secret
CORS_ORIGINS=http://localhost:3000,https://yourdomain.com

# SNMP 配置
SNMP_TIMEOUT=5
SNMP_RETRIES=3
SNMP_MAX_REPETITIONS=10
```

### 端口配置

- **前端**: 3000 (HTTP)
- **后端 API**: 8080 (HTTP)
- **Nginx**: 80 (HTTP), 443 (HTTPS)
- **PostgreSQL**: 5432 (内部)
- **Redis**: 6379 (内部)

## 📱 使用指南

### 访问应用

部署完成后，可通过以下地址访问：

- **Web 界面**: http://your-server-ip:3000
- **API 文档**: http://your-server-ip:8080/docs
- **健康检查**: http://your-server-ip:8080/health

### 基本操作

1. **上传 MIB 文件**
   - 访问 "MIB 管理" 页面
   - 点击 "上传 MIB" 按钮
   - 选择 MIB 文件并上传

2. **添加设备**
   - 访问 "设备管理" 页面
   - 点击 "添加设备" 按钮
   - 填写设备信息和 SNMP 凭据

3. **执行 SNMP 操作**
   - 访问 "SNMP 工具" 页面
   - 选择操作类型（Get/Walk/Set）
   - 输入目标设备和 OID
   - 执行操作并查看结果

## 🛡️ 安全配置

### SSL/TLS 配置

1. **获取 SSL 证书**
```bash
# 使用 Let's Encrypt
sudo apt install certbot
sudo certbot certonly --standalone -d yourdomain.com
```

2. **配置 Nginx**
```bash
# 编辑 nginx/conf.d/mibweb.conf
# 取消注释 HTTPS 配置部分
# 更新证书路径
```

### 防火墙配置

```bash
# 基本防火墙规则（部署脚本已自动配置）
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### 安全建议

- 定期更新系统和依赖包
- 使用强密码和 JWT 密钥
- 启用 HTTPS 和 HSTS
- 配置适当的 CORS 策略
- 定期备份数据
- 监控系统日志

## 📊 管理和维护

### 管理命令

部署完成后，可使用 `mibweb` 命令进行管理：

```bash
# 启动服务
mibweb start

# 停止服务
mibweb stop

# 重启服务
mibweb restart

# 查看状态
mibweb status

# 查看日志
mibweb logs [service]

# 创建备份
mibweb backup

# 更新应用
mibweb update

# 健康检查
mibweb health

# 清理资源
mibweb clean
```

### 备份和恢复

**自动备份**
- 系统每天凌晨 2:00 自动创建备份
- 备份保存在 `/opt/mibweb-backups/`
- 自动清理 7 天前的备份

**手动备份**
```bash
# 创建备份
mibweb backup

# 查看备份文件
ls -la /opt/mibweb-backups/
```

**恢复数据**
```bash
# 恢复数据库
docker-compose exec postgres psql -U mibweb -d mibweb < /path/to/backup.sql

# 恢复 Redis 数据
docker-compose exec redis redis-cli --rdb /path/to/backup.rdb
```

### 日志管理

**查看日志**
```bash
# 查看所有服务日志
mibweb logs

# 查看特定服务日志
mibweb logs backend
mibweb logs frontend
mibweb logs postgres
mibweb logs redis

# 查看系统日志
sudo journalctl -u mibweb.service
```

**日志轮转**
- Docker 容器日志自动轮转（最大 10MB，保留 3 个文件）
- 应用日志每周自动清理（保留 7 天）

### 性能监控

**系统资源监控**
```bash
# 查看容器资源使用
docker stats

# 查看系统资源
htop

# 查看磁盘使用
df -h
```

**应用监控**
- 健康检查端点：`/health`
- 指标端点：`/metrics`（如果启用）
- 数据库连接池状态
- Redis 缓存命中率

## 🔧 故障排除

### 常见问题

**1. 服务启动失败**
```bash
# 检查服务状态
mibweb status

# 查看错误日志
mibweb logs

# 检查端口占用
sudo netstat -tlnp | grep :3000
sudo netstat -tlnp | grep :8080
```

**2. 数据库连接失败**
```bash
# 检查数据库状态
docker-compose exec postgres pg_isready -U mibweb

# 查看数据库日志
mibweb logs postgres

# 重启数据库
docker-compose restart postgres
```

**3. 前端无法访问后端**
```bash
# 检查网络连接
curl http://localhost:8080/health

# 检查 CORS 配置
# 编辑 .env 文件中的 CORS_ORIGINS
```

**4. MIB 文件上传失败**
```bash
# 检查上传目录权限
ls -la /opt/mibweb/uploads/

# 检查文件大小限制
# 编辑 nginx/conf.d/mibweb.conf 中的 client_max_body_size
```

### 性能优化

**1. 数据库优化**
```sql
-- 分析查询性能
EXPLAIN ANALYZE SELECT * FROM mibs WHERE name LIKE '%cisco%';

-- 重建索引
REINDEX DATABASE mibweb;

-- 更新统计信息
ANALYZE;
```

**2. Redis 优化**
```bash
# 查看 Redis 信息
docker-compose exec redis redis-cli info

# 清理过期键
docker-compose exec redis redis-cli FLUSHEXPIRED
```

**3. 应用优化**
- 调整 Go 应用的 GOMAXPROCS
- 优化数据库连接池大小
- 启用 Gzip 压缩
- 配置 CDN（如果需要）

## 📚 文档

### 🚀 部署文档
- [**📖 完整部署指南**](DEPLOYMENT-GUIDE.md) - 🌟 **最新！详尽的在线/离线部署手册**
- [部署指南](DEPLOYMENT.md) - 基础部署说明
- [离线部署](OFFLINE-DEPLOYMENT.md) - 离线环境部署指南
- [快速上手](QUICK-OFFLINE-GUIDE.md) - 快速部署指南

### 🛠️ 开发文档
- [**🎯 项目完善计划**](PROJECT-ENHANCEMENT-PLAN.md) - 🌟 **功能增强与优化路线图**
- [**📊 项目状态总览**](PROJECT-STATUS.md) - 🌟 **实时项目进度和质量指标**
- [**📋 版本更新日志**](CHANGELOG.md) - 🌟 **版本历史和更新内容**
- [API 文档](docs/API.md) - API 接口说明
- [开发指南](docs/DEVELOPMENT.md) - 开发环境搭建

## 🤝 开发指南

### 本地开发环境

**前端开发**
```bash
cd frontend
npm install
npm run dev
```

**后端开发**
```bash
cd backend
go mod download
go run main.go
```

**数据库迁移**
```bash
# 运行迁移
go run migrate.go up

# 回滚迁移
go run migrate.go down
```

### API 文档

- **Swagger UI**: http://localhost:8080/docs
- **API 规范**: `/docs/api.yaml`

### 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 创建 Pull Request

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 📞 支持

如有问题或建议，请：

1. 查看本文档的故障排除部分
2. 搜索已有的 Issues
3. 创建新的 Issue
4. 联系技术支持

## 🔄 更新日志

### v1.0.0 (2025-06-09)
- 初始版本发布
- 基础 MIB 管理功能
- SNMP 操作支持
- 设备管理功能
- Docker 容器化部署
- Ubuntu 22.04/24.04 支持

---

**注意**: 本项目仍在积极开发中，功能和 API 可能会发生变化。建议在生产环境使用前进行充分测试。