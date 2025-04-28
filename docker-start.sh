#!/bin/bash

# 设置颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker未安装，请先安装Docker${NC}"
    echo "安装指南: https://docs.docker.com/get-docker/"
    exit 1
fi

# 检查docker-compose命令是否可用
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}错误: Docker Compose未安装，请先安装${NC}"
    echo "安装指南: https://docs.docker.com/compose/install/"
    exit 1
fi

# 确定使用哪种docker-compose命令
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

# 启动服务
echo -e "${GREEN}正在启动MCP Inspector服务...${NC}"
$COMPOSE_CMD up -d

# 提示用户如何访问服务
echo -e "${GREEN}MCP Inspector服务已启动!${NC}"
echo "======================= 访问方式 ======================="
echo "MCP Inspector UI: http://localhost:6274"
echo "MCP Proxy健康检查: http://localhost:6277/health"
echo "========================================================"
echo -e "${YELLOW}查看日志:${NC} $COMPOSE_CMD logs -f"
echo -e "${YELLOW}停止服务:${NC} $COMPOSE_CMD down" 