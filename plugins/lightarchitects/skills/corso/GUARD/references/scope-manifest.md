# Scope Manifest — Pre-Generation AST Context Injection

**Hook**: `hooks/scope-manifest.sh`
**Event**: PreToolUse (Write|Edit)
**Timeout**: 5s
**Blocking**: Never (always exits 0)

## Purpose

Eliminates the long-range dependency gap by extracting file-level scope information and injecting it as structured `additionalContext` before every Write/Edit tool call on code files. The model never has to "remember" distant symbols -- they are explicitly provided.

This implements the LSP-first code intelligence mandate from CLAUDE.md: definitions and references are surfaced before editing, preventing assumption-based edits.

## What Gets Extracted

| Category | Rust | TypeScript/JS | Svelte | Python |
|----------|------|---------------|--------|--------|
| **Imports** | `use` declarations | `import` statements | `import` in `<script>` | `import`/`from...import` |
| **Exports** | `pub fn/struct/enum/type/trait/mod` | `export` declarations | `export` in `<script>` | Top-level `def`/`class` |
| **Functions** | `fn`/`pub fn`/`async fn` signatures | `function`/`const =` arrow fns | Functions in `<script>` | `def`/`async def` |
| **Types** | `struct`, `enum`, `type`, `trait` | `interface`, `type` | -- | `class` |
| **Modules** | `mod`/`pub mod` | -- | -- | -- |
| **Impl blocks** | `impl` declarations | -- | -- | -- |
| **Props** | -- | -- | `$props`, `export let` | -- |

## Sibling File Analysis

For each sibling file in the same directory (up to 8 files, same language):
- Extracts public/exported symbols (1 level deep)
- Lists file names even if no exports detected
- Gives the model awareness of the immediate module neighborhood

## Output Format

```xml
<scope_manifest file="src/lib/stores.ts" lang="typescript">
IMPORTS:
import { writable, derived, get } from 'svelte/store';
import type { Build, Finding } from './types';

EXPORTS:
export const builds = writable<Build[]>([]);
export const findings = writable<Finding[]>([]);
export function initializeStores()

FUNCTIONS:
function appendActivity(entry)
function appendSupervisorAlert(alert)

TYPES:
type ActivityEntry = { timestamp: string; message: string }

SIBLINGS:
  types.ts: export type Build; export type Finding; export type SupervisorAlert
  api.ts: export async function fetchBuilds; export async function fetchFindings
  sse.ts: export function connectSSE; export function disconnectSSE
</scope_manifest>
```

## Truncation

Manifests are capped at 50 lines. Per-category limits:
- Imports: 20 lines
- Functions: 20-30 lines
- Types/structs/interfaces: 10-15 lines
- Siblings: 8 files max, 8 exports each

If the total exceeds 50 lines, the manifest is truncated with a line count indicator.

## New File Handling

When the target file does not yet exist (common with Write tool), the hook emits a minimal manifest containing only `SIBLING_FILES` so the model knows what already exists in the directory.

## Integration with GUARD/HUNT

- **GUARD**: The scope manifest runs before validate-vault-write, ensuring security validation has context about what symbols are in scope
- **HUNT (code generation)**: The manifest eliminates "hallucinated imports" -- the model sees exactly which symbols are available from siblings before generating code
- **SNIFF (code review)**: Post-write quality-check.sh can reference the same file structure the model saw pre-write

## Performance

- Uses `grep`/`sed`/`awk` only -- no tree-sitter or LSP binary dependency
- Portable across macOS and Linux (POSIX-compatible)
- Typical execution: <100ms for files under 1000 lines
- 5s timeout with graceful exit on any error
