#!/bin/bash

# 设置颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

echo -e "${GREEN}==== 构建MCP Inspector Docker镜像 ====${NC}"

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker未安装${NC}"
    echo "请先安装Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# 检查docker-compose是否可用
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${YELLOW}警告: Docker Compose未安装${NC}"
    echo "建议安装Docker Compose: https://docs.docker.com/compose/install/"
fi

# 清除可能存在的容器
echo -e "${YELLOW}清理可能存在的旧容器...${NC}"
docker-compose down 2>/dev/null || docker compose down 2>/dev/null || true

# 构建镜像
echo -e "${GREEN}开始构建Docker镜像...${NC}"
echo -e "${YELLOW}这可能需要几分钟时间...${NC}"

docker build --no-cache -t mcp-inspector . 

# 检查构建结果
if [ $? -ne 0 ]; then
    echo -e "${RED}构建失败${NC}"
    exit 1
fi

echo -e "${GREEN}构建成功!${NC}"
echo -e "可以使用以下命令启动服务:"
echo -e "${YELLOW}docker-compose up -d${NC} 或 ${YELLOW}docker compose up -d${NC}"
echo -e "或者直接运行启动脚本: ${YELLOW}./docker-start.sh${NC}" 