FROM node:22-bookworm-slim

WORKDIR /app

# 复制package.json和锁定文件
COPY package*.json ./
COPY .npmrc ./

# 复制子项目的package.json
COPY client/package*.json ./client/
COPY server/package*.json ./server/
COPY cli/package*.json ./cli/

# 设置环境变量解决依赖问题
ENV NPM_CONFIG_OPTIONAL=false

# 安装wget用于健康检查
RUN apt-get update && apt-get install -y --no-install-recommends wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 安装依赖
RUN npm ci --omit=optional

# 复制源代码
COPY . .

# 构建项目
RUN npm run build

# 精简生产环境依赖
RUN npm prune --production

# 暴露默认端口
EXPOSE 6274 6277

# 设置环境变量
ENV NODE_ENV=production
ENV CLIENT_PORT=6274
ENV SERVER_PORT=6277

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:6277/health || exit 1

# 启动命令
CMD ["node", "server/build/index.js"]