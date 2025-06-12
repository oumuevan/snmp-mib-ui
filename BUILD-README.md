# MIB 监控平台构建指南

## 概述

本项目提供了灵活的构建选项，支持两种构建模式：

- **基础版本**：仅包含 Web UI 和核心组件，监控组件可在界面中按需安装
- **完整版本**：预装所有监控组件，支持离线环境一键部署

## 构建选项

### 基础构建（推荐）

```bash
# 默认构建，仅包含 Web UI 和基础组件
bash build-local-deps.sh
```

**包含组件：**
- Web UI 前端应用
- Go 后端 API
- PostgreSQL 数据库
- Redis 缓存
- Nginx 反向代理

**优势：**
- 构建速度快
- 包体积小
- 监控组件可在 Web 界面中按需选择和安装
- 适合大多数使用场景

### 完整构建

```bash
# 包含所有监控组件的完整构建
bash build-local-deps.sh --include-monitoring
```

**额外包含的监控组件：**
- VictoriaMetrics（时序数据库）
- Grafana（数据可视化）
- Alertmanager（告警管理）
- Node Exporter（系统监控）
- Categraf（数据采集）
- VMAgent（数据代理）
- VMAlert（告警引擎）
- SNMP Exporter（网络设备监控）

**适用场景：**
- 完全离线环境部署
- 需要预装所有监控组件
- 企业级生产环境

## 其他构建选项

```bash
# 显示帮助信息
bash build-local-deps.sh --help

# 跳过 Docker 镜像构建
bash build-local-deps.sh --skip-docker

# 仅生成配置文件
bash build-local-deps.sh --config-only

# 详细输出
bash build-local-deps.sh --verbose

# 组合使用
bash build-local-deps.sh --include-monitoring --verbose
```

## 构建产物对比

| 构建模式 | 镜像数量 | 包大小（估算） | 构建时间 | 适用场景 |
|---------|---------|---------------|----------|----------|
| 基础版本 | ~5个 | ~500MB | 5-10分钟 | 一般部署、在线环境 |
| 完整版本 | ~13个 | ~2GB | 15-30分钟 | 离线部署、企业环境 |

## 部署说明

### 基础版本部署

1. 构建基础版本
2. 部署 Web UI 和基础组件
3. 在 Web 界面的"监控安装器"中按需选择和安装监控组件

### 完整版本部署

1. 构建完整版本
2. 一键部署所有组件
3. 直接使用完整的监控平台

## 监控组件说明

### 必需组件（自动包含）
- **Node Exporter**: 系统指标收集
- **VictoriaMetrics**: 时序数据库
- **Grafana**: 数据可视化

### 推荐组件
- **VMAgent**: 高效数据代理
- **VMAlert**: 智能告警引擎
- **Alertmanager**: 告警通知管理

### 可选组件
- **Categraf**: 多源数据采集
- **SNMP Exporter**: 网络设备监控

## 常见问题

**Q: 基础版本是否支持监控功能？**
A: 是的，基础版本包含完整的监控安装器界面，可以在部署后按需安装监控组件。

**Q: 如何选择构建模式？**
A: 
- 如果网络环境良好，推荐使用基础版本
- 如果是完全离线环境或需要预装所有组件，使用完整版本

**Q: 可以在基础版本上后续添加监控组件吗？**
A: 可以，通过 Web 界面的"监控安装器"模块可以随时安装所需的监控组件。

**Q: 构建失败怎么办？**
A: 
1. 检查网络连接
2. 确保 Docker 服务正在运行
3. 使用 `--verbose` 参数查看详细错误信息
4. 查看构建日志文件

## 技术支持

如有问题，请查看：
- [部署指南](./DEPLOYMENT-GUIDE.md)
- [快速开始](./docs/quick-start.md)
- [故障排除](./docs/troubleshooting.md)