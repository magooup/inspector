# MCP Inspector Docker 使用说明

本文档说明如何使用Docker方式运行MCP Inspector测试工具。

## 前置条件

- 安装 [Docker](https://docs.docker.com/get-docker/)
- 安装 [Docker Compose](https://docs.docker.com/compose/install/) (如果使用的Docker版本未内置compose插件)

## 构建和运行

### 1. 使用docker-compose（推荐）

```bash
# 构建并启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

### 2. 使用Docker命令

```bash
# 构建镜像
docker build -t mcp-inspector .

# 运行容器
docker run -d --name mcp-inspector -p 6274:6274 -p 6277:6277 mcp-inspector

# 查看日志
docker logs -f mcp-inspector

# 停止并删除容器
docker stop mcp-inspector
docker rm mcp-inspector
```

## 访问服务

在浏览器中访问：
- MCP Inspector UI：http://localhost:6274
- MCP Proxy健康检查：http://localhost:6277/health

## 测试MCP服务器

一旦MCP Inspector启动，您可以通过在浏览器访问UI界面（http://localhost:6274）来测试您的MCP服务器。

## 持久化配置

配置数据会被保存到一个Docker卷中，以便在容器重启后保持配置。如果您需要清除所有配置数据：

```bash
docker-compose down -v
```

## 注意事项

1. 默认端口是6274（UI界面）和6277（MCP代理服务器）。如需修改，请编辑docker-compose.yml或使用Docker命令时指定不同的端口映射。
2. 在实际部署中，应确保这些端口没有暴露给不信任的网络环境。 