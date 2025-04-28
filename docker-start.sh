#!/bin/bash

# 设置颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

echo -e "${GREEN}==== 启动MCP Inspector Docker服务 ====${NC}"

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker未安装，请先安装Docker${NC}"
    echo "安装指南: https://docs.docker.com/get-docker/"
    exit 1
fi

# 确定使用哪种docker-compose命令
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

# 检查镜像是否存在
if ! docker images | grep mcp-inspector > /dev/null; then
    echo -e "${YELLOW}未找到MCP Inspector镜像，尝试构建...${NC}"
    ./docker-build.sh
    
    # 如果构建失败，退出
    if [ $? -ne 0 ]; then
        echo -e "${RED}镜像构建失败，无法启动服务${NC}"
        exit 1
    fi
fi

# 启动服务
echo -e "${GREEN}正在启动MCP Inspector服务...${NC}"
$COMPOSE_CMD up -d

# 检查启动状态
if [ $? -ne 0 ]; then
    echo -e "${RED}启动失败${NC}"
    exit 1
fi

# 等待服务就绪
echo -e "${YELLOW}等待服务就绪...${NC}"
for i in {1..30}; do
    if curl -s http://localhost:6277/health > /dev/null; then
        echo -e "${GREEN}服务已就绪!${NC}"
        break
    fi
    
    if [ $i -eq 30 ]; then
        echo -e "${YELLOW}服务启动可能需要较长时间，请稍后访问以下地址检查状态${NC}"
    fi
    
    sleep 1
done

# 提示用户如何访问服务
echo -e "${GREEN}MCP Inspector服务已启动!${NC}"
echo "======================= 访问方式 ======================="
echo "MCP Inspector UI: http://localhost:6274"
echo "MCP Proxy健康检查: http://localhost:6277/health"
echo "========================================================"
echo -e "${YELLOW}查看日志:${NC} $COMPOSE_CMD logs -f"
echo -e "${YELLOW}停止服务:${NC} $COMPOSE_CMD down" 