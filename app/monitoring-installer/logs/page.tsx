"use client"

import React, { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Switch } from '@/components/ui/switch'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Separator } from '@/components/ui/separator'
import { 
  Search, 
  Download, 
  Filter, 
  RefreshCw, 
  Calendar, 
  Clock, 
  AlertTriangle, 
  Info, 
  CheckCircle, 
  XCircle, 
  Terminal, 
  FileText, 
  Eye, 
  Settings, 
  Trash2, 
  Archive, 
  Share, 
  Copy, 
  ExternalLink,
  ChevronDown,
  ChevronUp,
  Play,
  Pause,
  RotateCcw,
  Zap,
  Activity,
  Database,
  BarChart3,
  Bell,
  Server
} from 'lucide-react'

interface LogEntry {
  id: string
  timestamp: string
  level: 'debug' | 'info' | 'warn' | 'error' | 'fatal'
  component: string
  service: string
  message: string
  details?: string
  source: string
  tags: string[]
  metadata?: Record<string, any>
}

interface LogFilter {
  component: string
  service: string
  level: string
  timeRange: string
  searchQuery: string
  tags: string[]
}

interface LogStats {
  total: number
  byLevel: Record<string, number>
  byComponent: Record<string, number>
  byService: Record<string, number>
  timeRange: {
    start: string
    end: string
  }
}

// 模拟日志数据
const MOCK_LOG_ENTRIES: LogEntry[] = [
  {
    id: 'log-1',
    timestamp: '2024-01-22 16:30:15.123',
    level: 'info',
    component: 'node-exporter',
    service: 'metrics-collector',
    message: 'Successfully collected system metrics',
    details: 'Collected CPU, memory, disk, and network metrics from host node-01',
    source: 'node-01',
    tags: ['metrics', 'collection', 'success'],
    metadata: {
      host: 'node-01',
      metrics_count: 1247,
      duration_ms: 156
    }
  },
  {
    id: 'log-2',
    timestamp: '2024-01-22 16:30:10.456',
    level: 'error',
    component: 'victoriametrics',
    service: 'storage',
    message: 'Failed to write metrics to storage',
    details: 'Connection timeout while writing batch of 500 metrics to storage backend',
    source: 'vm-storage-01',
    tags: ['storage', 'write', 'error', 'timeout'],
    metadata: {
      batch_size: 500,
      timeout_ms: 5000,
      retry_count: 3
    }
  },
  {
    id: 'log-3',
    timestamp: '2024-01-22 16:30:05.789',
    level: 'warn',
    component: 'grafana',
    service: 'visualization',
    message: 'High memory usage detected',
    details: 'Memory usage has exceeded 80% threshold (current: 85%)',
    source: 'grafana-pod-1',
    tags: ['memory', 'threshold', 'warning'],
    metadata: {
      memory_usage_percent: 85,
      threshold_percent: 80,
      memory_used_mb: 1700,
      memory_limit_mb: 2048
    }
  },
  {
    id: 'log-4',
    timestamp: '2024-01-22 16:30:00.012',
    level: 'info',
    component: 'alertmanager',
    service: 'alerting',
    message: 'Alert rule evaluation completed',
    details: 'Evaluated 25 alert rules, 2 alerts triggered',
    source: 'alertmanager-01',
    tags: ['alerts', 'evaluation', 'rules'],
    metadata: {
      rules_evaluated: 25,
      alerts_triggered: 2,
      evaluation_duration_ms: 234
    }
  },
  {
    id: 'log-5',
    timestamp: '2024-01-22 16:29:55.345',
    level: 'debug',
    component: 'categraf',
    service: 'metrics-collector',
    message: 'Plugin execution completed',
    details: 'CPU plugin collected 12 metrics in 45ms',
    source: 'categraf-agent-02',
    tags: ['plugin', 'cpu', 'metrics'],
    metadata: {
      plugin_name: 'cpu',
      metrics_collected: 12,
      execution_time_ms: 45
    }
  },
  {
    id: 'log-6',
    timestamp: '2024-01-22 16:29:50.678',
    level: 'error',
    component: 'snmp-exporter',
    service: 'network-monitoring',
    message: 'SNMP query failed',
    details: 'Failed to query SNMP device 192.168.1.100: timeout after 10 seconds',
    source: 'snmp-exporter-01',
    tags: ['snmp', 'network', 'timeout', 'device'],
    metadata: {
      device_ip: '192.168.1.100',
      timeout_seconds: 10,
      oid: '1.3.6.1.2.1.1.1.0'
    }
  },
  {
    id: 'log-7',
    timestamp: '2024-01-22 16:29:45.901',
    level: 'info',
    component: 'vmauth',
    service: 'proxy',
    message: 'Request processed successfully',
    details: 'Proxied query request to VictoriaMetrics backend',
    source: 'vmauth-01',
    tags: ['proxy', 'query', 'success'],
    metadata: {
      backend: 'victoriametrics-01',
      response_time_ms: 123,
      query_type: 'range_query'
    }
  },
  {
    id: 'log-8',
    timestamp: '2024-01-22 16:29:40.234',
    level: 'warn',
    component: 'vmagent',
    service: 'metrics-agent',
    message: 'Scrape target unreachable',
    details: 'Failed to scrape metrics from target http://app-server:8080/metrics',
    source: 'vmagent-01',
    tags: ['scrape', 'target', 'unreachable'],
    metadata: {
      target_url: 'http://app-server:8080/metrics',
      error: 'connection refused',
      retry_after_seconds: 30
    }
  }
]

