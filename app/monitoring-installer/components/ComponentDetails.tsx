"use client"

import React, { useState } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Switch } from '@/components/ui/switch'
import { Slider } from '@/components/ui/slider'
import { Checkbox } from '@/components/ui/checkbox'
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group'
import { Separator } from '@/components/ui/separator'
import { 
  Download, 
  Settings, 
  Play, 
  CheckCircle, 
  AlertCircle, 
  Server, 
  Database, 
  BarChart3, 
  Bell, 
  Network, 
  Activity,
  RefreshCw,
  FileText,
  Zap,
  ExternalLink,
  Info,
  HelpCircle,
  Code,
  Terminal,
  Cpu,
  HardDrive,
  Wifi,
  Globe,
  Clock,
  Layers
} from 'lucide-react'

interface ComponentVersion {
  version: string
  releaseDate: string
  downloadUrl: string
  changelog: string
  isLatest: boolean
}

// 架构检测和下载链接生成
const getSystemArchitecture = (): string => {
  if (typeof window !== 'undefined') {
    const userAgent = window.navigator.userAgent.toLowerCase()
    if (userAgent.includes('arm64') || userAgent.includes('aarch64')) {
      return 'arm64'
    }
    if (userAgent.includes('armv7')) {
      return 'armv7'
    }
  }
  return 'amd64' // 默认架构
}

const generateDownloadUrl = (baseUrl: string, version: string, component: string, arch: string = getSystemArchitecture()): string => {
  // 根据不同组件和架构生成正确的下载链接
  const archMap: { [key: string]: string } = {
    'amd64': 'linux-amd64',
    'arm64': 'linux-arm64', 
    'armv7': 'linux-armv7'
  }
  
  const archSuffix = archMap[arch] || 'linux-amd64'
  
  // 特殊处理不同组件的命名规则
  switch (component) {
    case 'node_exporter':
      return `https://github.com/prometheus/node_exporter/releases/download/v${version}/node_exporter-${version}.${archSuffix}.tar.gz`
    case 'categraf':
      return `https://github.com/flashcatcloud/categraf/releases/download/v${version}/categraf-v${version}-${archSuffix}.tar.gz`
    case 'vmutils':
      return `https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${version}/vmutils-${archSuffix}-v${version}.tar.gz`
    case 'victoria-metrics':
      return `https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${version}/victoria-metrics-${archSuffix}-v${version}.tar.gz`
    case 'grafana':
      return `${baseUrl}grafana-${version}.${archSuffix}.tar.gz`
    case 'snmp_exporter':
      return `https://github.com/prometheus/snmp_exporter/releases/download/v${version}/snmp_exporter-${version}.${archSuffix}.tar.gz`
    case 'alertmanager':
      return `https://github.com/prometheus/alertmanager/releases/download/v${version}/alertmanager-${version}.${archSuffix}.tar.gz`
    default:
      return baseUrl
  }
}

interface MonitoringComponent {
  id: string
  name: string
  description: string
  category: 'collector' | 'storage' | 'visualization' | 'alerting'
  versions: ComponentVersion[]
  defaultPort: number
  configurable: boolean
  dependencies: string[]
  features: string[]
  documentation: string
  requirements: {
    cpu: string
    memory: string
    disk: string
  }
}

