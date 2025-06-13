#!/bin/bash

# 生产环境部署脚本
# 使用方法: ./deploy-production.sh YOUR_SERVER_IP

if [ $# -eq 0 ]; then
    echo "❌ 请提供服务器IP地址"
    echo "使用方法: ./deploy-production.sh 101.33.248.167"
    exit 1
fi

SERVER_IP=$1
echo "🚀 为服务器 $SERVER_IP 部署 SNMP Web UI..."

# 更新环境变量
cat > .env << EOF
# 数据库配置
POSTGRES_DB=network_monitor
POSTGRES_USER=netmon_user
POSTGRES_PASSWORD=netmon_pass_2024

# Redis配置
REDIS_PASSWORD=redis_pass_2024

# 应用配置
NODE_ENV=production
NEXTAUTH_SECRET=mibweb_secret_key_2024_very_secure
NEXTAUTH_URL=http://$SERVER_IP:3000

# JWT配置
JWT_SECRET=jwt_secret_key_2024_very_secure

# CORS配置
CORS_ORIGINS=http://$SERVER_IP:3000,http://$SERVER_IP

# 端口配置
FRONTEND_PORT=3000
BACKEND_PORT=8080
POSTGRES_PORT=5432
REDIS_PORT=6379
EOF

# 更新 docker-compose.yml 中的 NEXTAUTH_URL
sed -i "s|NEXTAUTH_URL=.*|NEXTAUTH_URL=http://$SERVER_IP:3000|g" docker-compose.yml

echo "✅ 环境配置已更新为: $SERVER_IP:3000"

# 检查防火墙
echo "🔥 检查防火墙配置..."
if command -v ufw &> /dev/null; then
    echo "检查 ufw 防火墙状态..."
    sudo ufw status | grep 3000 || echo "⚠️  端口 3000 未开放，请运行: sudo ufw allow 3000"
fi

if command -v firewall-cmd &> /dev/null; then
    echo "检查 firewalld 防火墙状态..."
    sudo firewall-cmd --list-ports | grep 3000 || echo "⚠️  端口 3000 未开放，请运行: sudo firewall-cmd --permanent --add-port=3000/tcp && sudo firewall-cmd --reload"
fi

# 启动服务
echo "🐳 启动 Docker 服务..."
docker-compose down
docker-compose up -d

echo "⏳ 等待服务启动..."
sleep 15

echo "📊 检查服务状态..."
docker-compose ps

echo ""
echo "🎉 部署完成！"
echo "===========================================" 
echo "🌐 访问地址: http://$SERVER_IP:3000"
echo "🗄️  数据库: $SERVER_IP:5432"
echo "📝 Redis: $SERVER_IP:6379"
echo "==========================================="
echo ""
echo "💡 重要提醒:"
echo "1. 确保防火墙已开放 3000 端口"
echo "2. 确保云服务器安全组已开放 3000 端口"
echo "3. 如果访问不了，请检查网络配置"
echo ""