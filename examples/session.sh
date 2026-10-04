#!/usr/bin/env sh
# Minimal JSON-RPC session against the hosted Daniks.AI MCP server.
# Usage: DANIKS_TOKEN=... ./session.sh
#
# Streamable HTTP servers normally accept a sequence of calls on one
# connection. curl opens a fresh connection per call, so the server is polled
# statelessly here: initialize, list tools, call one read tool. Some servers
# require the initialize handshake on the same connection — if so, run your
# client's native MCP transport instead (see the README).
set -eu

URL="${DANIKS_URL:-https://app.daniks.ai/mcp}"
AUTH="Authorization: Bearer ${DANIKS_TOKEN:?set DANIKS_TOKEN}"
CT="Content-Type: application/json"
AC="Accept: application/json, text/event-stream"

post() {
  curl -s "$URL" -H "$AUTH" -H "$CT" -H "$AC" -d "$1"
  printf '\n---\n'
}

post '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"curl-example","version":"0.1.0"}}}'
post '{"jsonrpc":"2.0","method":"notifications/initialized"}'
post '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'
post '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"list_sellers","arguments":{}}}'
