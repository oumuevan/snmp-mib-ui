#!/bin/bash

echo "🧪 测试导航栏功能..."

# 测试主要页面
echo "📊 测试主要页面:"
echo "  主页: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)"
echo "  MIB管理: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/mibs)"
echo "  告警规则: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/alert-rules)"
echo "  监控安装器: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/monitoring-installer)"
echo "  设备管理: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/devices)"

echo ""
echo "📋 测试子页面:"
echo "  OID浏览器: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/mibs/oid-browser)"
echo "  MIB导入导出: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/mibs/import-export)"
echo "  配置生成器: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/config-gen)"
echo "  设备模板: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/devices/templates)"
echo "  SNMP测试: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/devices/testing)"

echo ""
echo "🔧 测试工具页面:"
echo "  OID转换器: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/tools/oid-converter)"
echo "  SNMP Walker: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/tools/snmp-walker)"
echo "  配置对比: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/tools/config-diff)"

echo ""
echo "⚙️ 测试系统管理:"
echo "  设备发现: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/discovery)"
echo "  资产管理: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/assets)"
echo "  用户管理: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/users)"
echo "  系统设置: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/settings)"

echo ""
echo "🎉 导航栏测试完成！"
echo "✅ 所有200状态码表示页面正常"
echo "⚠️  404状态码表示页面不存在但路由正常"
echo "❌ 500状态码表示页面有错误"

echo ""
echo "🌐 访问地址: http://localhost:3000"
echo "💡 现在你可以点击导航栏的任意菜单项进行测试！"