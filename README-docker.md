# MCP Inspector Docker 使用说明

本文档说明如何使用Docker方式运行MCP Inspector测试工具。

## 前置条件

- 安装 [Docker](https://docs.docker.com/get-docker/)
- 安装 [Docker Compose](https://docs.docker.com/compose/install/) (如果使用的Docker版本未内置compose插件)

## 快速开始

我们提供了简单的脚本来管理MCP Inspector的Docker运行环境：

```bash
# 构建Docker镜像
./docker-build.sh

# 启动服务（如果镜像不存在，会自动构建）
./docker-start.sh

# 停止服务
./docker-stop.sh
```

## 手动构建和运行

如果您想手动控制构建和运行过程，可以使用以下命令：

### 使用docker-compose

```bash
# 构建镜像
docker-compose build

# 构建并启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

### 使用Docker命令

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

## 技术细节

MCP Inspector的Docker环境使用了以下技术：

1. **多阶段构建**：使用两个阶段来分别进行构建和运行，减小最终镜像大小
2. **依赖解决方案**：针对Rollup在ARM架构上的问题，提供了特殊的解决方案
3. **持久化存储**：使用Docker卷存储配置数据，保证重启后配置不丢失
4. **健康检查**：配置了健康检查确保服务正常运行

## 故障排查

如果遇到问题，可以尝试以下解决方案：

1. 清理构建缓存：
   ```bash
   docker-compose build --no-cache
   ```

2. 检查容器日志：
   ```bash
   docker-compose logs -f
   ```

3. 手动操作容器：
   ```bash
   docker exec -it mcp-inspector /bin/bash
   ```

## 注意事项

1. 默认端口是6274（UI界面）和6277（MCP代理服务器）。如需修改，请编辑docker-compose.yml文件中的端口映射。
2. 在实际部署中，应确保这些端口没有暴露给不信任的网络环境。
3. 配置数据存储在Docker卷中，可以通过`docker volume ls`查看，如需清除可使用`docker-compose down -v`。

## 测试MCP服务器

一旦MCP Inspector启动，您可以通过在浏览器访问UI界面（http://localhost:6274）来测试您的MCP服务器。

## 持久化配置

配置数据会被保存到一个Docker卷中，以便在容器重启后保持配置。如果您需要清除所有配置数据：

```bash
docker-compose down -v
``` 