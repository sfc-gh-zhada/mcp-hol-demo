# Snowflake Managed MCP HOL

Public workshop materials for a governed neobank support agent built with a Snowflake Managed MCP Server.

The lab exposes four narrowly scoped Snowflake tools:

- `classify_intent`: classifies a customer message with a fine-tuned model
- `search_help_articles`: searches a synthetic help-centre knowledge base
- `get_transaction_status`: looks up one synthetic case by reference ID
- `file_ticket`: creates and routes a support incident

All included customer records and support content are synthetic. This repository contains no credentials, account hostnames, or executed notebook output.

## Prerequisites

- A Snowflake account with Managed MCP Server, Cortex Search, and Cortex fine-tuning access
- A warehouse named `COCO_WH`, or equivalent edits to the SQL and notebook
- A role allowed to create the objects used by the lab
- The public Banking77 dataset loaded into:
  - `MCP_HOL.SUPPORT.B77_TRAIN`
  - `MCP_HOL.SUPPORT.B77_PROBE`
  - `MCP_HOL.SUPPORT.B77_TEST`

The expected training-table columns are `TEXT` and `LABEL`. Banking77 is published under CC BY 4.0.

## Setup

Run the scripts in this order:

1. `sql/00_setup.sql`
2. `sql/00_cases_and_status.sql`
3. `sql/03_search_help_articles.sql`
4. `sql/06_finetune_intent.sql`
5. `sql/02_case_ticket_and_routing.sql`
6. `sql/04_mcp_server.sql`

The fine-tuning job in step 4 is asynchronous. The procedure can be created immediately, but wait for the job to succeed before calling `CLASSIFY_INTENT_PROC` or creating the MCP server.

## Open In Snowflake Workspaces

1. In Snowsight, open **Projects > Workspaces**.
2. Select **From Git repository**.
3. Paste `https://github.com/sfc-gh-zhada/mcp-hol-demo`.
4. Select **Public repository**. No GitHub credentials are required.
5. Choose an API integration approved by your Snowflake administrator.
6. Open `mcp_hol_demo.ipynb`.

## Security Model

The MCP server exposes only the four declared tools. The `CUSTOMER_AGENT` role receives tool usage privileges but no direct `SELECT` privilege on the underlying case or ticket tables. The write action creates a support incident only; it does not move money or call an external service.

The sample creates or replaces objects in the `MCP_HOL` database. Use a dedicated workshop account or schema, and review object names before running it in a shared environment.

## License

The workshop code in this repository is provided under the MIT License. Banking77 remains subject to its own CC BY 4.0 license and attribution requirements.