const COMPONENTS = ['all', 'node-exporter', 'victoriametrics', 'grafana', 'alertmanager', 'categraf', 'snmp-exporter', 'vmauth', 'vmagent']
const SERVICES = ['all', 'metrics-collector', 'storage', 'visualization', 'alerting', 'network-monitoring', 'proxy', 'metrics-agent']
const LOG_LEVELS = ['all', 'debug', 'info', 'warn', 'error', 'fatal']
const TIME_RANGES = [
  { label: '最近 15 分钟', value: '15m' },
  { label: '最近 1 小时', value: '1h' },
  { label: '最近 6 小时', value: '6h' },
  { label: '最近 24 小时', value: '24h' },
  { label: '最近 7 天', value: '7d' },
  { label: '自定义', value: 'custom' }
]

const LogLevelBadge = ({ level }: { level: string }) => {
  const levelConfig: Record<string, { color: string; icon: React.ReactNode }> = {
    debug: { color: 'bg-gray-100 text-gray-800', icon: <Info className="h-3 w-3" /> },
    info: { color: 'bg-blue-100 text-blue-800', icon: <Info className="h-3 w-3" /> },
    warn: { color: 'bg-yellow-100 text-yellow-800', icon: <AlertTriangle className="h-3 w-3" /> },
    error: { color: 'bg-red-100 text-red-800', icon: <XCircle className="h-3 w-3" /> },
    fatal: { color: 'bg-red-200 text-red-900', icon: <XCircle className="h-3 w-3" /> }
  }

  const config = levelConfig[level] || levelConfig.info

  return (
    <Badge className={`${config.color} flex items-center gap-1 text-xs`}>
      {config.icon}
      {level.toUpperCase()}
    </Badge>
  )
}

const ComponentIcon = ({ component }: { component: string }) => {
  const icons: Record<string, React.ReactNode> = {
    'node-exporter': <Activity className="h-4 w-4" />,
    'victoriametrics': <Database className="h-4 w-4" />,
    'grafana': <BarChart3 className="h-4 w-4" />,
    'alertmanager': <Bell className="h-4 w-4" />,
    'categraf': <Activity className="h-4 w-4" />,
    'snmp-exporter': <Activity className="h-4 w-4" />,
    'vmauth': <Server className="h-4 w-4" />,
    'vmagent': <Activity className="h-4 w-4" />
  }

  return icons[component] || <Server className="h-4 w-4" />
}

