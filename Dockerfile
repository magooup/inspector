# ---------- 构建阶段 ----------
  FROM node:22-alpine AS builder

  WORKDIR /app
  
  # 复制package.json和锁定文件
  COPY package*.json ./
  COPY .npmrc ./
  
  # 复制子项目package.json
  COPY client/package*.json ./client/
  COPY server/package*.json ./server/
  COPY cli/package*.json ./cli/
  
  # 安装依赖，只安装 production 依赖（如果你要 dev依赖就把 --omit=dev 去掉）
  RUN npm ci
  
  # 复制源代码
  COPY . .
  
  # 构建
  RUN npm run build
  
  
  # ---------- 运行阶段 ----------
  FROM node:22-alpine AS runner
  
  WORKDIR /app
  
  # 只拷贝 build 后产物，不拷贝 node_modules
  COPY --from=builder /app/server/build ./server/build
  
  # 如果你的 server 还需要某些资源（比如 config 文件），也可以加复制命令
  # COPY --from=builder /app/server/config ./server/config
  
  # 安装运行时需要的 node_modules
  # 这里如果 server 有 package.json 就单独 npm install
  COPY server/package*.json ./server/
  WORKDIR /app/server
  RUN npm install --omit=dev
  
  # 回到 app 目录
  WORKDIR /app
  
  # 暴露端口
  EXPOSE 6277
  
  # 环境变量
  ENV NODE_ENV=production
  ENV SERVER_PORT=6277
  
  # 健康检查
  HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:6277/health || exit 1
  
  # 启动 server
  CMD ["node", "server/build/index.js"]