# AGENTS.md

Guidance for human and AI contributors working in this repository.

## 1. Purpose

Paperclip is a control plane for AI-agent companies.
The current implementation target is V1 and is defined in `doc/SPEC-implementation.md`.

## 2. Read This First

Before making changes, read in this order:

1. `doc/GOAL.md`
2. `doc/PRODUCT.md`
3. `doc/SPEC-implementation.md`
4. `doc/DEVELOPING.md`
5. `doc/DATABASE.md`

`doc/SPEC.md` is long-horizon product context.
`doc/SPEC-implementation.md` is the concrete V1 build contract.

## 3. Repo Map

- `server/`: Express REST API and orchestration services
- `ui/`: React + Vite board UI
- `packages/db/`: Drizzle schema, migrations, DB clients
- `packages/shared/`: shared types, constants, validators, API path constants
- `doc/`: operational and product docs

## 4. Dev Setup (Auto DB)

Use embedded PGlite in dev by leaving `DATABASE_URL` unset.

```sh
pnpm install
pnpm dev
```

This starts:

- API: `http://localhost:3100`
- UI: `http://localhost:3100` (served by API server in dev middleware mode)

Quick checks:

```sh
curl http://localhost:3100/api/health
curl http://localhost:3100/api/companies
```

Reset local dev DB:

```sh
rm -rf data/pglite
pnpm dev
```

## 4a. Dev Setup (Root / System PostgreSQL)

When running as root, embedded PostgreSQL is not supported. Use the system
PostgreSQL instead (already initialized at `/var/lib/paperclip/db`, port 54329).

```sh
# Start everything with one command:
./scripts/start-dev.sh
```

Or manually:

```sh
# Start system postgres (if not running)
su -s /bin/bash postgres -c \
  "/usr/lib/postgresql/16/bin/pg_ctl -D /var/lib/paperclip/db -l /var/lib/paperclip/postgres.log -o '-p 54329' start"

# Start Paperclip server (config reads from ~/.paperclip/instances/default/config.json)
PAPERCLIP_MIGRATION_PROMPT=never pnpm dev:once
```

The config at `~/.paperclip/instances/default/config.json` already points to
`postgresql://paperclip@localhost:54329/paperclip`.

### Installed Agents (Company: orchidea.digital / MYC)

orchidea.digital is a dev/tech agency. Agents are configured to run client software projects.
Agent instructions: `agents/<slug>/AGENTS.md`. Company manifest: `companies/orchidea-digital/manifest.json`.

| Agent        | Role      | Reports To  | Adapter       | Instructions                              |
|-------------|-----------|-------------|---------------|-------------------------------------------|
| CEO          | ceo       | —           | claude_local  | agents/ceo/AGENTS.md                      |
| CTO          | cto       | CEO         | claude_local  | agents/cto/AGENTS.md                      |
| PM           | pm        | CEO         | claude_local  | agents/pm/AGENTS.md                       |
| ClaudeCoder  | engineer  | CTO         | claude_local  | agents/claudecoder/AGENTS.md              |
| CodexCoder   | engineer  | CTO         | codex_local   | agents/codexcoder/AGENTS.md               |
| Designer     | designer  | CTO         | claude_local  | agents/designer/AGENTS.md                 |
| QA           | qa        | CTO         | claude_local  | agents/qa/AGENTS.md                       |

To get shell exports for an agent (e.g. to run a heartbeat manually):

```sh
COMPANY_ID="ecbdbf73-50ed-40a1-8625-b756c3e58d15"
pnpm paperclipai agent local-cli claudecoder --company-id $COMPANY_ID
```

## 5. Core Engineering Rules

1. Keep changes company-scoped.
Every domain entity should be scoped to a company and company boundaries must be enforced in routes/services.

2. Keep contracts synchronized.
If you change schema/API behavior, update all impacted layers:
- `packages/db` schema and exports
- `packages/shared` types/constants/validators
- `server` routes/services
- `ui` API clients and pages

3. Preserve control-plane invariants.
- Single-assignee task model
- Atomic issue checkout semantics
- Approval gates for governed actions
- Budget hard-stop auto-pause behavior
- Activity logging for mutating actions

4. Do not replace strategic docs wholesale unless asked.
Prefer additive updates. Keep `doc/SPEC.md` and `doc/SPEC-implementation.md` aligned.

## 6. Database Change Workflow

When changing data model:

1. Edit `packages/db/src/schema/*.ts`
2. Ensure new tables are exported from `packages/db/src/schema/index.ts`
3. Generate migration:

```sh
pnpm db:generate
```

4. Validate compile:

```sh
pnpm -r typecheck
```

Notes:
- `packages/db/drizzle.config.ts` reads compiled schema from `dist/schema/*.js`
- `pnpm db:generate` compiles `packages/db` first

## 7. Verification Before Hand-off

Run this full check before claiming done:

```sh
pnpm -r typecheck
pnpm test:run
pnpm build
```

If anything cannot be run, explicitly report what was not run and why.

## 8. API and Auth Expectations

- Base path: `/api`
- Board access is treated as full-control operator context
- Agent access uses bearer API keys (`agent_api_keys`), hashed at rest
- Agent keys must not access other companies

When adding endpoints:

- apply company access checks
- enforce actor permissions (board vs agent)
- write activity log entries for mutations
- return consistent HTTP errors (`400/401/403/404/409/422/500`)

## 9. UI Expectations

- Keep routes and nav aligned with available API surface
- Use company selection context for company-scoped pages
- Surface failures clearly; do not silently ignore API errors

## 10. Definition of Done

A change is done when all are true:

1. Behavior matches `doc/SPEC-implementation.md`
2. Typecheck, tests, and build pass
3. Contracts are synced across db/shared/server/ui
4. Docs updated when behavior or commands change
