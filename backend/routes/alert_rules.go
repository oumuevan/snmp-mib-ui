package routes

import (
	"github.com/gin-gonic/gin"
	"mib-platform/controllers"
	"mib-platform/middleware"
)

// RegisterAlertRulesRoutes 注册告警规则相关路由
func RegisterAlertRulesRoutes(r *gin.Engine, controller *controllers.AlertRulesController) {
	// 告警规则API组
	alertRules := r.Group("/api/v1/alert-rules")
	alertRules.Use(middleware.CORS()) // 跨域中间件
	// alertRules.Use(middleware.Auth()) // 认证中间件（如果需要）

	{
		// 告警规则管理
		alertRules.GET("", controller.GetAlertRules)                    // 获取告警规则列表
		alertRules.POST("", controller.CreateAlertRule)                 // 创建告警规则
		alertRules.GET("/:id", controller.GetAlertRuleByID)             // 获取单个告警规则
		alertRules.PUT("/:id", controller.UpdateAlertRule)              // 更新告警规则
		alertRules.DELETE("/:id", controller.DeleteAlertRule)           // 删除告警规则

		// 批量操作
		alertRules.POST("/batch", controller.BatchCreateAlertRules)     // 批量创建告警规则
		alertRules.PUT("/batch", controller.BatchUpdateAlertRules)      // 批量更新告警规则
		alertRules.DELETE("/batch", controller.BatchDeleteAlertRules)   // 批量删除告警规则

		// 导入导出
		alertRules.POST("/import", controller.ImportRules)              // 导入告警规则
		alertRules.GET("/export", controller.ExportRules)              // 导出告警规则

		// PromQL相关
		alertRules.POST("/validate-promql", controller.ValidatePromQL) // 验证PromQL表达式
		alertRules.GET("/metrics", controller.GetMetrics)              // 获取可用指标
		alertRules.POST("/query", controller.QueryMetrics)             // 查询指标数据
	}

	// 告警规则模板API组
	templates := r.Group("/api/v1/alert-rule-templates")
	templates.Use(middleware.CORS())

	{
		templates.GET("", controller.GetRuleTemplates)                 // 获取规则模板列表
		templates.POST("", controller.CreateRuleTemplate)              // 创建规则模板
		templates.GET("/:id", controller.GetRuleTemplateByID)          // 获取单个规则模板
		templates.PUT("/:id", controller.UpdateRuleTemplate)           // 更新规则模板
		templates.DELETE("/:id", controller.DeleteRuleTemplate)        // 删除规则模板
		templates.POST("/:id/clone", controller.CloneRuleTemplate)     // 克隆规则模板
		templates.POST("/:id/apply", controller.ApplyTemplate)         // 应用模板到设备组
	}

	// 设备分组API组
	deviceGroups := r.Group("/api/v1/device-groups")
	deviceGroups.Use(middleware.CORS())

	{
		deviceGroups.GET("", controller.GetDeviceGroups)               // 获取设备分组列表
		deviceGroups.POST("", controller.CreateDeviceGroup)            // 创建设备分组
		deviceGroups.GET("/:id", controller.GetDeviceGroupByID)        // 获取单个设备分组
		deviceGroups.PUT("/:id", controller.UpdateDeviceGroup)         // 更新设备分组
		deviceGroups.DELETE("/:id", controller.DeleteDeviceGroup)      // 删除设备分组

		// 设备管理
		deviceGroups.POST("/:id/devices", controller.AddDevicesToGroup)    // 添加设备到分组
		deviceGroups.DELETE("/:id/devices", controller.RemoveDevicesFromGroup) // 从分组移除设备
		deviceGroups.GET("/:id/devices", controller.GetDeviceGroupDevices)    // 获取分组下的设备

		// 批量操作
		deviceGroups.POST("/batch", controller.BatchCreateDeviceGroups) // 批量创建设备分组
		deviceGroups.DELETE("/batch", controller.BatchDeleteDeviceGroups) // 批量删除设备分组
	}

	// Alertmanager配置API组
	alertmanager := r.Group("/api/v1/alertmanager")
	alertmanager.Use(middleware.CORS())

	{
		alertmanager.GET("/config", controller.GetAlertmanagerConfig)     // 获取Alertmanager配置
		alertmanager.PUT("/config", controller.UpdateAlertmanagerConfig)  // 更新Alertmanager配置
		alertmanager.POST("/config/validate", controller.ValidateAlertmanagerConfig) // 验证配置
		alertmanager.POST("/config/preview", controller.PreviewAlertmanagerConfig)   // 预览配置
		alertmanager.GET("/config/export", controller.ExportAlertmanagerConfig)      // 导出配置

		// 路由规则
		alertmanager.GET("/routes", controller.GetRoutes)              // 获取路由规则
		alertmanager.POST("/routes/test", controller.TestRoute)        // 测试路由规则

		// 接收器管理
		alertmanager.GET("/receivers", controller.GetReceivers)        // 获取接收器列表
		alertmanager.POST("/receivers", controller.CreateReceiver)     // 创建接收器
		alertmanager.PUT("/receivers/:name", controller.UpdateReceiver) // 更新接收器
		alertmanager.DELETE("/receivers/:name", controller.DeleteReceiver) // 删除接收器
		alertmanager.POST("/receivers/:name/test", controller.TestReceiver) // 测试接收器

		// 静默管理
		alertmanager.GET("/silences", controller.GetSilences)          // 获取静默列表
		alertmanager.POST("/silences", controller.CreateSilence)       // 创建静默
		alertmanager.DELETE("/silences/:id", controller.DeleteSilence) // 删除静默
	}

	// 配置同步API组
	sync := r.Group("/api/v1/sync")
	sync.Use(middleware.CORS())

	{
		sync.POST("/config", controller.SyncConfig)                   // 同步配置
		sync.GET("/history", controller.GetSyncHistory)               // 获取同步历史
		sync.GET("/status", controller.GetSyncStatus)                 // 获取同步状态
		sync.POST("/rollback/:id", controller.RollbackConfig)         // 回滚配置
	}

	// 设备发现API组
	discovery := r.Group("/api/v1/discovery")
	discovery.Use(middleware.CORS())

	{
		discovery.POST("/scan", controller.DiscoverDevices)           // 扫描发现设备
		discovery.GET("/devices", controller.GetDiscoveredDevices)    // 获取发现的设备
		discovery.POST("/devices/:id/monitor", controller.AddToMonitoring) // 添加到监控
		discovery.DELETE("/devices/:id", controller.RemoveDiscoveredDevice) // 移除发现的设备
		discovery.GET("/coverage", controller.GetMonitoringCoverage)  // 获取监控覆盖率报告
		discovery.GET("/rules", controller.GetDiscoveryRules)         // 获取发现规则
		discovery.POST("/rules", controller.CreateDiscoveryRule)      // 创建发现规则
		discovery.PUT("/rules/:id", controller.UpdateDiscoveryRule)   // 更新发现规则
		discovery.DELETE("/rules/:id", controller.DeleteDiscoveryRule) // 删除发现规则
	}

	// 智能推荐API组
	recommendations := r.Group("/api/v1/recommendations")
	recommendations.Use(middleware.CORS())

	{
		recommendations.GET("", controller.GetRecommendations)         // 获取推荐列表
		recommendations.POST("/generate", controller.GenerateRecommendations) // 生成推荐
		recommendations.POST("/:id/apply", controller.ApplyRecommendation)     // 应用推荐
		recommendations.POST("/:id/reject", controller.RejectRecommendation)   // 拒绝推荐
		recommendations.DELETE("/:id", controller.DeleteRecommendation)        // 删除推荐
		recommendations.GET("/history", controller.GetRecommendationHistory)  // 获取推荐历史
		recommendations.GET("/analysis", controller.GetAnalysisReport)        // 获取分析报告
		recommendations.GET("/settings", controller.GetRecommendationSettings) // 获取推荐设置
		recommendations.PUT("/settings", controller.UpdateRecommendationSettings) // 更新推荐设置
	}

	// 统计分析API组
	stats := r.Group("/api/v1/alert-stats")
	stats.Use(middleware.CORS())

	{
		stats.GET("/overview", controller.GetStatsOverview)           // 获取统计概览
		stats.GET("/rules", controller.GetRuleStats)                  // 获取规则统计
		stats.GET("/alerts", controller.GetAlertStats)                // 获取告警统计
		stats.GET("/performance", controller.GetPerformanceStats)     // 获取性能统计
		stats.GET("/trends", controller.GetTrendAnalysis)             // 获取趋势分析
		stats.GET("/top-rules", controller.GetTopRules)               // 获取热门规则
		stats.GET("/slow-queries", controller.GetSlowQueries)         // 获取慢查询规则
	}

	// 健康检查和调试API
	health := r.Group("/api/v1/alert-health")
	health.Use(middleware.CORS())

	{
		health.GET("/check", controller.HealthCheck)                 // 健康检查
		health.GET("/metrics", controller.GetHealthMetrics)          // 获取健康指标
		health.GET("/connectivity", controller.CheckConnectivity)    // 检查连通性
		health.POST("/test-rule", controller.TestRule)               // 测试规则
		health.POST("/test-template", controller.TestTemplate)       // 测试模板
	}
}