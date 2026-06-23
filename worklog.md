# iSecurify GRC Platform — Worklog

## Task ID: 1 — Project Setup & Source File Migration
- **Agent:** main
- **Date:** 2025-06-22
- **Description:** Extracted project from tar archive (`workspace-dad165d1-94bd-4bce-a1d4-e8abe21f82b0 (7).tar`). Copied all iSecurify GRC source files (src/lib/, src/app/api routes, src/components/app/, hooks, prisma/seed.ts, public/) from the extracted archive to the working project directory. Installed missing dependencies: `mysql2` (Prisma MySQL driver) and `mammoth` (document conversion).

## Task ID: 2 — TASK 1: MySQL Prisma Schema
- **Agent:** main
- **Date:** 2025-06-22
- **Description:** Created MySQL-ready Prisma schema at `prisma/schema.mysql.prisma` with:
  - `provider = "mysql"`
  - `@db.VarChar(191)` on 5 unique String fields: Tenant.slug, User.email, Framework.code, Session.token, PasswordReset.token
  - `@db.Text` on 15 long text fields: Policy.content, Control.description, Control.guidance, Framework.description, AuditTask.description, Risk.description, Vulnerability.description, Checklist.description, Evidence.description, AuditLog.meta, ChecklistItem.options, ChecklistItem.hint, ControlAssignment.notes, Tenant.address, User.avatarUrl
  - Schema validated successfully with Prisma CLI
  - Active `prisma/schema.prisma` kept as SQLite for local development
  - Before deployment, copy `schema.mysql.prisma` → `schema.prisma`

## Task ID: 3 — TASKS 3-7: Deployment Files (Dockerfile, entrypoint, dockerignore, compose, env)
- **Agent:** main
- **Date:** 2025-06-22
- **Description:** Created all Docker/deployment configuration files:
  - `Dockerfile` — 3-stage build (deps → builder → runner) with Bun runtime, Prisma generate, standalone output, mysql2 driver, entrypoint script
  - `docker-entrypoint.sh` — Startup script with masked DB URL logging, prisma generate, db push (idempotent), conditional SEED_DB, exec bun server.js
  - `.dockerignore` — Excludes .git, node_modules, .next, db/, .env, dev artifacts, mini-services, examples, upload
  - `docker-compose.yml` — Two-service stack (app + MySQL 8.0) with healthcheck, named volumes (mysql_data, uploads_data), env passthrough
  - `.env.example` — Fully documented env template with explanations for every variable (DATABASE_URL, NextAuth, app URLs, SEED_DB, MySQL credentials)

## Task ID: 4 — TASK 2 & 8: package.json and db.ts Updates
- **Agent:** main
- **Date:** 2025-06-22
- **Description:**
  - Added `db:deploy` script to package.json: `"db:deploy": "prisma generate && prisma db push"`
  - Updated `src/lib/db.ts` to only log queries in development: `log: process.env.NODE_ENV === 'development' ? ['query', 'error'] : ['error']`

## Task ID: 5 — TASK 9 & 10: README and Deployment Checklist
- **Agent:** main
- **Date:** 2025-06-22
- **Description:** Created comprehensive Coolify deployment README at `README.md` with all required sections: architecture overview, prerequisites, 7-step deployment guide, default credentials, Prisma commands, troubleshooting table, backups, monitoring, and a 30-item deployment checklist with checkboxes.

## Task ID: 6 — Fix: App Rendering & Database Setup
- **Agent:** main
- **Date:** 2025-06-22
- **Description:** Fixed multiple issues that caused the app to show a blank page:
  - Updated `src/app/page.tsx` with iSecurify login/app shell logic (was default empty page)
  - Updated `src/app/layout.tsx` with iSecurify metadata and Sonner toaster
  - Updated `src/app/globals.css` with iSecurify brand theme (purple/charcoal/teal palette)
  - Fixed Prisma schema fields that lost optional `?` markers during MySQL annotation removal
  - Deleted old SQLite DB, re-pushed clean schema, seeded database successfully
  - Verified login page renders correctly with all branding, form fields, and demo credentials
  - Verified login API works (POST /api/auth/login returns 200 with session cookie)
  - Simplified dev script from `next dev -p 3000 2>&1 | tee dev.log` to `next dev -p 3000`
  - Created separate `prisma/schema.mysql.prisma` for deployment (active schema stays SQLite for local dev)

