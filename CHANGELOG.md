# 更新日志 (CHANGELOG)

## [Unreleased]

## [0.1.0] - 2024-10-25

### 改进

- **UI 改进**：
  - 将 "Bearer Token" 输入框改为 "Header Value"
  - "Authentication" 按钮文本改为更通用的 "Headers"
  - 改进了UI界面的变量和属性命名，使其更加一致

- **后端增强**：
  - 补充详细日志，支持打印出请求的完整URL路径
  - 所有HTTP请求头都会被传递，而不仅仅是 authorization 头
  - 优化错误处理，提供更详细的连接错误信息

- **功能优化**：
  - 修改了token处理逻辑，不再自动添加 "Bearer " 前缀
  - 确保使用填入的URL来拼接请求地址
  - 更新了本地存储键名，使其更符合实际用途（从 lastBearerToken 更新为 lastHeaderValue）
  
### 技术细节

- 修改了 `client/src/components/Sidebar.tsx` 中的UI组件
- 优化了 `client/src/lib/hooks/useConnection.ts` 中的连接逻辑
- 增强了 `server/src/index.ts` 中的HTTP请求处理和日志记录
- 更新了 `client/src/App.tsx` 中的本地存储键名 