const LogEntryCard = ({ entry, isExpanded, onToggle }: {
  entry: LogEntry
  isExpanded: boolean
  onToggle: () => void
}) => {
  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text)
  }

  return (
    <Card className="mb-2">
      <CardContent className="p-4">
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <div className="flex items-center gap-2 mb-2">
              <LogLevelBadge level={entry.level} />
              <div className="flex items-center gap-1 text-sm text-gray-600">
                <ComponentIcon component={entry.component} />
                <span className="font-medium">{entry.component}</span>
                <span>/</span>
                <span>{entry.service}</span>
              </div>
              <Badge variant="outline" className="text-xs">
                {entry.source}
              </Badge>
              <span className="text-xs text-gray-500">{entry.timestamp}</span>
            </div>
            <p className="text-sm mb-2">{entry.message}</p>
            {entry.tags.length > 0 && (
              <div className="flex flex-wrap gap-1 mb-2">
                {entry.tags.map((tag) => (
                  <Badge key={tag} variant="secondary" className="text-xs">
                    {tag}
                  </Badge>
                ))}
              </div>
            )}
          </div>
          <div className="flex items-center gap-1 ml-4">
            <Button
              variant="ghost"
              size="sm"
              onClick={() => copyToClipboard(entry.message)}
            >
              <Copy className="h-4 w-4" />
            </Button>
            <Button
              variant="ghost"
              size="sm"
              onClick={onToggle}
            >
              {isExpanded ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
            </Button>
          </div>
        </div>
        
        {isExpanded && (
          <div className="mt-4 pt-4 border-t">
            {entry.details && (
              <div className="mb-4">
                <Label className="text-sm font-medium">详细信息</Label>
                <p className="text-sm text-gray-600 mt-1">{entry.details}</p>
              </div>
            )}
            
            {entry.metadata && Object.keys(entry.metadata).length > 0 && (
              <div>
                <Label className="text-sm font-medium">元数据</Label>
                <div className="bg-gray-50 p-3 rounded-lg mt-1">
                  <pre className="text-xs text-gray-700">
                    {JSON.stringify(entry.metadata, null, 2)}
                  </pre>
                </div>
              </div>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  )
}

export default function LogManagementPage() {
  const [logEntries, setLogEntries] = useState<LogEntry[]>(MOCK_LOG_ENTRIES)
  const [filteredLogs, setFilteredLogs] = useState<LogEntry[]>(MOCK_LOG_ENTRIES)
  const [expandedLogs, setExpandedLogs] = useState<Set<string>>(new Set())
  const [autoRefresh, setAutoRefresh] = useState(true)
  const [isLiveMode, setIsLiveMode] = useState(false)
  const [filter, setFilter] = useState<LogFilter>({
    component: 'all',
    service: 'all',
    level: 'all',
    timeRange: '1h',
    searchQuery: '',
    tags: []
  })

  // 自动刷新日志
  useEffect(() => {
    if (!autoRefresh && !isLiveMode) return

    const interval = setInterval(() => {
      // 模拟新日志条目
      const newLog: LogEntry = {
        id: `log-${Date.now()}`,
        timestamp: new Date().toISOString().replace('T', ' ').slice(0, 23),
        level: ['info', 'warn', 'error'][Math.floor(Math.random() * 3)] as any,
        component: COMPONENTS[Math.floor(Math.random() * (COMPONENTS.length - 1)) + 1],
        service: SERVICES[Math.floor(Math.random() * (SERVICES.length - 1)) + 1],
        message: `Simulated log message at ${new Date().toLocaleTimeString()}`,
        source: `source-${Math.floor(Math.random() * 10) + 1}`,
        tags: ['simulated', 'auto-generated']
      }

      setLogEntries(prev => [newLog, ...prev.slice(0, 99)]) // 保持最新100条
    }, isLiveMode ? 2000 : 10000)

    return () => clearInterval(interval)
  }, [autoRefresh, isLiveMode])

  // 应用过滤器
  useEffect(() => {
    let filtered = logEntries

    if (filter.component !== 'all') {
      filtered = filtered.filter(log => log.component === filter.component)
    }

    if (filter.service !== 'all') {
      filtered = filtered.filter(log => log.service === filter.service)
    }

    if (filter.level !== 'all') {
      filtered = filtered.filter(log => log.level === filter.level)
    }

    if (filter.searchQuery) {
      const query = filter.searchQuery.toLowerCase()
      filtered = filtered.filter(log => 
        log.message.toLowerCase().includes(query) ||
        log.details?.toLowerCase().includes(query) ||
        log.component.toLowerCase().includes(query) ||
        log.service.toLowerCase().includes(query)
      )
    }

    setFilteredLogs(filtered)
  }, [logEntries, filter])

  const toggleLogExpansion = (logId: string) => {
    setExpandedLogs(prev => {
      const newSet = new Set(prev)
      if (newSet.has(logId)) {
        newSet.delete(logId)
      } else {
        newSet.add(logId)
      }
      return newSet
    })
  }

  const clearLogs = () => {
    setLogEntries([])
    setFilteredLogs([])
  }

  const exportLogs = () => {
    const dataStr = JSON.stringify(filteredLogs, null, 2)
    const dataBlob = new Blob([dataStr], { type: 'application/json' })
    const url = URL.createObjectURL(dataBlob)
    const link = document.createElement('a')
    link.href = url
    link.download = `logs-${new Date().toISOString().slice(0, 10)}.json`
    link.click()
  }

  const getLogStats = (): LogStats => {
    const byLevel: Record<string, number> = {}
    const byComponent: Record<string, number> = {}
    const byService: Record<string, number> = {}

    filteredLogs.forEach(log => {
      byLevel[log.level] = (byLevel[log.level] || 0) + 1
      byComponent[log.component] = (byComponent[log.component] || 0) + 1
      byService[log.service] = (byService[log.service] || 0) + 1
    })

    return {
      total: filteredLogs.length,
      byLevel,
      byComponent,
      byService,
      timeRange: {
        start: filteredLogs[filteredLogs.length - 1]?.timestamp || '',
        end: filteredLogs[0]?.timestamp || ''
      }
    }
  }

  const stats = getLogStats()

  return (
    <div className="container mx-auto p-6 space-y-6">
      {/* 页面标题 */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">日志管理</h1>
          <p className="text-gray-600 mt-1">查看和分析监控组件日志</p>
        </div>
        <div className="flex items-center gap-2">
          <div className="flex items-center space-x-2">
            <Switch
              id="live-mode"
              checked={isLiveMode}
              onCheckedChange={setIsLiveMode}
            />
            <Label htmlFor="live-mode" className="text-sm">实时模式</Label>
          </div>
          <div className="flex items-center space-x-2">
            <Switch
              id="auto-refresh"
              checked={autoRefresh}
              onCheckedChange={setAutoRefresh}
            />
            <Label htmlFor="auto-refresh" className="text-sm">自动刷新</Label>
          </div>
          <Button variant="outline" size="sm" onClick={exportLogs}>
            <Download className="h-4 w-4 mr-2" />
            导出
          </Button>
          <Button variant="outline" size="sm" onClick={clearLogs}>
            <Trash2 className="h-4 w-4 mr-2" />
            清空
          </Button>
        </div>
      </div>

      {/* 统计信息 */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-2">
              <FileText className="h-5 w-5 text-blue-600" />
              <div>
                <p className="text-sm text-gray-600">总日志数</p>
                <p className="text-2xl font-bold">{stats.total}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-2">
              <XCircle className="h-5 w-5 text-red-600" />
              <div>
                <p className="text-sm text-gray-600">错误日志</p>
                <p className="text-2xl font-bold">{stats.byLevel.error || 0}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-2">
              <AlertTriangle className="h-5 w-5 text-yellow-600" />
              <div>
                <p className="text-sm text-gray-600">警告日志</p>
                <p className="text-2xl font-bold">{stats.byLevel.warn || 0}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-2">
              <CheckCircle className="h-5 w-5 text-green-600" />
              <div>
                <p className="text-sm text-gray-600">信息日志</p>
                <p className="text-2xl font-bold">{stats.byLevel.info || 0}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* 过滤器 */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Filter className="h-5 w-5" />
            过滤器
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-6 gap-4">
            <div>
              <Label>组件</Label>
              <Select value={filter.component} onValueChange={(value) => setFilter(prev => ({ ...prev, component: value }))}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {COMPONENTS.map((component) => (
                    <SelectItem key={component} value={component}>
                      {component === 'all' ? '全部组件' : component}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label>服务</Label>
              <Select value={filter.service} onValueChange={(value) => setFilter(prev => ({ ...prev, service: value }))}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {SERVICES.map((service) => (
                    <SelectItem key={service} value={service}>
                      {service === 'all' ? '全部服务' : service}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label>日志级别</Label>
              <Select value={filter.level} onValueChange={(value) => setFilter(prev => ({ ...prev, level: value }))}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {LOG_LEVELS.map((level) => (
                    <SelectItem key={level} value={level}>
                      {level === 'all' ? '全部级别' : level.toUpperCase()}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label>时间范围</Label>
              <Select value={filter.timeRange} onValueChange={(value) => setFilter(prev => ({ ...prev, timeRange: value }))}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {TIME_RANGES.map((range) => (
                    <SelectItem key={range.value} value={range.value}>
                      {range.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="md:col-span-2">
              <Label>搜索</Label>
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                <Input
                  placeholder="搜索日志内容..."
                  value={filter.searchQuery}
                  onChange={(e) => setFilter(prev => ({ ...prev, searchQuery: e.target.value }))}
                  className="pl-10"
                />
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* 日志列表 */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2">
              <Terminal className="h-5 w-5" />
              日志条目
              {isLiveMode && (
                <Badge className="bg-green-100 text-green-800 animate-pulse">
                  <Activity className="h-3 w-3 mr-1" />
                  实时
                </Badge>
              )}
            </CardTitle>
            <div className="flex items-center gap-2">
              <Button variant="outline" size="sm" onClick={() => setExpandedLogs(new Set())}>
                折叠全部
              </Button>
              <Button variant="outline" size="sm" onClick={() => setExpandedLogs(new Set(filteredLogs.map(log => log.id)))}>
                展开全部
              </Button>
              <Button variant="outline" size="sm">
                <RefreshCw className="h-4 w-4 mr-1" />
                刷新
              </Button>
            </div>
          </div>
          <CardDescription>
            显示 {filteredLogs.length} 条日志 (共 {logEntries.length} 条)
          </CardDescription>
        </CardHeader>
        <CardContent>
          {filteredLogs.length === 0 ? (
            <div className="text-center py-12">
              <FileText className="h-12 w-12 mx-auto mb-4 text-gray-300" />
              <p className="text-lg font-medium mb-2 text-gray-500">没有找到日志</p>
              <p className="text-gray-400">尝试调整过滤条件或等待新的日志生成</p>
            </div>
          ) : (
            <div className="space-y-2 max-h-[600px] overflow-y-auto">
              {filteredLogs.map((entry) => (
                <LogEntryCard
                  key={entry.id}
                  entry={entry}
                  isExpanded={expandedLogs.has(entry.id)}
                  onToggle={() => toggleLogExpansion(entry.id)}
                />
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* 日志分析 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>按级别分布</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {Object.entries(stats.byLevel).map(([level, count]) => (
                <div key={level} className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <LogLevelBadge level={level} />
                    <span className="text-sm">{level.toUpperCase()}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-24 bg-gray-200 rounded-full h-2">
                      <div 
                        className="bg-blue-600 h-2 rounded-full" 
                        style={{ width: `${(count / stats.total) * 100}%` }}
                      />
                    </div>
                    <span className="text-sm font-medium w-8 text-right">{count}</span>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>按组件分布</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {Object.entries(stats.byComponent).map(([component, count]) => (
                <div key={component} className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <ComponentIcon component={component} />
                    <span className="text-sm">{component}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-24 bg-gray-200 rounded-full h-2">
                      <div 
                        className="bg-green-600 h-2 rounded-full" 
                        style={{ width: `${(count / stats.total) * 100}%` }}
                      />
                    </div>
                    <span className="text-sm font-medium w-8 text-right">{count}</span>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}