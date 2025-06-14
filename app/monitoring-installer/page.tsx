'use client'

import React, { useState } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Progress } from '@/components/ui/progress'
import { 
  Download, 
  Settings, 
  Play, 
  CheckCircle, 
  AlertCircle, 
  Server, 
  Database, 
  BarChart3, 
  Monitor,
  Activity,
  RefreshCw,
  Bell, // Added for VMAlert, Alertmanager (already AlertCircle, Bell is an alternative)
  Network // Added for SNMP Exporter, Categraf (Server is also fine)
} from 'lucide-react'

// Data from ComponentDetails.tsx (COMPONENT_CONFIGS) - simplified for this update
// In a real scenario, this would likely be imported or fetched
const allMonitoringComponentsConfig = {
  'node-exporter': {
    id: 'node-exporter',
    name: 'Node Exporter',
    description: '系统指标采集器，收集CPU、内存、磁盘等系统指标', // System metrics collector
    category: 'collector',
    versions: [{ version: '1.7.0', isLatest: true }],
  },
  'categraf': {
    id: 'categraf',
    name: 'Categraf',
    description: '多功能指标采集器，支持多种数据源', // Multi-functional metrics collector
    category: 'collector',
    versions: [{ version: '0.3.60', isLatest: true }],
  },
  'vmagent': {
    id: 'vmagent',
    name: 'VMAgent',
    description: '轻量级指标代理，负责指标收集和转发', // Lightweight metrics agent
    category: 'collector',
    versions: [{ version: '1.96.0', isLatest: true }],
  },
  'victoriametrics': {
    id: 'victoriametrics',
    name: 'VictoriaMetrics',
    description: 'VictoriaMetrics单机版，高性能时序数据库', // High-performance time-series database (single-node)
    category: 'storage',
    versions: [{ version: '1.96.0', isLatest: true }],
  },
  'vmstorage': {
    id: 'vmstorage',
    name: 'VMStorage',
    description: 'VictoriaMetrics集群存储节点', // VictoriaMetrics cluster storage node
    category: 'storage',
    versions: [{ version: '1.96.0', isLatest: true }],
  },
  'vminsert': {
    id: 'vminsert',
    name: 'VMInsert',
    description: 'VictoriaMetrics集群插入节点', // VictoriaMetrics cluster insert node
    category: 'storage',
    versions: [{ version: '1.96.0', isLatest: true }],
  },
  'vmselect': {
    id: 'vmselect',
    name: 'VMSelect',
    description: 'VictoriaMetrics集群查询节点', // VictoriaMetrics cluster query node
    category: 'storage',
    versions: [{ version: '1.96.0', isLatest: true }],
  },
  'vmalert': {
    id: 'vmalert',
    name: 'VMAlert',
    description: 'VictoriaMetrics告警组件', // VictoriaMetrics alerting component
    category: 'alerting',
    versions: [{ version: '1.96.0', isLatest: true }],
  },
  'grafana': {
    id: 'grafana',
    name: 'Grafana',
    description: '数据可视化和监控面板', // Data visualization and monitoring dashboard
    category: 'visualization',
    versions: [{ version: '10.2.3', isLatest: true }],
  },
  'snmp-exporter': {
    id: 'snmp-exporter',
    name: 'SNMP Exporter',
    description: 'SNMP设备监控导出器', // SNMP device monitoring exporter
    category: 'collector',
    versions: [{ version: '0.24.1', isLatest: true }],
  },
  'alertmanager': {
    id: 'alertmanager',
    name: 'Alertmanager',
    description: '告警管理和通知系统', // Alert management and notification system
    category: 'alerting',
    versions: [{ version: '0.26.0', isLatest: true }],
  }
};

const getIconForCategory = (category: string) => {
  switch (category) {
    case 'collector':
      return Server; // Using Server for collectors like Node Exporter, Categraf, SNMP Exporter, VMAgent
    case 'storage':
      return Database; // For VictoriaMetrics and its storage components
    case 'visualization':
      return BarChart3; // For Grafana
    case 'alerting':
      return Bell; // Using Bell for Alertmanager, VMAlert (AlertCircle also an option)
    default:
      return Settings; // Default icon
  }
};

