#!/bin/bash

# 设置颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

echo -e "${GREEN}==== 停止MCP Inspector Docker服务 ====${NC}"

# 确定使用哪种docker-compose命令
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

echo -e "${YELLOW}正在停止MCP Inspector服务...${NC}"
$COMPOSE_CMD down

# 检查停止状态
if [ $? -ne 0 ]; then
    echo -e "${RED}服务停止失败，尝试直接停止容器${NC}"
    docker stop mcp-inspector
    docker rm mcp-inspector
fi

echo -e "${GREEN}MCP Inspector服务已停止${NC}"

# 询问是否要清除卷数据
echo -e "${YELLOW}是否要清除所有配置数据？(y/n)${NC}"
read -r CLEAN_VOLUMES

if [[ $CLEAN_VOLUMES == "y" || $CLEAN_VOLUMES == "Y" ]]; then
    echo -e "${RED}正在删除所有配置数据...${NC}"
    $COMPOSE_CMD down -v
    echo -e "${GREEN}所有配置数据已清除${NC}"
fi 