// 模拟组件配置数据
export const COMPONENT_CONFIGS: Record<string, MonitoringComponent> = {
  'node-exporter': {
    id: 'node-exporter',
    name: 'Node Exporter',
    description: '系统指标采集器，收集CPU、内存、磁盘等系统指标',
    category: 'collector',
    versions: [
      { 
        version: '1.7.0', 
        releaseDate: '2023-12-15', 
        downloadUrl: generateDownloadUrl('', '1.7.0', 'node_exporter'),
        changelog: '- 新增网络接口监控指标\n- 修复磁盘IO统计问题\n- 性能优化',
        isLatest: true
      },
      { 
        version: '1.6.1', 
        releaseDate: '2023-10-10', 
        downloadUrl: generateDownloadUrl('', '1.6.1', 'node_exporter'),
        changelog: '- 修复内存统计问题\n- 改进CPU使用率计算',
        isLatest: false
      },
      { 
        version: '1.6.0', 
        releaseDate: '2023-09-01', 
        downloadUrl: generateDownloadUrl('', '1.6.0', 'node_exporter'),
        changelog: '- 新增文件系统监控\n- 支持更多Linux内核指标',
        isLatest: false
      }
    ],
    defaultPort: 9100,
    configurable: false,
    dependencies: [],
    features: ['系统负载监控', 'CPU使用率', '内存使用率', '磁盘使用率', '网络流量'],
    documentation: 'https://github.com/prometheus/node_exporter',
    requirements: {
      cpu: '1 core',
      memory: '64MB',
      disk: '20MB'
    }
  },
  'categraf': {
    id: 'categraf',
    name: 'Categraf',
    description: '多功能指标采集器，支持多种数据源',
    category: 'collector',
    versions: [
      { 
        version: '0.3.60', 
        releaseDate: '2024-01-10', 
        downloadUrl: generateDownloadUrl('', '0.3.60', 'categraf'),
        changelog: '- 新增Kafka采集插件\n- 改进MySQL监控\n- 修复日志轮转问题',
        isLatest: true
      },
      { 
        version: '0.3.59', 
        releaseDate: '2023-12-20', 
        downloadUrl: generateDownloadUrl('', '0.3.59', 'categraf'),
        changelog: '- 新增Redis监控模块\n- 优化配置加载性能',
        isLatest: false
      },
      { 
        version: '0.3.58', 
        releaseDate: '2023-12-01', 
        downloadUrl: generateDownloadUrl('', '0.3.58', 'categraf'),
        changelog: '- 支持更多协议\n- 修复内存泄漏问题',
        isLatest: false
      }
    ],
    defaultPort: 9100,
    configurable: true,
    dependencies: [],
    features: ['多协议支持', '插件化架构', '低资源占用', '高性能', '配置热加载'],
    documentation: 'https://github.com/flashcatcloud/categraf',
    requirements: {
      cpu: '1 core',
      memory: '128MB',
      disk: '50MB'
    }
  },
  'vmagent': {
    id: 'vmagent',
    name: 'VMAgent',
    description: '轻量级指标代理，负责指标收集和转发',
    category: 'collector',
    versions: [
      { 
        version: '1.96.0', 
        releaseDate: '2024-01-15', 
        downloadUrl: generateDownloadUrl('', '1.96.0', 'vmutils'),
        changelog: '- 提高数据压缩率\n- 改进服务发现机制\n- 新增Prometheus兼容API',
        isLatest: true
      },
      { 
        version: '1.95.1', 
        releaseDate: '2023-12-20', 
        downloadUrl: generateDownloadUrl('', '1.95.1', 'vmutils'),
        changelog: '- 修复高并发下的稳定性问题\n- 优化内存使用',
        isLatest: false
      },
      { 
        version: '1.95.0', 
        releaseDate: '2023-12-10', 
        downloadUrl: generateDownloadUrl('', '1.95.0', 'vmutils'),
        changelog: '- 新增远程写入功能\n- 支持多种服务发现机制',
        isLatest: false
      }
    ],
    defaultPort: 8429,
    configurable: true,
    dependencies: ['victoriametrics'],
    features: ['高性能', '低资源消耗', '数据压缩', '服务发现', '远程写入'],
    documentation: 'https://docs.victoriametrics.com/vmagent.html',
    requirements: {
      cpu: '2 cores',
      memory: '512MB',
      disk: '100MB'
    }
  },
  'victoriametrics': {
    id: 'victoriametrics',
    name: 'VictoriaMetrics',
    description: 'VictoriaMetrics单机版，高性能时序数据库，适合中小规模部署',
    category: 'storage',
    versions: [
      { 
        version: '1.96.0', 
        releaseDate: '2024-01-15', 
        downloadUrl: generateDownloadUrl('', '1.96.0', 'victoria-metrics'),
        changelog: '- 改进查询性能\n- 新增数据压缩算法\n- 修复内存使用问题',
        isLatest: true
      },
      { 
        version: '1.95.1', 
        releaseDate: '2023-12-20', 
        downloadUrl: generateDownloadUrl('', '1.95.1', 'victoria-metrics'),
        changelog: '- 修复查询bug\n- 优化存储引擎',
        isLatest: false
      },
      { 
        version: '1.95.0', 
        releaseDate: '2023-12-01', 
        downloadUrl: generateDownloadUrl('', '1.95.0', 'victoria-metrics'),
        changelog: '- 新增流式聚合\n- 改进HTTP API',
        isLatest: false
      }
    ],
    defaultPort: 8428,
    configurable: true,
    dependencies: [],
    features: ['高性能存储', 'PromQL兼容', '数据压缩', '快速查询', '低资源占用', '单机部署'],
    documentation: 'https://docs.victoriametrics.com/',
    requirements: {
      cpu: '2 cores',
      memory: '1GB',
      disk: '10GB'
    }
  },
  'vmstorage': {
    id: 'vmstorage',
    name: 'VMStorage',
    description: 'VictoriaMetrics集群存储节点，负责数据持久化存储',
    category: 'storage',
    versions: [
      { 
        version: '1.96.0', 
        releaseDate: '2024-01-15', 
        downloadUrl: generateDownloadUrl('', '1.96.0', 'victoria-metrics'),
        changelog: '- 提高存储性能\n- 优化数据压缩\n- 支持动态扩容',
        isLatest: true
      },
      { 
        version: '1.95.1', 
        releaseDate: '2023-12-20', 
        downloadUrl: generateDownloadUrl('', '1.95.1', 'victoria-metrics'),
        changelog: '- 修复存储稳定性问题\n- 优化内存使用',
        isLatest: false
      },
      { 
        version: '1.95.0', 
        releaseDate: '2023-12-10', 
        downloadUrl: generateDownloadUrl('', '1.95.0', 'victoria-metrics'),
        changelog: '- 新增集群模式\n- 支持水平扩展',
        isLatest: false
      }
    ],
    defaultPort: 8482,
    configurable: true,
    dependencies: [],
    features: ['数据持久化', '高压缩率', '快速查询', '水平扩展', '数据复制'],
    documentation: 'https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#vmstorage',
    requirements: {
      cpu: '4 cores',
      memory: '8GB',
      disk: '100GB SSD'
    }
  },
  'vminsert': {
    id: 'vminsert',
    name: 'VMInsert',
    description: 'VictoriaMetrics集群插入节点，负责接收和分发写入请求',
    category: 'storage',
    versions: [
      { 
        version: '1.96.0', 
        releaseDate: '2024-01-15', 
        downloadUrl: generateDownloadUrl('', '1.96.0', 'victoria-metrics'),
        changelog: '- 提高写入性能\n- 优化负载均衡\n- 支持批量写入',
        isLatest: true
      },
      { 
        version: '1.95.1', 
        releaseDate: '2023-12-20', 
        downloadUrl: generateDownloadUrl('', '1.95.1', 'victoria-metrics'),
        changelog: '- 修复高并发写入问题\n- 优化内存使用',
        isLatest: false
      },
      { 
        version: '1.95.0', 
        releaseDate: '2023-12-10', 
        downloadUrl: generateDownloadUrl('', '1.95.0', 'victoria-metrics'),
        changelog: '- 新增集群写入支持\n- 支持多种数据格式',
        isLatest: false
      }
    ],
    defaultPort: 8480,
    configurable: true,
    dependencies: ['vmstorage'],
    features: ['高并发写入', '负载均衡', '数据分片', '故障转移', '批量处理'],
    documentation: 'https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#vminsert',
    requirements: {
      cpu: '2 cores',
      memory: '2GB',
      disk: '10GB'
    }
  },
  'vmselect': {
    id: 'vmselect',
    name: 'VMSelect',
    description: 'VictoriaMetrics集群查询节点，负责处理查询请求',
    category: 'storage',
    versions: [
      { 
        version: '1.96.0', 
        releaseDate: '2024-01-15', 
        downloadUrl: generateDownloadUrl('', '1.96.0', 'victoria-metrics'),
        changelog: '- 提高查询性能\n- 优化聚合计算\n- 新增缓存机制',
        isLatest: true
      },
      { 
        version: '1.95.1', 
        releaseDate: '2023-12-20', 
        downloadUrl: generateDownloadUrl('', '1.95.1', 'victoria-metrics'),
        changelog: '- 修复查询稳定性问题\n- 改进高基数指标处理',
        isLatest: false
      },
      { 
        version: '1.95.0', 
        releaseDate: '2023-12-10', 
        downloadUrl: generateDownloadUrl('', '1.95.0', 'victoria-metrics'),
        changelog: '- 新增集群查询支持\n- 优化查询性能',
        isLatest: false
      }
    ],
    defaultPort: 8481,
    configurable: true,
    dependencies: ['vmstorage'],
    features: ['高性能查询', 'Prometheus兼容', '查询缓存', '多租户支持', '聚合计算'],
    documentation: 'https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#vmselect',
    requirements: {
      cpu: '2 cores',
      memory: '4GB',
      disk: '10GB'
    }
  },
  'vmalert': {
    id: 'vmalert',
    name: 'VMAlert',
    description: 'VictoriaMetrics告警组件，支持告警规则评估和通知',
    category: 'alerting',
    versions: [
      { 
        version: '1.96.0', 
        releaseDate: '2024-01-15', 
        downloadUrl: generateDownloadUrl('', '1.96.0', 'vmutils'),
        changelog: '- 新增告警规则模板\n- 改进通知机制\n- 支持多种通知渠道',
        isLatest: true
      },
      { 
        version: '1.95.1', 
        releaseDate: '2023-12-20', 
        downloadUrl: generateDownloadUrl('', '1.95.1', 'vmutils'),
        changelog: '- 修复告警规则解析问题\n- 优化性能',
        isLatest: false
      },
      { 
        version: '1.95.0', 
        releaseDate: '2023-12-10', 
        downloadUrl: generateDownloadUrl('', '1.95.0', 'vmutils'),
        changelog: '- 新增告警功能\n- 支持Prometheus告警规则',
        isLatest: false
      }
    ],
    defaultPort: 8880,
    configurable: true,
    dependencies: ['vmselect'],
    features: ['告警规则评估', 'Prometheus兼容', '多种通知渠道', '告警抑制', '告警分组'],
    documentation: 'https://docs.victoriametrics.com/vmalert.html',
    requirements: {
      cpu: '1 core',
      memory: '512MB',
      disk: '1GB'
    }
  },
  'grafana': {
    id: 'grafana',
    name: 'Grafana',
    description: '数据可视化和监控面板',
    category: 'visualization',
    versions: [
      { 
        version: '10.2.3', 
        releaseDate: '2024-01-20', 
        downloadUrl: generateDownloadUrl('https://dl.grafana.com/oss/release/', '10.2.3', 'grafana'),
        changelog: '- 新增仪表盘模板\n- 改进告警管理\n- 修复安全漏洞',
        isLatest: true
      },
      { 
        version: '10.2.2', 
        releaseDate: '2023-12-15', 
        downloadUrl: generateDownloadUrl('https://dl.grafana.com/oss/release/', '10.2.2', 'grafana'),
        changelog: '- 修复UI渲染问题\n- 改进用户认证',
        isLatest: false
      },
      { 
        version: '10.2.1', 
        releaseDate: '2023-12-01', 
        downloadUrl: generateDownloadUrl('https://dl.grafana.com/oss/release/', '10.2.1', 'grafana'),
        changelog: '- 新增数据源支持\n- 优化查询性能',
        isLatest: false
      }
    ],
    defaultPort: 3000,
    configurable: true,
    dependencies: [],
    features: ['多数据源支持', '丰富的可视化', '告警管理', '用户认证', '插件生态'],
    documentation: 'https://grafana.com/docs/grafana/latest/',
    requirements: {
      cpu: '2 cores',
      memory: '512MB',
      disk: '200MB'
    }
  },
  'snmp-exporter': {
    id: 'snmp-exporter',
    name: 'SNMP Exporter',
    description: 'SNMP设备监控导出器',
    category: 'collector',
    versions: [
      { 
        version: '0.24.1', 
        releaseDate: '2023-12-10', 
        downloadUrl: generateDownloadUrl('', '0.24.1', 'snmp_exporter'),
        changelog: '- 新增设备MIB支持\n- 修复SNMP v3认证问题',
        isLatest: true
      },
      { 
        version: '0.24.0', 
        releaseDate: '2023-11-15', 
        downloadUrl: generateDownloadUrl('', '0.24.0', 'snmp_exporter'),
        changelog: '- 改进错误处理\n- 优化性能',
        isLatest: false
      },
      { 
        version: '0.23.0', 
        releaseDate: '2023-10-01', 
        downloadUrl: generateDownloadUrl('', '0.23.0', 'snmp_exporter'),
        changelog: '- 支持更多网络设备\n- 新增自动发现功能',
        isLatest: false
      }
    ],
    defaultPort: 9116,
    configurable: true,
    dependencies: [],
    features: ['SNMP v1/v2c/v3支持', '自动MIB转换', '多设备监控', '自定义指标'],
    documentation: 'https://github.com/prometheus/snmp_exporter',
    requirements: {
      cpu: '1 core',
      memory: '128MB',
      disk: '50MB'
    }
  },
  'alertmanager': {
    id: 'alertmanager',
    name: 'Alertmanager',
    description: '告警管理和通知系统',
    category: 'alerting',
    versions: [
      { 
        version: '0.26.0', 
        releaseDate: '2023-12-20', 
        downloadUrl: generateDownloadUrl('', '0.26.0', 'alertmanager'),
        changelog: '- 新增告警分组功能\n- 改进通知模板\n- 支持更多通知渠道',
        isLatest: true
      },
      { 
        version: '0.25.1', 
        releaseDate: '2023-11-10', 
        downloadUrl: generateDownloadUrl('', '0.25.1', 'alertmanager'),
        changelog: '- 修复高可用模式下的同步问题\n- 改进Web UI',
        isLatest: false
      },
      { 
        version: '0.25.0', 
        releaseDate: '2023-10-15', 
        downloadUrl: generateDownloadUrl('', '0.25.0', 'alertmanager'),
        changelog: '- 新增静默功能\n- 支持更多集成',
        isLatest: false
      }
    ],
    defaultPort: 9093,
    configurable: true,
    dependencies: [],
    features: ['告警分组', '告警抑制', '告警静默', '多种通知方式', '高可用模式'],
    documentation: 'https://prometheus.io/docs/alerting/latest/alertmanager/',
    requirements: {
      cpu: '1 core',
      memory: '128MB',
      disk: '50MB'
    }
  }
}

