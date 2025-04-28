#!/bin/bash

# 启动服务器和客户端
echo "启动MCP服务器和客户端..."
node /app/server/build/index.js &
SERVER_PID=$!

sleep 2

echo "启动MCP客户端UI..."
node /app/client/bin/client.js &
CLIENT_PID=$!

# 等待子进程完成
wait $SERVER_PID $CLIENT_PID 