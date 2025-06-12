# 部署配置修改详尽手册

本手册详细说明了在服务器部署时必须修改的所有配置文件和参数。每个配置项都提供了文件路径链接，方便快速定位和修改。

## 📋 配置检查清单

### ✅ 必须修改的配置
- [ ] 数据库密码
- [ ] Redis 密码
- [ ] JWT 密钥
- [ ] 服务器域名/IP
- [ ] SSL 证书（生产环境）
- [ ] 管理员账户

### ⚠️ 建议修改的配置
- [ ] 日志级别
- [ ] 缓存配置
- [ ] 安全策略
- [ ] 性能参数

---

## 🔧 核心配置文件

### 1. 环境变量配置

**文件位置**: [`.env`](file://.env)

> 📝 **操作**: 复制 `.env.example` 为 `.env` 并修改以下配置

```bash
cp .env.example .env
```

#### 🔐 安全配置（必须修改）

```bash
# JWT 密钥 - 必须修改为强密码
# 说明：用于签名和验证 JWT 令牌，至少32字符，建议使用随机生成的字符串
# 生成方法：openssl rand -base64 32
# 示例：JWT_SECRET=AbCdEf1234567890aBcDeF1234567890AbCdEf12
JWT_SECRET=your_super_secret_jwt_key_at_least_32_characters_long

# 会话密钥 - 必须修改
# 说明：用于加密用户会话数据，建议24字符以上
# 生成方法：openssl rand -base64 24
# 示例：SESSION_SECRET=XyZ789aBcDeF123456XyZ789
SESSION_SECRET=your_session_secret_key_here

# 数据库密码 - 必须修改
# 说明：PostgreSQL 数据库的用户密码，建议包含大小写字母、数字和特殊字符
# 要求：至少8位，包含大小写字母和数字
# 示例：POSTGRES_PASSWORD=MySecureDB2024!
POSTGRES_PASSWORD=your_secure_postgres_password_here

# Redis 密码 - 必须修改
# 说明：Redis 缓存服务的访问密码
# 要求：至少8位，避免使用常见密码
# 示例：REDIS_PASSWORD=RedisCache2024#
REDIS_PASSWORD=your_secure_redis_password_here
```

#### 🌐 服务器配置（必须修改）

```bash
# API 基础 URL - 修改为实际服务器地址
# 说明：前端访问后端 API 的地址，必须是可访问的 IP 或域名
# 格式：http://IP地址:端口 或 https://域名:端口
# 示例：NEXT_PUBLIC_API_URL=http://192.168.1.100:8080
# 示例：NEXT_PUBLIC_API_URL=https://api.yourdomain.com:8080
NEXT_PUBLIC_API_URL=http://your-server-ip:8080

# 前端 URL - 修改为实际服务器地址
# 说明：前端应用的访问地址，用于 CORS 和重定向
# 格式：http://IP地址:端口 或 https://域名:端口
# 示例：FRONTEND_URL=http://192.168.1.100:3000
# 示例：FRONTEND_URL=https://monitor.yourdomain.com
FRONTEND_URL=http://your-server-ip:3000

# CORS 配置 - 添加实际域名
# 说明：允许跨域访问的源地址列表，多个地址用逗号分隔
# 格式：地址1,地址2,地址3（不要有空格）
# 示例：CORS_ORIGINS=http://192.168.1.100:3000,https://monitor.yourdomain.com
CORS_ORIGINS=http://your-domain.com,http://your-server-ip:3000
```

#### 📊 数据库配置

```bash
# 数据库连接
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=network_monitor
POSTGRES_USER=netmon_user

# 连接池配置（可选调整）
DB_MAX_OPEN_CONNS=25
DB_MAX_IDLE_CONNS=5
```

---

### 2. Docker Compose 配置

**文件位置**: [`docker-compose.yml`](file://docker-compose.yml)

#### 🔐 数据库密码（必须修改）

**行号**: 9-11
```yaml
environment:
  POSTGRES_DB: network_monitor
  POSTGRES_USER: netmon_user
  # 修改此密码 - 必须与 .env 文件中的 POSTGRES_PASSWORD 保持一致
  # 说明：数据库用户的登录密码，建议使用强密码
  # 要求：至少8位，包含大小写字母、数字和特殊字符
  # 示例：POSTGRES_PASSWORD: "MySecureDB2024!"
  POSTGRES_PASSWORD: netmon_pass_2024
```

#### 🔐 Redis 密码（必须修改）

**行号**: 32
```yaml
# 修改此密码 - 必须与 .env 文件中的 REDIS_PASSWORD 保持一致
# 说明：Redis 服务的访问密码，用于保护缓存数据
# 要求：至少8位，避免使用简单密码
# 示例：command: redis-server /usr/local/etc/redis/redis.conf --requirepass "RedisCache2024#"
command: redis-server /usr/local/etc/redis/redis.conf --requirepass redis_pass_2024
```

#### 🌐 端口配置（可选修改）

```yaml
# PostgreSQL 端口
ports:
  - "5432:5432"  # 可修改为其他端口

# Redis 端口
ports:
  - "6379:6379"  # 可修改为其他端口

# 前端端口
ports:
  - "3000:3000"  # 可修改为其他端口

# 后端端口
ports:
  - "8080:8080"  # 可修改为其他端口

# Nginx 端口
ports:
  - "80:80"      # HTTP 端口
  - "443:443"    # HTTPS 端口（需要 SSL 证书）
```

---

### 3. Nginx 配置

**文件位置**: [`nginx/nginx.conf`](file://nginx/nginx.conf)

#### 🌐 服务器名称（必须修改）

**行号**: 33
```nginx
server {
    listen 80;
    # 修改为实际域名或 IP 地址
    # 说明：客户端访问时使用的域名或 IP 地址
    # 域名示例：server_name monitor.yourdomain.com;
    # IP 示例：server_name 192.168.1.100;
    # 多域名示例：server_name monitor.yourdomain.com www.monitor.yourdomain.com;
    server_name your-domain.com;
```

#### 🔒 SSL 配置（生产环境必须）

在 `server` 块中添加：
```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
}
```

#### ⚡ 性能优化（可选）

**行号**: 13-14
```nginx
# 速率限制
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;    # 可调整 API 请求频率
limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;   # 可调整登录请求频率
```

---

### 4. Redis 配置

**文件位置**: [`redis/redis.conf`](file://redis/redis.conf)

#### 💾 内存配置（建议修改）

**行号**: 7-8
```conf
# 内存配置
# 说明：Redis 最大使用内存，建议设置为服务器内存的 25-50%
# 计算方法：服务器总内存 × 0.25 到 0.5
# 示例：4GB 服务器设置为 1gb，8GB 服务器设置为 2gb
# 格式：数字+单位(mb/gb)，如：1gb, 2048mb
maxmemory 512mb

# 内存淘汰策略
# 说明：当内存不足时的数据清理策略
# allkeys-lru: 删除最近最少使用的键（推荐）
# allkeys-lfu: 删除最少使用频率的键
# volatile-lru: 只删除设置了过期时间的最近最少使用键
maxmemory-policy allkeys-lru
```

#### 🔐 安全配置

**行号**: 18-20
```conf
# 安全配置
protected-mode yes
# requirepass 在 docker-compose 中设置
```

---

### 5. 数据库初始化

**文件位置**: [`database/init/01-init.sql`](file://database/init/01-init.sql)

#### 👤 默认管理员账户（建议修改）

在数据库初始化后，需要创建管理员账户：

```sql
-- 插入默认管理员用户
INSERT INTO users (email, name, password_hash, role, is_active) 
VALUES (
    'admin@yourdomain.com',           -- 修改邮箱
    'System Administrator',            -- 修改名称
    '$2a$10$...',                     -- 使用 bcrypt 加密的密码
    'admin', 
    true
);
```

---

## 🚀 部署步骤

### 1. 准备配置文件

```bash
# 1. 复制环境变量文件
cp .env.example .env

# 2. 编辑配置文件
vim .env                    # 修改环境变量
vim docker-compose.yml      # 修改 Docker 配置
vim nginx/nginx.conf        # 修改 Nginx 配置
```

### 2. 生成安全密钥

```bash
# 生成 JWT 密钥（32字符以上）
# 说明：生成用于 JWT 令牌签名的随机密钥
openssl rand -base64 32

# 生成会话密钥
# 说明：生成用于会话加密的随机密钥
openssl rand -base64 24

# 生成数据库密码
# 说明：生成随机数据库密码（可选，也可以手动设置）
openssl rand -base64 16

# 生成 Redis 密码
# 说明：生成随机 Redis 密码
openssl rand -base64 16

# 批量生成所有密钥（推荐）
echo "JWT_SECRET=$(openssl rand -base64 32)"
echo "SESSION_SECRET=$(openssl rand -base64 24)"
echo "POSTGRES_PASSWORD=$(openssl rand -base64 16)"
echo "REDIS_PASSWORD=$(openssl rand -base64 16)"
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
# 检查服务健康状态
curl http://localhost:8080/health
curl http://localhost:3000

# 检查数据库连接
docker-compose exec postgres psql -U netmon_user -d network_monitor -c "\dt"
```

---

## 🔍 故障排除

### 常见问题

1. **数据库连接失败**
   - 检查 `.env` 中的数据库密码是否与 `docker-compose.yml` 一致
   - 确认数据库容器已启动：`docker-compose ps postgres`

2. **Redis 连接失败**
   - 检查 Redis 密码配置
   - 确认 Redis 容器状态：`docker-compose ps redis`

3. **前端无法访问后端**
   - 检查 `NEXT_PUBLIC_API_URL` 配置
   - 确认防火墙设置

4. **SSL 证书问题**
   - 确认证书文件路径正确
   - 检查证书有效期

### 日志查看

```bash
# 查看所有服务日志
docker-compose logs

# 查看特定服务日志
docker-compose logs frontend
docker-compose logs backend
docker-compose logs postgres
docker-compose logs redis
docker-compose logs nginx
```

---

## 📚 配置文件快速导航

| 配置类型 | 文件路径 | 主要用途 |
|---------|----------|----------|
| 环境变量 | [`.env`](file://.env) | 应用程序配置 |
| 容器编排 | [`docker-compose.yml`](file://docker-compose.yml) | 服务定义和网络 |
| 反向代理 | [`nginx/nginx.conf`](file://nginx/nginx.conf) | 负载均衡和SSL |
| 缓存配置 | [`redis/redis.conf`](file://redis/redis.conf) | Redis 性能调优 |
| 数据库初始化 | [`database/init/01-init.sql`](file://database/init/01-init.sql) | 数据库结构 |
| 应用构建 | [`Dockerfile`](file://Dockerfile) | 容器镜像构建 |

---

## ⚠️ 安全提醒

1. **密码安全**：所有默认密码必须修改
2. **密钥管理**：JWT 密钥至少 32 字符
3. **网络安全**：生产环境必须使用 HTTPS
4. **访问控制**：配置防火墙规则
5. **定期更新**：及时更新依赖和镜像

---

## 📞 技术支持

如果在配置过程中遇到问题，请：

1. 查看相关日志文件
2. 检查配置文件语法
3. 确认网络连接
4. 验证权限设置

**配置完成后，请保存此手册以备后续维护使用。**