const CategoryBadge = ({ category }: { category: string }) => {
  const categoryColors: Record<string, string> = {
    collector: 'bg-blue-100 text-blue-800',
    storage: 'bg-green-100 text-green-800',
    visualization: 'bg-purple-100 text-purple-800',
    alerting: 'bg-orange-100 text-orange-800'
  }

  const categoryNames: Record<string, string> = {
    collector: '数据采集',
    storage: '数据存储',
    visualization: '数据可视化',
    alerting: '告警管理'
  }

  return (
    <Badge className={categoryColors[category]}>
      {categoryNames[category] || category}
    </Badge>
  )
}

const ComponentSettings = ({ componentId }: { componentId: string }) => {
  const [settings, setSettings] = useState<Record<string, any>>({})

  const handleSettingChange = (key: string, value: any) => {
    setSettings(prev => ({ ...prev, [key]: value }))
  }

  if (componentId === 'node-exporter') {
    return (
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <Label htmlFor="ne-enabled" className="flex items-center gap-2">
            <Server className="h-4 w-4" />
            启用主机指标收集
          </Label>
          <Switch 
            id="ne-enabled" 
            checked={settings.enabled !== false}
            onCheckedChange={(checked) => handleSettingChange('enabled', checked)}
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="ne-port">监听端口</Label>
          <Input 
            id="ne-port" 
            type="number" 
            defaultValue="9100" 
            onChange={(e) => handleSettingChange('port', e.target.value)}
          />
        </div>
        <div className="space-y-2">
          <Label>启用的收集器</Label>
          <div className="grid grid-cols-2 gap-2">
            {['cpu', 'diskstats', 'filesystem', 'loadavg', 'meminfo', 'netdev'].map(collector => (
              <div key={collector} className="flex items-center space-x-2">
                <Checkbox 
                  id={`collector-${collector}`} 
                  defaultChecked 
                  onCheckedChange={(checked) => {
                    const collectors = settings.collectors || ['cpu', 'diskstats', 'filesystem', 'loadavg', 'meminfo', 'netdev']
                    if (checked) {
                      handleSettingChange('collectors', [...collectors, collector])
                    } else {
                      handleSettingChange('collectors', collectors.filter((c: string) => c !== collector))
                    }
                  }}
                />
                <Label htmlFor={`collector-${collector}`} className="text-sm">{collector}</Label>
              </div>
            ))}
          </div>
        </div>
      </div>
    )
  }

  if (componentId === 'categraf') {
    return (
      <div className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="cat-interval">采集间隔 (秒)</Label>
          <Input 
            id="cat-interval" 
            type="number" 
            defaultValue="15" 
            onChange={(e) => handleSettingChange('interval', e.target.value)}
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="cat-hostname">主机名</Label>
          <Input 
            id="cat-hostname" 
            defaultValue="auto" 
            onChange={(e) => handleSettingChange('hostname', e.target.value)}
          />
        </div>
        <div className="space-y-2">
          <Label>启用的插件</Label>
          <div className="grid grid-cols-2 gap-2">
            {['cpu', 'disk', 'diskio', 'mem', 'net', 'processes'].map(plugin => (
              <div key={plugin} className="flex items-center space-x-2">
                <Checkbox 
                  id={`plugin-${plugin}`} 
                  defaultChecked 
                  onCheckedChange={(checked) => {
                    const plugins = settings.plugins || ['cpu', 'disk', 'diskio', 'mem', 'net', 'processes']
                    if (checked) {
                      handleSettingChange('plugins', [...plugins, plugin])
                    } else {
                      handleSettingChange('plugins', plugins.filter((p: string) => p !== plugin))
                    }
                  }}
                />
                <Label htmlFor={`plugin-${plugin}`} className="text-sm">{plugin}</Label>
              </div>
            ))}
          </div>
        </div>
      </div>
    )
  }

  if (componentId === 'victoriametrics') {
    return (
      <div className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="vm-retention">数据保留期 (天)</Label>
          <Input 
            id="vm-retention" 
            type="number" 
            defaultValue="30" 
            onChange={(e) => handleSettingChange('retention', e.target.value)}
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="vm-port">HTTP监听端口</Label>
          <Input 
            id="vm-port" 
            type="number" 
            defaultValue="8428" 
            onChange={(e) => handleSettingChange('httpPort', e.target.value)}
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="vm-storage">存储路径</Label>
          <Input 
            id="vm-storage" 
            defaultValue="/var/lib/victoriametrics" 
            onChange={(e) => handleSettingChange('storagePath', e.target.value)}
          />
        </div>
        <div className="flex items-center justify-between">
          <Label htmlFor="vm-dedup" className="flex items-center gap-2">
            <Database className="h-4 w-4" />
            启用数据去重
          </Label>
          <Switch 
            id="vm-dedup" 
            defaultChecked={true}
            onCheckedChange={(checked) => handleSettingChange('deduplication', checked)}
          />
        </div>
        <div className="flex items-center justify-between">
          <Label htmlFor="vm-remote-write" className="flex items-center gap-2">
            <Network className="h-4 w-4" />
            启用远程写入
          </Label>
          <Switch 
            id="vm-remote-write" 
            defaultChecked={false}
            onCheckedChange={(checked) => handleSettingChange('remoteWrite', checked)}
          />
        </div>
      </div>
    )
  }

  if (componentId === 'vmstorage') {
    return (
      <div className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="vms-retention">数据保留期 (天)</Label>
          <Input 
            id="vms-retention" 
            type="number" 
            defaultValue="30" 
            onChange={(e) => handleSettingChange('retention', e.target.value)}
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="vms-port">HTTP监听端口</Label>
          <Input 
            id="vms-port" 
            type="number" 
            defaultValue="8482" 
            onChange={(e) => handleSettingChange('httpPort', e.target.value)}
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="vms-storage">存储路径</Label>
          <Input 
            id="vms-storage" 
            defaultValue="/var/lib/vmstorage" 
            onChange={(e) => handleSettingChange('storagePath', e.target.value)}
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="vms-replicas">存储节点副本数</Label>
          <div className="flex items-center space-x-4">
            <Slider
              id="vms-replicas"
              min={1}
              max={10}
              step={1}
              defaultValue={[3]}
              onValueChange={(value) => handleSettingChange('replicas', value[0])}
              className="flex-1"
            />
            <span className="text-sm font-medium w-8">{settings.replicas || 3}</span>
          </div>
        </div>
        <div className="flex items-center justify-between">
          <Label htmlFor="vms-dedup" className="flex items-center gap-2">
            <Database className="h-4 w-4" />
            启用数据去重
          </Label>
          <Switch 
            id="vms-dedup" 
            defaultChecked={true}
            onCheckedChange={(checked) => handleSettingChange('deduplication', checked)}
          />
        </div>
        <div className="flex items-center justify-between">
          <Label htmlFor="vms-autoscale" className="flex items-center gap-2">
            <Layers className="h-4 w-4" />
            启用自动扩容
          </Label>
          <Switch 
            id="vms-autoscale" 
            defaultChecked={false}
            onCheckedChange={(checked) => handleSettingChange('autoScale', checked)}
          />
        </div>
      </div>
    )
  }

  if (componentId === 'vminsert') {
    return (
      <div className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="vmi-port">HTTP监听端口</Label>
          <Input 
            id="vmi-port" 
            type="number" 
            defaultValue="8480" 
            onChange={(e) => handleSettingChange('httpPort', e.target.value)}
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="vmi-storage-nodes">存储节点地址</Label>
          <Textarea 
            id="vmi-storage-nodes" 
            defaultValue="vmstorage-1:8400,vmstorage-2:8400,vmstorage-3:8400" 
            onChange={(e) => handleSettingChange('storageNodes', e.target.value)}
            placeholder="存储节点地址，用逗号分隔"
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="vmi-replicas">插入节点副本数</Label>
          <div className="flex items-center space-x-4">
            <Slider
              id="vmi-replicas"
              min={1}
              max={5}
              step={1}
              defaultValue={[2]}
              onValueChange={(value) => handleSettingChange('replicas', value[0])}
              className="flex-1"
            />
            <span className="text-sm font-medium w-8">{settings.replicas || 2}</span>
          </div>
        </div>
        <div className="flex items-center justify-between">
          <Label htmlFor="vmi-autoscale" className="flex items-center gap-2">
            <Layers className="h-4 w-4" />
            启用自动扩容
          </Label>
          <Switch 
            id="vmi-autoscale" 
            defaultChecked={false}
            onCheckedChange={(checked) => handleSettingChange('autoScale', checked)}
          />
        </div>
      </div>
    )
  }

  if (componentId === 'vmselect') {
    return (
      <div className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="vmsel-port">HTTP监听端口</Label>
          <Input 
            id="vmsel-port" 
            type="number" 
            defaultValue="8481" 
            onChange={(e) => handleSettingChange('httpPort', e.target.value)}
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="vmsel-storage-nodes">存储节点地址</Label>
          <Textarea 
            id="vmsel-storage-nodes" 
            defaultValue="vmstorage-1:8401,vmstorage-2:8401,vmstorage-3:8401" 
            onChange={(e) => handleSettingChange('storageNodes', e.target.value)}
            placeholder="存储节点地址，用逗号分隔"
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="vmsel-replicas">查询节点副本数</Label>
          <div className="flex items-center space-x-4">
            <Slider
              id="vmsel-replicas"
              min={1}
              max={5}
              step={1}
              defaultValue={[2]}
              onValueChange={(value) => handleSettingChange('replicas', value[0])}
              className="flex-1"
            />
            <span className="text-sm font-medium w-8">{settings.replicas || 2}</span>
          </div>
        </div>
        <div className="space-y-2">
          <Label htmlFor="vmsel-cache-size">查询缓存大小 (MB)</Label>
          <Input 
            id="vmsel-cache-size" 
            type="number" 
            defaultValue="512" 
            onChange={(e) => handleSettingChange('cacheSize', e.target.value)}
          />
        </div>
        <div className="flex items-center justify-between">
          <Label htmlFor="vmsel-autoscale" className="flex items-center gap-2">
            <Layers className="h-4 w-4" />
            启用自动扩容
          </Label>
          <Switch 
            id="vmsel-autoscale" 
            defaultChecked={false}
            onCheckedChange={(checked) => handleSettingChange('autoScale', checked)}
          />
        </div>
      </div>
    )
  }

  if (componentId === 'vmalert') {
    return (
      <div className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="vma-port">HTTP监听端口</Label>
          <Input 
            id="vma-port" 
            type="number" 
            defaultValue="8880" 
            onChange={(e) => handleSettingChange('httpPort', e.target.value)}
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="vma-datasource">数据源URL</Label>
          <Input 
            id="vma-datasource" 
            defaultValue="http://vmselect:8481/select/0/prometheus" 
            onChange={(e) => handleSettingChange('datasourceUrl', e.target.value)}
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="vma-notifier">通知器URL</Label>
          <Input 
            id="vma-notifier" 
            defaultValue="http://alertmanager:9093" 
            onChange={(e) => handleSettingChange('notifierUrl', e.target.value)}
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="vma-eval-interval">评估间隔 (秒)</Label>
          <Input 
            id="vma-eval-interval" 
            type="number" 
            defaultValue="15" 
            onChange={(e) => handleSettingChange('evaluationInterval', e.target.value)}
          />
        </div>
        <div className="flex items-center justify-between">
          <Label htmlFor="vma-external-labels" className="flex items-center gap-2">
            <Bell className="h-4 w-4" />
            启用外部标签
          </Label>
          <Switch 
            id="vma-external-labels" 
            defaultChecked={true}
            onCheckedChange={(checked) => handleSettingChange('externalLabels', checked)}
          />
        </div>
      </div>
    )
  }

  if (componentId === 'vmagent') {
    return (
      <div className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="vma-remote-url">远程存储URL</Label>
          <Input 
            id="vma-remote-url" 
            defaultValue="http://localhost:8428/api/v1/write" 
            onChange={(e) => handleSettingChange('remoteWriteUrl', e.target.value)}
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="vma-scrape-interval">抓取间隔 (秒)</Label>
          <Input 
            id="vma-scrape-interval" 
            type="number" 
            defaultValue="15" 
            onChange={(e) => handleSettingChange('scrapeInterval', e.target.value)}
          />
        </div>
        <div className="flex items-center justify-between">
          <Label htmlFor="vma-discovery" className="flex items-center gap-2">
            <Network className="h-4 w-4" />
            启用服务发现
          </Label>
          <Switch 
            id="vma-discovery" 
            defaultChecked={false}
            onCheckedChange={(checked) => handleSettingChange('serviceDiscovery', checked)}
          />
        </div>
      </div>
    )
  }

  if (componentId === 'grafana') {
    return (
      <div className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="grafana-port">HTTP端口</Label>
          <Input 
            id="grafana-port" 
            type="number" 
            defaultValue="3000" 
            onChange={(e) => handleSettingChange('port', e.target.value)}
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="grafana-admin">管理员用户名</Label>
          <Input 
            id="grafana-admin" 
            defaultValue="admin" 
            onChange={(e) => handleSettingChange('adminUser', e.target.value)}
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="grafana-password">管理员密码</Label>
          <Input 
            id="grafana-password" 
            type="password" 
            defaultValue="admin" 
            onChange={(e) => handleSettingChange('adminPassword', e.target.value)}
          />
        </div>
        <div className="space-y-2">
          <Label>自动配置数据源</Label>
          <div className="grid grid-cols-1 gap-2">
            <div className="flex items-center space-x-2">
              <Checkbox 
                id="grafana-ds-vm" 
                defaultChecked 
                onCheckedChange={(checked) => handleSettingChange('configureVMDataSource', checked)}
              />
              <Label htmlFor="grafana-ds-vm" className="text-sm">VictoriaMetrics</Label>
            </div>
          </div>
        </div>
      </div>
    )
  }

  if (componentId === 'alertmanager') {
    return (
      <div className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="am-port">HTTP端口</Label>
          <Input 
            id="am-port" 
            type="number" 
            defaultValue="9093" 
            onChange={(e) => handleSettingChange('port', e.target.value)}
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="am-cluster">集群对等节点</Label>
          <Textarea 
            id="am-cluster" 
            placeholder="每行一个节点地址，例如: alertmanager-peer:9094" 
            onChange={(e) => handleSettingChange('peers', e.target.value.split('\n'))}
          />
        </div>
        <div className="space-y-2">
          <Label>通知渠道</Label>
          <Select defaultValue="email" onValueChange={(value) => handleSettingChange('notifier', value)}>
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="email">邮件</SelectItem>
              <SelectItem value="webhook">Webhook</SelectItem>
              <SelectItem value="slack">Slack</SelectItem>
              <SelectItem value="wechat">微信</SelectItem>
              <SelectItem value="dingtalk">钉钉</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>
    )
  }

  if (componentId === 'snmp-exporter') {
    return (
      <div className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="snmp-port">HTTP端口</Label>
          <Input 
            id="snmp-port" 
            type="number" 
            defaultValue="9116" 
            onChange={(e) => handleSettingChange('port', e.target.value)}
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="snmp-version">SNMP版本</Label>
          <Select defaultValue="v2c" onValueChange={(value) => handleSettingChange('snmpVersion', value)}>
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="v1">SNMP v1</SelectItem>
              <SelectItem value="v2c">SNMP v2c</SelectItem>
              <SelectItem value="v3">SNMP v3</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <div className="space-y-2">
          <Label htmlFor="snmp-community">Community字符串</Label>
          <Input 
            id="snmp-community" 
            defaultValue="public" 
            onChange={(e) => handleSettingChange('community', e.target.value)}
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="snmp-targets">目标设备</Label>
          <Textarea 
            id="snmp-targets" 
            placeholder="每行一个IP地址，例如: 192.168.1.1" 
            onChange={(e) => handleSettingChange('targets', e.target.value.split('\n'))}
          />
        </div>
      </div>
    )
  }

  return (
    <div className="p-4 border rounded-md bg-muted/50">
      <div className="flex items-center gap-2 text-muted-foreground">
        <Info className="h-4 w-4" />
        <p>此组件没有可配置的设置</p>
      </div>
    </div>
  )
}