## Task ID: 7-a — Fix ControlsView Import Dialog Scrollability & Add Export Functionality
- **Agent:** general-purpose
- **Date:** 2025-06-22
- **Description:** Two fixes to `src/components/app/views/ControlsView.tsx`:
  1. **Import Dialog scrollability fix:** Changed `DialogContent` to `max-w-2xl max-h-[85vh] flex flex-col`, wrapped middle content in `flex-1 overflow-y-auto -mx-6 px-6`, added `mt-4 shrink-0` to `DialogFooter` so Import/Cancel buttons stay visible.
  2. **Export controls dropdown:** Added `Download` icon and `DropdownMenu` imports. Added `csvEscape`, `exportJSON`, and `exportCSV` functions inside `ControlsView`. Added an Export `DropdownMenu` button (disabled when no controls loaded) in the header actions area, with JSON and CSV format options.

## Task ID: 7-b — Fix Logo Display Across App
- **Agent:** general-purpose
- **Date:** 2025-06-22
- **Description:** Fixed logo (transparent PNG) visibility issues across the application:
  1. **LoginPage.tsx — Hero panel (dark bg):** Wrapped transparent PNG in a `w-12 h-12 rounded-xl bg-white` container for high contrast. The white box makes the purple shield + white eagle clearly visible against the dark purple gradient.
  2. **LoginPage.tsx — Mobile view (white bg):** Wrapped icon in a `w-12 h-12 rounded-xl bg-[#812671]` container for contrast on white background.
  3. **AppShell.tsx — Sidebar (dark bg):** Used `bg-white/10 dark:bg-white/15` container for subtle contrast in the charcoal sidebar.
  4. Copied uploaded logo files to `public/`: `isecurify-icon.png` (transparent PNG, 663×662) and `isecurify-logo-small.jpg` (JPG, 801×366).
  5. Verified via VLM screenshot analysis: logo is now clearly visible as "white rounded square containing a purple shield logo with a white bird/eagle emblem."

## Task ID: 7-c — Final Logo Polish
- **Agent:** main
- **Date:** 2025-06-22
- **Description:** Further refined logo containers:
  - LoginPage hero panel: Changed from bare `img w-12 h-12` to `div w-12 h-12 rounded-xl bg-white + img w-10 h-10` for maximum contrast on dark purple gradient
  - AppShell sidebar: Changed container from `bg-[#812671]/15` to `bg-white/10 dark:bg-white/15` for clean visibility in both light and dark sidebar themes

---
Task ID: 8 — Generic Controls Import with Framework Selector & Duplicate Prevention
- **Agent:** main
- **Date:** 2025-06-22

Work Log:
- Analyzed user request: import controls should work for ANY framework, not just the currently-tabbed one
- Updated `ImportControlsDialog` props from `{ frameworkId, onDone }` to `{ frameworks, defaultFrameworkId, onDone }`
- Added a framework selector dropdown (`Select` component) inside the import dialog so users can pick any registered framework
- Framework list shows `code — name` for clarity (e.g., "SOC2 — SOC 2 Type II", "ISO27001 — ISO 27001")
- Updated `ControlsView` to pass `frameworks` array and `defaultFrameworkId` to `ImportControlsDialog`
- Improved dialog scrollability: `max-h-[90vh]`, `overflow-hidden` on DialogContent, `flex-1 overflow-y-auto min-h-0` on body, `shrink-0` on header/footer, textarea capped at `maxHeight: 40vh`
- Footer has `pt-3 border-t` for clear visual separation and always stays visible
- Updated `/api/controls/import` to always return `{ created, skipped }` counts (previously only returned skipped when ALL were duplicates)
- Import dialog toast now shows both counts: e.g., "15 imported, 3 duplicates skipped"
- Duplicate prevention: API filters out controls whose `ref` already exists in the target framework before `createMany`
- Cleaned up stale `public/public/` duplicate directory from tar extraction
- Verified logo files are valid PNG/JPG/SVG (already fixed in prior tasks)
- All changes pass ESLint

