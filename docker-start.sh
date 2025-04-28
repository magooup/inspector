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

# 询问是否需要设置代理
echo -e "${YELLOW}是否需要配置网络代理？(y/n)${NC}"
read -r USE_PROXY

if [[ $USE_PROXY == "y" || $USE_PROXY == "Y" ]]; then
    # 设置默认代理地址
    DEFAULT_PROXY="http://127.0.0.1:7890"
    DEFAULT_SOCKS="socks5://127.0.0.1:7890"
    
    echo -e "${YELLOW}请输入HTTP代理地址 (默认: $DEFAULT_PROXY):${NC}"
    read -r HTTP_PROXY
    HTTP_PROXY=${HTTP_PROXY:-$DEFAULT_PROXY}
    
    echo -e "${YELLOW}请输入HTTPS代理地址 (默认: $DEFAULT_PROXY):${NC}"
    read -r HTTPS_PROXY
    HTTPS_PROXY=${HTTPS_PROXY:-$DEFAULT_PROXY}
    
    echo -e "${YELLOW}请输入SOCKS代理地址 (默认: $DEFAULT_SOCKS):${NC}"
    read -r ALL_PROXY
    ALL_PROXY=${ALL_PROXY:-$DEFAULT_SOCKS}
    
    # 如果运行在Docker中，修改代理地址中的localhost为host.docker.internal
    HTTP_PROXY=$(echo "$HTTP_PROXY" | sed 's/127.0.0.1/host.docker.internal/g' | sed 's/localhost/host.docker.internal/g')
    HTTPS_PROXY=$(echo "$HTTPS_PROXY" | sed 's/127.0.0.1/host.docker.internal/g' | sed 's/localhost/host.docker.internal/g')
    ALL_PROXY=$(echo "$ALL_PROXY" | sed 's/127.0.0.1/host.docker.internal/g' | sed 's/localhost/host.docker.internal/g')
    
    # 修改docker-compose.yml文件以添加代理配置
    echo -e "${GREEN}配置代理设置...${NC}"
    sed -i.bak -e "s/# - https_proxy=.*/- https_proxy=$HTTPS_PROXY/" \
              -e "s/# - http_proxy=.*/- http_proxy=$HTTP_PROXY/" \
              -e "s/# - all_proxy=.*/- all_proxy=$ALL_PROXY/" docker-compose.yml
    
    echo -e "${GREEN}已设置以下代理:${NC}"
    echo "HTTP代理: $HTTP_PROXY"
    echo "HTTPS代理: $HTTPS_PROXY"
    echo "SOCKS代理: $ALL_PROXY"
else
    # 确保代理配置行被注释掉
    echo -e "${GREEN}跳过代理配置${NC}"
    sed -i.bak -e 's/^(\s*)-\s*https_proxy=.*/#\1- https_proxy=http:\/\/host.docker.internal:7890/' \
              -e 's/^(\s*)-\s*http_proxy=.*/#\1- http_proxy=http:\/\/host.docker.internal:7890/' \
              -e 's/^(\s*)-\s*all_proxy=.*/#\1- all_proxy=socks5:\/\/host.docker.internal:7890/' docker-compose.yml
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