interface ComponentDetailsProps {
  componentId: string
  onVersionChange: (version: string) => void
  selectedVersion: string
}

export default function ComponentDetails({ componentId, onVersionChange, selectedVersion }: ComponentDetailsProps) {
  const component = COMPONENT_CONFIGS[componentId]
  
  if (!component) {
    return (
      <div className="p-4 border rounded-md">
        <div className="flex items-center gap-2 text-muted-foreground">
          <AlertCircle className="h-4 w-4" />
          <p>未找到组件信息</p>
        </div>
      </div>
    )
  }

  return (
    <Card className="w-full">
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle className="text-xl">{component.name}</CardTitle>
            <div className="flex items-center gap-2 mt-1">
              <CategoryBadge category={component.category} />
              <Badge variant="outline" className="text-xs">
                端口: {component.defaultPort}
              </Badge>
            </div>
          </div>
        </div>
        <CardDescription>{component.description}</CardDescription>
      </CardHeader>
      <CardContent>
        <Tabs defaultValue="overview" className="space-y-4">
          <TabsList className="grid w-full grid-cols-4">
            <TabsTrigger value="overview">概览</TabsTrigger>
            <TabsTrigger value="versions">版本</TabsTrigger>
            <TabsTrigger value="config">配置</TabsTrigger>
            <TabsTrigger value="docs">文档</TabsTrigger>
          </TabsList>
          
          <TabsContent value="overview" className="space-y-4">
            <div>
              <h4 className="text-sm font-medium mb-2">主要功能</h4>
              <div className="grid grid-cols-2 gap-2">
                {component.features.map((feature, index) => (
                  <div key={index} className="flex items-center gap-2">
                    <CheckCircle className="h-4 w-4 text-green-500" />
                    <span className="text-sm">{feature}</span>
                  </div>
                ))}
              </div>
            </div>
            
            <div>
              <h4 className="text-sm font-medium mb-2">默认端口</h4>
              <div className="flex items-center gap-2">
                <Network className="h-4 w-4 text-blue-500" />
                <span className="text-sm">{component.defaultPort}</span>
              </div>
            </div>
            
            {component.dependencies.length > 0 && (
              <div>
                <h4 className="text-sm font-medium mb-2">依赖组件</h4>
                <div className="flex flex-wrap gap-1">
                  {component.dependencies.map(dep => {
                    const depComponent = COMPONENT_CONFIGS[dep]
                    return (
                      <Badge key={dep} variant="outline" className="text-xs">
                        {depComponent?.name || dep}
                      </Badge>
                    )
                  })}
                </div>
              </div>
            )}
            
            <div>
              <h4 className="text-sm font-medium mb-2">系统需求</h4>
              <div className="grid grid-cols-3 gap-2">
                <div className="flex items-center gap-2">
                  <Cpu className="h-4 w-4 text-blue-500" />
                  <span className="text-sm">CPU: {component.requirements.cpu}</span>
                </div>
                <div className="flex items-center gap-2">
                  <HardDrive className="h-4 w-4 text-green-500" />
                  <span className="text-sm">内存: {component.requirements.memory}</span>
                </div>
                <div className="flex items-center gap-2">
                  <Database className="h-4 w-4 text-purple-500" />
                  <span className="text-sm">磁盘: {component.requirements.disk}</span>
                </div>
              </div>
            </div>
          </TabsContent>
          
          <TabsContent value="versions" className="space-y-4">
            <div className="space-y-4">
              {component.versions.map((version) => (
                <Card key={version.version} className={`border ${version.version === selectedVersion ? 'border-primary' : ''}`}>
                  <CardHeader className="py-3">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <CardTitle className="text-base">{version.version}</CardTitle>
                        {version.isLatest && <Badge>最新</Badge>}
                      </div>
                      <div className="flex items-center gap-2">
                        <Button 
                          size="sm" 
                          variant={version.version === selectedVersion ? "default" : "outline"}
                          onClick={() => onVersionChange(version.version)}
                        >
                          {version.version === selectedVersion ? "已选择" : "选择"}
                        </Button>
                        <Button size="sm" variant="outline" asChild>
                          <a href={version.downloadUrl} target="_blank" rel="noopener noreferrer">
                            <Download className="h-4 w-4" />
                          </a>
                        </Button>
                      </div>
                    </div>
                    <div className="flex items-center gap-2 text-sm text-muted-foreground">
                      <Clock className="h-4 w-4" />
                      <span>发布日期: {version.releaseDate}</span>
                    </div>
                  </CardHeader>
                  <CardContent className="py-2">
                    <div className="space-y-2">
                      <h4 className="text-sm font-medium">更新日志:</h4>
                      <div className="text-sm whitespace-pre-line">
                        {version.changelog}
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </TabsContent>
          
          <TabsContent value="config" className="space-y-4">
            {component.configurable ? (
              <ComponentSettings componentId={component.id} />
            ) : (
              <div className="p-4 border rounded-md bg-muted/50">
                <div className="flex items-center gap-2 text-muted-foreground">
                  <Info className="h-4 w-4" />
                  <p>此组件不需要额外配置，可以使用默认设置</p>
                </div>
              </div>
            )}
          </TabsContent>
          
          <TabsContent value="docs" className="space-y-4">
            <div className="p-4 border rounded-md">
              <div className="flex flex-col gap-4">
                <div className="flex items-center gap-2">
                  <FileText className="h-4 w-4 text-blue-500" />
                  <span className="font-medium">官方文档</span>
                </div>
                <p className="text-sm text-muted-foreground">
                  访问 {component.name} 的官方文档以获取详细的安装和配置指南。
                </p>
                <Button asChild>
                  <a href={component.documentation} target="_blank" rel="noopener noreferrer">
                    <ExternalLink className="h-4 w-4 mr-2" />
                    访问文档
                  </a>
                </Button>
              </div>
            </div>
          </TabsContent>
        </Tabs>
      </CardContent>
    </Card>
  )
}