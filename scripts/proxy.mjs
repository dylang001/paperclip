#!/usr/bin/env node
/**
 * Reverse proxy: 0.0.0.0:PROXY_PORT → 127.0.0.1:TARGET_PORT
 * Used to expose the Paperclip UI (bound to loopback) to the browser.
 */
import http from "node:http";

const TARGET_PORT = parseInt(process.env.TARGET_PORT ?? "3100", 10);
const PROXY_PORT = parseInt(process.env.PROXY_PORT ?? "3101", 10);

const server = http.createServer((req, res) => {
  const options = {
    hostname: "127.0.0.1",
    port: TARGET_PORT,
    path: req.url,
    method: req.method,
    headers: req.headers,
  };

  const proxy = http.request(options, (proxyRes) => {
    res.writeHead(proxyRes.statusCode, proxyRes.headers);
    proxyRes.pipe(res, { end: true });
  });

  proxy.on("error", (err) => {
    res.writeHead(502);
    res.end(`Proxy error: ${err.message}`);
  });

  req.pipe(proxy, { end: true });
});

server.listen(PROXY_PORT, "0.0.0.0", () => {
  console.log(`[proxy] Forwarding 0.0.0.0:${PROXY_PORT} → 127.0.0.1:${TARGET_PORT}`);
});
