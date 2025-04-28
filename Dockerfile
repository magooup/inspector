# 使用官方 Node.js 镜像
FROM node:18 as builder

# 设置工作目录
WORKDIR /app

# 设置环境变量
ENV NODE_ENV=production
ENV ROLLUP_SKIP_NODEJS_NATIVE=true
ENV NODE_OPTIONS="--no-experimental-fetch"

# 复制package.json和锁定文件
COPY package*.json ./
COPY .npmrc ./

# 复制子项目的package.json
COPY client/package*.json ./client/
COPY server/package*.json ./server/
COPY cli/package*.json ./cli/

# 安装依赖
RUN npm install --omit=optional

# 复制源代码
COPY . .

# 为客户端创建必要的目录结构
RUN mkdir -p client/dist/assets && \
    cp -r client/public/* client/dist/ || true && \
    echo "{}" > client/dist/package.json

# 仅构建服务器和CLI组件
RUN cd server && npm run build && \
    cd ../cli && npm run build

# 构建运行阶段容器
FROM node:18-slim

# 设置阿里云镜像源
RUN echo "deb https://mirrors.aliyun.com/debian/ bullseye main non-free contrib" > /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian-security bullseye-security main" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian/ bullseye-updates main non-free contrib" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian/ bullseye-backports main non-free contrib" >> /etc/apt/sources.list

WORKDIR /app

# 安装运行时所需的工具
RUN apt-get update && apt-get install -y --no-install-recommends wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 复制package.json文件
COPY package*.json ./
COPY .npmrc ./
COPY client/package*.json ./client/
COPY server/package*.json ./server/
COPY cli/package*.json ./cli/

# 安装生产环境依赖
RUN npm ci --omit=dev --ignore-scripts --omit=optional

# 复制构建好的文件
COPY --from=builder /app/server/build ./server/build
COPY --from=builder /app/cli/build ./cli/build
COPY --from=builder /app/client/dist ./client/dist
COPY --from=builder /app/client/bin ./client/bin

# 设置环境变量
ENV NODE_ENV=production
ENV CLIENT_PORT=6274
ENV SERVER_PORT=6277

# 暴露端口
EXPOSE 6274 6277

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:6277/health || exit 1

# 启动命令
CMD ["node", "server/build/index.js"]