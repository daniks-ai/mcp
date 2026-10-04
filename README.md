# Daniks.AI Amazon Ads — MCP server

Manage Amazon Ads ACoS targets and read Sponsored Products campaign
performance for your Daniks.AI-connected Amazon seller accounts — from any
MCP client (Claude Code, Claude Desktop, Cursor, or your own agent).

- **Server URL:** `https://app.daniks.ai/mcp`
- **Transport:** Streamable HTTP, protocol version `2025-06-18`
- **Auth:** Bearer token — a personal token from the Daniks.AI dashboard, or
  an OAuth 2.1 access token (dynamic client registration supported)
- **Discovery:** [`/.well-known/mcp/server-card.json`](https://app.daniks.ai/.well-known/mcp/server-card.json)
  and [`/.well-known/mcp.json`](https://app.daniks.ai/.well-known/mcp.json)
- **Plan requirement:** MCP access is included from the
  [Plus plan](https://daniks.ai/#pricing) and higher. Special Rules tools
  additionally require the Growth plan or higher.

This repository documents the hosted server and provides copy-paste client
examples. The server implementation itself runs at app.daniks.ai.

## Quick start

1. Create a token in the Daniks.AI dashboard: **app.daniks.ai/mcp/tokens/**
   (Dashboard → MCP tokens). Choose a `read` token for trying things out, or
   `readwrite` when you want an agent to change targets.
2. Add the server to your MCP client with the URL above and the token.

### Claude Code

```sh
claude mcp add --transport http daniks-amazon-ads \
  --header "Authorization: Bearer DANIKS_TOKEN" \
  https://app.daniks.ai/mcp
```

### Claude Desktop / Claude.ai

Claude supports remote MCP servers ("Connectors"): add a custom connector
with the server URL `https://app.daniks.ai/mcp`. When the client follows the
OAuth 2.1 discovery documents, you can authorize with your Daniks.AI account
instead of pasting a token.

### Any JSON-RPC client

```sh
curl -s https://app.daniks.ai/mcp \
  -H "Authorization: Bearer DANIKS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
```

See [examples/](examples/) for a minimal shell session
(initialize → tools/list → tools/call).

## Tools

Read tools work with any token; `update_*` tools require a `readwrite`
token. Monetary values in stats are in marketplace currency, with
`*_base_currency` fields pre-converted to the seller's base currency.

### Accounts and structure

| Tool | What it does |
|---|---|
| `list_sellers` | Seller accounts the token can access; use the returned `code` as `seller_code` elsewhere. |
| `list_marketplaces` | Marketplaces per seller with the default ACoS and the ad mode: `disabled` / `blanket` / `whitelist`. |
| `list_listings` | SKU+marketplace rows with inventory, pricing, 30-day sales/ads aggregates, effective target ACoS; filters by country, ASIN, SKU, product, brand. |
| `list_campaigns` | Campaign metadata (kind, state, budget, targeting, advertised SKU/ASIN); no numbers — pair with `get_ads_stats`. |

### Performance (read)

| Tool | What it does |
|---|---|
| `get_ads_status` | Per-product advertising status: default ACoS, override, effective ACoS, resolution rules. |
| `list_product_acos` | Per-country ACoS overrides and campaign-type switches per product. |
| `get_listing_performance` | Full snapshot for one listing over a date range: unit economics, ads config, and aggregate impressions/clicks/orders/ACoS/ROAS/CTR/CPC/CVR; optional per-campaign breakdown. |
| `get_ads_stats` | Aggregated ads stats over a date range with optional per-day / per-marketplace / per-campaign breakdown. |
| `get_listing_target_ads` | Custom targeting on a listing: Target Ads ASINs, Target Ads Keywords, Negative Keywords, AI-managed negatives (read-only). |

### Targets and controls (readwrite)

| Tool | What it does |
|---|---|
| `update_marketplace_acos` | Change the marketplace default ACoS and `ad_active`. `default_acos=0` + `ad_active=true` = whitelist mode. |
| `update_product_acos` | Bulk per-country ACoS overrides per product; `null` clears an override back to the marketplace default. |
| `update_product_campaign_controls` | Per-product switches: `auto_campaigns_enabled` (false parks the auto campaign at minimum bids), `sd_campaigns_enabled` (false archives Sponsored Display). |
| `update_listing_target_ads` | Modify Target Ads ASINs / Keywords / Negative Keywords with `replace` / `add` / `remove` operations. |

### Special Rules (Growth plan and higher)

| Tool | What it does |
|---|---|
| `list_special_rules` | Client-defined keywords with their own target ACoS, whether each rule is applied, and what the last run matched. |
| `create_special_rule` | Keywords (e.g. brand defense) with their own target ACoS, optionally scoped to products and marketplaces. |
| `update_special_rule` | Change a rule by id; omitted fields are untouched. |
| `delete_special_rule` | Delete a rule; its routing negatives are withdrawn on the next run. |

Special Rules never create keywords: the platform-managed keywords that match
a rule bid against the rule's target, and matching searches are routed with
negatives away from the other ad groups. `acos=0` switches those searches off.

## Example agent prompts

- "Show my worst ACoS marketplace last 30 days and pause ads there."
- "For my DE marketplace, list products whose effective ACoS is above 30% and
  set them to 25%."
- "Create a Special Rule for my brand name at 15% ACoS scoped to the US."
- "Which enabled campaigns had zero impressions in the last 14 days?"

## Security notes

- Tokens are scoped (`read` or `readwrite`); create the narrowest one that
  does the job and revoke it in the dashboard when done.
- The OAuth 2.1 flow supports dynamic client registration for clients that
  store no secrets (RFC 7591), with metadata published per RFC 9728.

## About Daniks.AI

Daniks.AI builds and manages Amazon Sponsored Products / Display campaigns
toward your per-product target ACoS, while your existing manual campaigns
stay untouched. [Website](https://daniks.ai) ·
[Free break-even ACoS calculator](https://daniks.ai/tools/amazon-acos-calculator) ·
[Partner program](https://daniks.ai/partners)

## License

Documentation and examples in this repository: [MIT](LICENSE).
