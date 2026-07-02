# MCP HOL — Managed MCP Server Demo

Live demo for the **Snowflake Managed MCP Server** hands-on lab. A CX analyst, working in their own agent (Claude Code), investigates a live customer escalation: they search reviews, quantify the sales impact, and open a **refund-approval case** — which a **human** signs off on before any money moves.

## What's here
- `mcp_hol_demo.ipynb` — the demo notebook (open this in Snowflake Workspaces)
- `sql/01_dataset.sql` — REVIEWS + SALES_FACT seed data
- `sql/03_search_and_semantic.sql` — Cortex Search service + semantic view
- `sql/05_reframe_zendesk_case.sql` — refund-approval case model, Zendesk External Access, `CREATE_TICKET` + `APPROVE_CASE`

## Open the notebook in Workspaces
1. In Snowsight, go to **Projects » Workspaces**.
2. Open the **From Git repository** menu.
3. Paste this repo's URL, select the **Public repository** option (no auth needed).
4. Choose the API integration your admin created (`GITHUB_MCP_HOL_API`).
5. Select **Create**, then open `mcp_hol_demo.ipynb`.

## Why MCP and not a scheduled job?
A nightly "flag bad SKUs" rule should be a Snowflake Task. MCP earns its place when a **human asks unpredictable questions in the agent they already live in**, and that agent composes your governed Snowflake tools on the fly. Schedule the predictable; expose over MCP the ad-hoc, human-in-the-loop work.
