#!/usr/bin/env node

import cors from "cors";
import { parseArgs } from "node:util";
import { parse as shellParseArgs } from "shell-quote";

import {
  SSEClientTransport,
  SseError,
} from "@modelcontextprotocol/sdk/client/sse.js";
import {
  StdioClientTransport,
  getDefaultEnvironment,
} from "@modelcontextprotocol/sdk/client/stdio.js";
import { Transport } from "@modelcontextprotocol/sdk/shared/transport.js";
import { SSEServerTransport } from "@modelcontextprotocol/sdk/server/sse.js";
import express from "express";
import { findActualExecutable } from "spawn-rx";
import mcpProxy from "./mcpProxy.js";

// 替换为一个空的数组，后面会动态添加所有headers
const SSE_HEADERS_PASSTHROUGH: string[] = [];

const defaultEnvironment = {
  ...getDefaultEnvironment(),
  ...(process.env.MCP_ENV_VARS ? JSON.parse(process.env.MCP_ENV_VARS) : {}),
};

const { values } = parseArgs({
  args: process.argv.slice(2),
  options: {
    env: { type: "string", default: "" },
    args: { type: "string", default: "" },
  },
});

const app = express();
app.use(cors());

let webAppTransports: SSEServerTransport[] = [];

const createTransport = async (req: express.Request): Promise<Transport> => {
  const query = req.query;
  console.log("Query parameters:", query);

  // 记录所有请求头
  console.log("Request headers:", req.headers);

  const transportType = query.transportType as string;

  if (transportType === "stdio") {
    const command = query.command as string;
    const origArgs = shellParseArgs(query.args as string) as string[];
    const queryEnv = query.env ? JSON.parse(query.env as string) : {};
    const env = { ...process.env, ...defaultEnvironment, ...queryEnv };

    const { cmd, args } = findActualExecutable(command, origArgs);

    console.log(`Stdio transport: command=${cmd}, args=${args}`);

    const transport = new StdioClientTransport({
      command: cmd,
      args,
      env,
      stderr: "pipe",
    });

    await transport.start();

    console.log("Spawned stdio transport");
    return transport;
  } else if (transportType === "sse") {
    const url = query.url as string;
    // 打印完整的URL路径
    console.log(`SSE transport: Full URL=${url}`);
    
    const headers: HeadersInit = {
      Accept: "text/event-stream",
    };

    // 获取所有请求头，而不仅仅是authorization
    Object.keys(req.headers).forEach(key => {
      if (req.headers[key] === undefined) {
        return;
      }

      const value = req.headers[key];
      headers[key] = Array.isArray(value) ? value[value.length - 1] : value;
      // 将这个头添加到SSE_HEADERS_PASSTHROUGH中，以便后续请求也能传递
      if (!SSE_HEADERS_PASSTHROUGH.includes(key)) {
        SSE_HEADERS_PASSTHROUGH.push(key);
      }
    });

    console.log(`SSE transport: url=${url}, headers=${JSON.stringify(headers, null, 2)}`);

    try {
      const fullUrl = new URL(url);
      console.log(`SSE transport: Connecting to endpoint: ${fullUrl.toString()}`);
      
      const transport = new SSEClientTransport(fullUrl, {
        eventSourceInit: {
          fetch: (url, init) => fetch(url, { ...init, headers }),
        },
        requestInit: {
          headers,
        },
      });
      await transport.start();

      console.log("Connected to SSE transport successfully");
      return transport;
    } catch (error) {
      console.error(`Failed to connect to SSE endpoint: ${url}`, error);
      throw error;
    }
  } else {
    console.error(`Invalid transport type: ${transportType}`);
    throw new Error("Invalid transport type specified");
  }
};

let backingServerTransport: Transport | undefined;

app.get("/sse", async (req, res) => {
  try {
    console.log("New SSE connection");

    try {
      await backingServerTransport?.close();
      backingServerTransport = await createTransport(req);
    } catch (error) {
      if (error instanceof SseError && error.code === 401) {
        console.error(
          "Received 401 Unauthorized from MCP server:",
          error.message,
        );
        res.status(401).json(error);
        return;
      }

      throw error;
    }

    console.log("Connected MCP client to backing server transport");

    const webAppTransport = new SSEServerTransport("/message", res);
    console.log("Created web app transport");

    webAppTransports.push(webAppTransport);
    console.log("Created web app transport");

    await webAppTransport.start();

    if (backingServerTransport instanceof StdioClientTransport) {
      backingServerTransport.stderr!.on("data", (chunk) => {
        webAppTransport.send({
          jsonrpc: "2.0",
          method: "notifications/stderr",
          params: {
            content: chunk.toString(),
          },
        });
      });
    }

    mcpProxy({
      transportToClient: webAppTransport,
      transportToServer: backingServerTransport,
    });

    console.log("Set up MCP proxy");
  } catch (error) {
    console.error("Error in /sse route:", error);
    res.status(500).json(error);
  }
});

app.post("/message", async (req, res) => {
  try {
    const sessionId = req.query.sessionId;
    console.log(`Received message for sessionId ${sessionId}`);

    const transport = webAppTransports.find((t) => t.sessionId === sessionId);
    if (!transport) {
      res.status(404).end("Session not found");
      return;
    }
    await transport.handlePostMessage(req, res);
  } catch (error) {
    console.error("Error in /message route:", error);
    res.status(500).json(error);
  }
});

app.get("/health", (req, res) => {
  res.json({
    status: "ok",
  });
});

app.get("/config", (req, res) => {
  try {
    res.json({
      defaultEnvironment,
      defaultCommand: values.env,
      defaultArgs: values.args,
    });
  } catch (error) {
    console.error("Error in /config route:", error);
    res.status(500).json(error);
  }
});

const PORT = process.env.PORT || 6277;

const server = app.listen(PORT);
server.on("listening", () => {
  console.log(`⚙️ Proxy server listening on port ${PORT}`);
});
server.on("error", (err) => {
  if (err.message.includes(`EADDRINUSE`)) {
    console.error(`❌  Proxy Server PORT IS IN USE at port ${PORT} ❌ `);
  } else {
    console.error(err.message);
  }
  process.exit(1);
});
