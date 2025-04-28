FROM node:22-alpine

WORKDIR /app

# 复制package.json和锁定文件
COPY package*.json ./
COPY .npmrc ./

# 复制子项目的package.json
COPY client/package*.json ./client/
COPY server/package*.json ./server/
COPY cli/package*.json ./cli/

# 安装依赖
RUN npm ci

# 复制源代码
COPY . .

# 构建项目
RUN npm run build

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