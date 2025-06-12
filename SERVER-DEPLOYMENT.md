# 服务器部署指南

本指南专门用于在服务器上部署 MIB 监控平台。

## 系统要求

- Docker 20.10+
- Docker Compose 2.0+
- 至少 2GB RAM
- 至少 10GB 磁盘空间

## 快速部署

### 1. 上传项目文件

将整个项目目录上传到服务器：

```bash
# 在本地打包
tar -czf mibweb-platform.tar.gz web-ui/

# 上传到服务器
scp mibweb-platform.tar.gz user@server:/opt/

# 在服务器上解压
cd /opt
tar -xzf mibweb-platform.tar.gz
cd web-ui
```

### 2. 配置环境

```bash
# 复制环境配置文件
cp .env.example .env

# 编辑配置（可选）
vim .env
```

### 3. 启动服务

```bash
# 启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 4. 验证部署

```bash
# 检查健康状态
./healthcheck.sh

# 访问应用
curl http://localhost:3000
```

## 可用的 Docker Compose 配置

- `docker-compose.yml` - 完整生产环境配置（推荐）
- `docker-compose.simple.yml` - 简化配置，适合测试

## 服务端口

- **Web UI**: 3000
- **后端 API**: 8080
- **PostgreSQL**: 5432
- **Redis**: 6379

## 常用命令

```bash
# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 更新服务
docker-compose pull
docker-compose up -d

# 查看资源使用
docker stats

# 清理未使用的镜像
docker system prune -f
```

## 故障排除

### 端口冲突

如果端口被占用，修改 `docker-compose.yml` 中的端口映射：

```yaml
ports:
  - "8080:3000"  # 将 Web UI 映射到 8080 端口
```

### 数据持久化

数据会自动保存在 Docker volumes 中：

```bash
# 查看数据卷
docker volume ls

# 备份数据
docker-compose exec postgres pg_dump -U netmon_user network_monitor > backup.sql
```

### 日志查看

```bash
# 查看特定服务日志
docker-compose logs app
docker-compose logs postgres
docker-compose logs redis

# 实时跟踪日志
docker-compose logs -f --tail=100
```

## 安全建议

1. 修改默认密码（在 `.env` 文件中）
2. 配置防火墙，只开放必要端口
3. 定期更新 Docker 镜像
4. 设置日志轮转

## 性能优化

1. 根据服务器配置调整 Docker 资源限制
2. 配置 Redis 持久化策略
3. 优化 PostgreSQL 配置
4. 设置适当的健康检查间隔