export default function MonitoringInstaller() {
  const [isInstalling, setIsInstalling] = useState(false)
  const [installProgress, setInstallProgress] = useState(0)

  const components = Object.values(allMonitoringComponentsConfig).map(comp => {
    const latestVersion = comp.versions.find(v => v.isLatest) || comp.versions[0];
    return {
      id: comp.id,
      name: comp.name,
      description: comp.description, // Assuming description is already in the desired language or a key
      icon: getIconForCategory(comp.category),
      status: 'available', // Default status
      version: latestVersion ? latestVersion.version : 'N/A'
    };
  });

  const handleInstall = (componentId: string) => {
    setIsInstalling(true)
    setInstallProgress(0)
    
    // 模拟安装过程
    const interval = setInterval(() => {
      setInstallProgress(prev => {
        if (prev >= 100) {
          clearInterval(interval)
          setIsInstalling(false)
          return 100
        }
        return prev + 10
      })
    }, 500)
  }

  return (
    <div className="flex-1 space-y-6 p-4 md:p-8 pt-6">
      {/* 页面头部 */}
      <div className="flex flex-col space-y-4 lg:flex-row lg:items-center lg:justify-between lg:space-y-0">
        <div className="space-y-1">
          <div className="flex items-center space-x-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-gradient-to-br from-blue-500 to-purple-600">
              <Monitor className="h-4 w-4 text-white" />
            </div>
            <h2 className="text-3xl font-bold tracking-tight">监控组件安装器</h2>
          </div>
          <p className="text-muted-foreground">
            一键安装和配置监控组件，快速搭建完整的监控系统
          </p>
        </div>
        
        <div className="flex items-center space-x-2">
          <Button variant="outline" size="sm">
            <RefreshCw className="mr-2 h-4 w-4" />
            刷新状态
          </Button>
          <Button size="sm">
            <Download className="mr-2 h-4 w-4" />
            批量安装
          </Button>
        </div>
      </div>

      {/* 安装进度 */}
      {isInstalling && (
        <Alert>
          <Activity className="h-4 w-4" />
          <AlertDescription>
            正在安装组件... {installProgress}%
            <Progress value={installProgress} className="mt-2" />
          </AlertDescription>
        </Alert>
      )}

      {/* 主要内容 */}
      <Tabs defaultValue="components" className="w-full">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="components">组件管理</TabsTrigger>
          <TabsTrigger value="templates">安装模板</TabsTrigger>
          <TabsTrigger value="config">配置管理</TabsTrigger>
          <TabsTrigger value="status">系统状态</TabsTrigger>
        </TabsList>

        <TabsContent value="components" className="space-y-6">
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4"> {/* Adjusted grid for more items */}
            {components.map((component) => {
              const Icon = component.icon
              return (
                <Card key={component.id}>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <div className="flex items-center space-x-2">
                      <Icon className="h-5 w-5" />
                      <CardTitle className="text-lg">{component.name}</CardTitle>
                    </div>
                    <Badge variant="secondary">v{component.version}</Badge>
                  </CardHeader>
                  <CardContent>
                    <CardDescription className="mb-4 h-10"> {/* Added fixed height for description */}
                      {component.description}
                    </CardDescription>
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-2">
                        <CheckCircle className="h-4 w-4 text-green-500" />
                        <span className="text-sm text-green-600">可用</span>
                      </div>
                      <Button 
                        size="sm" 
                        onClick={() => handleInstall(component.id)}
                        disabled={isInstalling}
                      >
                        <Download className="mr-2 h-4 w-4" />
                        安装
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              )
            })}
          </div>
        </TabsContent>

        <TabsContent value="templates" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>安装模板</CardTitle>
              <CardDescription>预配置的监控组件组合，适用于不同场景</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid gap-4 md:grid-cols-2">
                <div className="p-4 border rounded-lg">
                  <h4 className="font-medium">基础监控</h4>
                  <p className="text-sm text-muted-foreground mt-1">
                    包含 Prometheus + Grafana + Node Exporter
                  </p>
                  <Button className="mt-3" size="sm">选择模板</Button>
                </div>
                <div className="p-4 border rounded-lg">
                  <h4 className="font-medium">完整监控</h4>
                  <p className="text-sm text-muted-foreground mt-1">
                    包含所有主要监控组件和告警系统
                  </p>
                  <Button className="mt-3" size="sm">选择模板</Button>
                </div>
                 <div className="p-4 border rounded-lg">
                  <h4 className="font-medium">VictoriaMetrics 栈</h4>
                  <p className="text-sm text-muted-foreground mt-1">
                    包含 VictoriaMetrics 单机版, VMAgent, Grafana
                  </p>
                  <Button className="mt-3" size="sm">选择模板</Button>
                </div>
                <div className="p-4 border rounded-lg">
                  <h4 className="font-medium">VictoriaMetrics 集群基础</h4>
                  <p className="text-sm text-muted-foreground mt-1">
                    包含 VMStorage, VMInsert, VMSelect, VMAgent, Grafana
                  </p>
                  <Button className="mt-3" size="sm">选择模板</Button>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="config" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>配置管理</CardTitle>
              <CardDescription>管理监控组件的配置文件</CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground">配置管理功能正在开发中...</p>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="status" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>系统状态</CardTitle>
              <CardDescription>查看监控系统的运行状态</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <span>系统状态</span>
                  <Badge variant="default">正常</Badge>
                </div>
                <div className="flex items-center justify-between">
                  <span>已安装组件</span>
                  <span className="text-sm text-muted-foreground">0 / {components.length}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span>最后检查</span>
                  <span className="text-sm text-muted-foreground">刚刚</span>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}