Stage Summary:
- Import dialog now supports any framework via a built-in dropdown selector
- Duplicate controls are automatically detected by `ref` within a framework and skipped
- Import result shows both created count and skipped duplicate count
- Dialog is fully scrollable with textarea capped at 40vh
- Footer (Import/Cancel buttons) always visible regardless of content length
- Files changed: `src/components/app/views/ControlsView.tsx`, `src/app/api/controls/import/route.ts`

---
Task ID: 9 — Fix Import Controls Button Not Enabling
- **Agent:** main
- **Date:** 2025-06-22

Work Log:
- Diagnosed root causes: (1) `recomputeCount` silently swallowed ALL parse errors with no feedback, (2) parser only accepted bare `[...]` arrays not wrapped objects `{"controls":[...]}`, (3) header normalization was too strict on whitespace/underscores
- Rewrote `ImportControlsDialog` with comprehensive fixes:
  - Added `parseError` state — now shows visible red error messages when parsing fails
  - Added `extractArray()` robust JSON parser that handles: bare arrays, wrapped objects (finds first array property), trailing commas, BOM characters, single-quoted strings
  - Changed `parseTextToControls` to also accept `{...}` wrapped objects (not just `[...]`)
  - Added underscore-based key aliases: `control_id`, `control_name` for camelCase/snake_case JSON
  - `normalizeHeader` now collapses `[_\s]+` to single space for flexible matching
  - `mapRow` handles non-string values (numbers, objects) by stringifying them
  - Textarea border turns red when parse error is active
  - Status indicator shows: green "N valid controls ready" / red "error message" / gray "Paste or upload"
  - Passes 8/8 unit tests: standard JSON, SOC2 keys, wrapped objects, id/name, underscore variants, trailing commas, numeric values, BOM
  - Passes 4/4 error tests: empty, bad JSON, wrong keys (shows detected keys), valid single-quote JSON

Stage Summary:
- Import button now highlights as soon as valid JSON/CSV with ref+title is detected
- Visible error feedback tells user exactly what's wrong (parse error, missing ref/title, detected keys)
- Supports wrapped JSON objects, trailing commas, BOM characters, underscore keys
- All changes pass ESLint
- File changed: `src/components/app/views/ControlsView.tsx`
---
Task ID: 1
Agent: Main Agent
Task: Fix evidence upload 404 error and JSON.parse crash

Work Log:
- Investigated error: frontend POSTs to `/api/evidence/upload` but only `/api/evidence` route existed (JSON-only, no multipart support)
- Created `/src/app/api/evidence/upload/route.ts` — full multipart FormData handler with: auth check, tenant access, 25MB limit, file type whitelist, sanitized filenames, per-tenant directory under `public/uploads/`, DB record creation, audit logging
- Fixed `JSON.parse(xhr.responseText)` crash in `EvidenceView.tsx` — wrapped in try-catch to gracefully handle non-JSON responses (e.g. 404 HTML pages) with user-friendly toast error
- Created `public/uploads/` directory
- Verified lint passes clean

Stage Summary:
- Root cause 1: `/api/evidence/upload` route did not exist → created with full file upload logic
- Root cause 2: XHR `JSON.parse` on non-JSON 404 response → added try-catch with fallback error message
- Files created: `src/app/api/evidence/upload/route.ts`
- Files modified: `src/components/app/views/EvidenceView.tsx` (lines 381-400)
---
Task ID: 2
Agent: Main Agent
Task: Fix evidence upload 404 - route file was not persisted from previous session

Work Log:
- Discovered `/api/evidence/upload/route.ts` was missing from disk (previous session write did not persist)
- Recreated the file: `src/app/api/evidence/upload/route.ts` with full multipart upload handling
- Verified both API routes exist: `/api/evidence` (JSON, for links) and `/api/evidence/upload` (multipart, for files)
- Confirmed `EvidenceView.tsx` has try-catch around JSON.parse (persisted from previous session)
- Confirmed Prisma Evidence model has all fields used by both routes
- Ran lint - clean, no errors
- Restarted dev server to ensure Turbopack picks up new route

Stage Summary:
- Root cause: The `/api/evidence/upload/route.ts` file was not persisted between sessions
- Both evidence flows now have backend routes:
  1. File upload → POST `/api/evidence/upload` (multipart FormData, with progress tracking)
  2. Link attach → POST `/api/evidence` (JSON body via `api()` helper)
- Files created: `src/app/api/evidence/upload/route.ts`
