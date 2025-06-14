# 🚀 SNMP MIB Web Platform

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Go Version](https://img.shields.io/badge/Go-1.23+-blue.svg)](https://golang.org/)
[![Next.js](https://img.shields.io/badge/Next.js-14+-black.svg)](https://nextjs.org/)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey.svg)](https://github.com/Oumu33/snmp-mib-ui)

**现代化的 SNMP MIB 管理和网络监控平台**

[🚀 快速开始](#-快速开始) • [📖 文档](#-文档) • [🎯 功能特性](#-功能特性) • [🛠️ 部署指南](#️-部署指南) • [🤝 贡献](#-贡献)

</div>

---

## 📋 项目简介

SNMP MIB Web Platform 是一个现代化的网络设备管理和监控平台，专为网络工程师和系统管理员设计。平台提供直观的 Web 界面来管理 MIB 文件、配置 SNMP 监控、生成配置文件，并支持多种监控工具集成。

### ✨ 核心亮点

- 🎯 **一站式 MIB 管理** - 上传、解析、搜索 MIB 文件，可视化 OID 树结构
- ⚙️ **智能配置生成** - 自动生成 Prometheus SNMP Exporter 和 Categraf 配置
- 🔧 **设备管理** - 统一管理网络设备和 SNMP 凭据
- 📊 **监控集成** - 内置 VictoriaMetrics + Grafana 监控栈
- 🐳 **容器化部署** - Docker Compose 一键部署，支持多架构
- 🌐 **现代化界面** - 基于 Next.js 14 的响应式 Web 界面

---

## 🎯 功能特性

### 🗂️ MIB 文件管理
- **文件上传与解析** - 支持多种 MIB 文件格式，自动解析 OID 结构
- **目录扫描** - 自动扫描 `/opt/monitoring/mibs` 目录中的 MIB 文件
- **OID 浏览器** - 可视化浏览和搜索 OID 树形结构
- **智能解析** - 集成 `snmptranslate` 工具，支持备用解析器

### ⚙️ 配置生成与管理
- **多格式支持** - 生成 YAML (SNMP Exporter) 和 TOML (Categraf) 配置
- **设备集成** - 结合设备信息和选定 OID 生成完整配置
- **配置预览** - 实时预览生成的配置文件
- **文件管理** - 保存、合并、查看现有配置文件

### 🖥️ 设备管理
- **设备信息管理** - IP、Community、SNMP 版本等信息管理
- **批量操作** - 支持批量添加和配置设备
- **连接测试** - SNMP 连通性测试和验证
- **模板支持** - 设备配置模板和快速部署

### 📊 监控与告警
- **监控栈集成** - VictoriaMetrics、Grafana、Alertmanager
- **告警规则** - 智能告警规则配置和管理
- **实时监控** - 设备状态和性能指标实时监控
- **数据分析** - 网络设备性能分析和报表

---

## 🚀 快速开始

### 📦 一键部署

```bash
# 克隆项目
git clone https://github.com/Oumu33/snmp-mib-ui.git
cd snmp-mib-ui

# 启动服务
docker-compose up -d
```

### 🌐 访问应用

部署完成后，访问以下地址：

| 服务 | 地址 | 说明 |
|------|------|------|
| 🌐 **Web 界面** | http://localhost:3000 | 主要管理界面 |
| 🔧 **后端 API** | http://localhost:8080 | RESTful API |
| 📊 **健康检查** | http://localhost:8080/health | 服务状态检查 |

---

## 🛠️ 部署指南

### 📋 系统要求

| 配置项 | 最低要求 | 推荐配置 |
|--------|----------|----------|
| **CPU** | 2 核心 | 4 核心+ |
| **内存** | 4GB RAM | 8GB RAM+ |
| **存储** | 20GB | 50GB SSD |
| **系统** | Ubuntu 22.04+ | Ubuntu 24.04 LTS |
| **架构** | AMD64/ARM64 | AMD64 |

### 🐳 Docker 部署（推荐）

```bash
# 1. 克隆项目
git clone https://github.com/Oumu33/snmp-mib-ui.git
cd snmp-mib-ui

# 2. 配置环境变量（可选）
cp .env.example .env
# 编辑 .env 文件设置数据库密码等

# 3. 启动服务
docker-compose up -d

# 4. 查看服务状态
docker-compose ps
```

### 🔧 手动部署

<details>
<summary>点击展开手动部署步骤</summary>

**前端部署**
```bash
# 安装依赖
npm install

# 构建项目
npm run build

# 启动服务
npm start
```

**后端部署**
```bash
cd backend

# 安装 Go 依赖
go mod download

# 编译项目
go build -o mib-platform .

# 启动服务
./mib-platform
```

**数据库配置**
```bash
# 安装 PostgreSQL
sudo apt install postgresql postgresql-contrib

# 创建数据库和用户
sudo -u postgres createdb network_monitor
sudo -u postgres createuser netmon_user
```

</details>

### 🌍 监控栈部署

```bash
# 部署完整监控栈
docker-compose -f docker-compose.monitoring.yml up -d

# 访问监控服务
# Grafana: http://localhost:3001 (admin/admin)
# VictoriaMetrics: http://localhost:8428
# Alertmanager: http://localhost:9093
```

---

## 📖 文档

### 📚 用户文档
- [📖 **完整部署指南**](DEPLOYMENT_GUIDE.md) - 详细的部署和配置说明
- [🚀 **快速开始指南**](docs/quick-start.md) - 5分钟快速上手
- [🔧 **配置说明**](docs/configuration.md) - 详细配置参数说明
- [🛠️ **故障排除**](docs/troubleshooting.md) - 常见问题解决方案

### 🔧 开发文档
- [🏗️ **系统架构**](docs/system-architecture.md) - 系统设计和架构说明
- [📡 **API 文档**](docs/API.md) - RESTful API 接口说明
- [🧪 **开发指南**](docs/DEVELOPMENT.md) - 本地开发环境搭建
- [📊 **性能基准**](docs/performance-benchmarks.md) - 性能测试和优化

### 📋 项目文档
- [📝 **项目总结**](PROJECT_SUMMARY.md) - 项目功能和技术栈总览
- [📅 **更新日志**](CHANGELOG.md) - 版本历史和更新内容
- [🤝 **贡献指南**](CONTRIBUTING.md) - 如何参与项目贡献

---

## 🏗️ 技术架构

### 🔧 技术栈

| 层级 | 技术 | 版本 | 说明 |
|------|------|------|------|
| **前端** | Next.js + React + TypeScript | 14+ | 现代化 Web 界面 |
| **后端** | Go + Gin 框架 | 1.23+ | 高性能 API 服务 |
| **数据库** | PostgreSQL + Redis | 15+ / 7+ | 数据存储和缓存 |
| **监控** | VictoriaMetrics + Grafana | Latest | 监控和可视化 |
| **部署** | Docker + Docker Compose | Latest | 容器化部署 |

### 🏛️ 系统架构

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Frontend  │    │   Backend API   │    │   Monitoring    │
│   (Next.js)     │◄──►│   (Go + Gin)    │◄──►│  (VictoriaM)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                       ┌────────┴────────┐
                       │                 │
                ┌──────▼──────┐   ┌──────▼──────┐
                │ PostgreSQL  │   │    Redis    │
                │ (主数据库)   │   │   (缓存)     │
                └─────────────┘   └─────────────┘
```

---

## 🧪 测试与验证

### ✅ 自动化测试

项目包含完整的自动化测试套件：

```bash
# 运行平台测试
./test_platform.sh

# 测试结果示例
🚀 开始测试 SNMP MIB Platform...
✓ 健康检查通过
✓ MIB 管理功能正常
✓ 配置生成功能正常
✓ 设备管理功能正常
总测试数: 9 | 通过: 9 | 失败: 0
```

### 📊 测试覆盖

- ✅ **API 端点测试** - 所有 REST API 接口
- ✅ **数据库连接** - PostgreSQL 和 Redis 连接
- ✅ **文件操作** - MIB 文件上传和解析
- ✅ **配置生成** - SNMP Exporter 和 Categraf 配置
- ✅ **健康检查** - 服务状态监控

---

## 🤝 贡献

我们欢迎所有形式的贡献！

### 🔧 开发环境

```bash
# 1. Fork 项目
git clone https://github.com/your-username/snmp-mib-ui.git

# 2. 创建功能分支
git checkout -b feature/your-feature-name

# 3. 本地开发
npm run dev          # 前端开发
cd backend && go run main.go  # 后端开发

# 4. 提交更改
git commit -m "feat: add your feature"
git push origin feature/your-feature-name

# 5. 创建 Pull Request
```

### 📝 贡献指南

- 🐛 **Bug 报告** - 使用 Issue 模板报告问题
- 💡 **功能建议** - 提出新功能想法和改进建议
- 📖 **文档改进** - 完善文档和示例
- 🧪 **测试用例** - 添加测试用例和性能测试
- 🔧 **代码贡献** - 修复 Bug 和实现新功能

---

## 📄 许可证

本项目采用 [MIT 许可证](LICENSE)。

---

## 📞 支持与反馈

### 🆘 获取帮助

- 📖 **文档** - 查看 [完整文档](docs/)
- 🐛 **问题报告** - 创建 [GitHub Issue](https://github.com/Oumu33/snmp-mib-ui/issues)
- 💬 **讨论** - 参与 [GitHub Discussions](https://github.com/Oumu33/snmp-mib-ui/discussions)
- 📧 **联系** - 发送邮件至项目维护者

### 🌟 项目状态

- ✅ **核心功能** - 已完成并测试
- 🔄 **持续改进** - 定期更新和优化
- 📈 **活跃维护** - 及时响应问题和建议
- 🚀 **生产就绪** - 可用于生产环境

---

<div align="center">

**⭐ 如果这个项目对您有帮助，请给我们一个 Star！**

[⬆️ 回到顶部](#-snmp-mib-web-platform)

</div>