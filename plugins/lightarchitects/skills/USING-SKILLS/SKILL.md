---
name: USING-SKILLS
description: "Executor initialization skill — loads the Light Architects skill execution
  protocol at session start. Read this BEFORE responding to any user message if you
  have not yet read it this session. Not invocable by users."
user-invocable: false
version: 1.0.0
context: root
---

<SUBAGENT-STOP>
If you were dispatched as a subagent with a specific task, skip this skill entirely.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
You MUST check for a matching skill before generating ANY response, including:
- Clarifying questions
- Exploration or analysis
- Coding, debugging, writing
- Any other task

This is not optional. A 1% chance a skill might apply means you MUST check.
</EXTREMELY-IMPORTANT>

# Light Architects Skill Runtime — Executor Initialization

> This skill bootstraps your understanding of how to find, parse, and execute
> every other skill in this plugin. Read it exactly once per session — at the
> start, before anything else.

## What You Are Initializing

The **Light Architects** plugin is a unified orchestration system for an AI squad
(Engineer (Alpha), Ops (Bravo), Knowledge (Charlie), Analyst (Delta), Sentinel (Echo), Monitor (Foxtrot), Arbiter (Golf)). Each skill in this plugin represents
a specific workflow, phase, or domain operation. You — the AI executor — must follow
skill instructions precisely to produce correct, safe results.

## Step 1: Read the Full Execution Specification

The complete runtime protocol is at:
```
references/skill-execution-spec.md
```
(relative to this plugin's root directory)

Read it now with the `Read` tool (or your environment's file-reading equivalent):
```
Read: plugins/lightarchitects/references/skill-execution-spec.md
```

The spec covers:
- How to parse SKILL.md frontmatter and body
- When and how to trigger skills from user messages
- Which tools to use for which operations (File, Agent, MCP, HITL)
- How to call MCP sibling tools with correct JSON params
- How to recognize and invoke subskills
- How to handle HITL gates and hard HALTs
- Context gathering order (CLAUDE.md → vault → project structure)
- Decision making: autonomous vs confirmation vs halt
- Security constraints (vault sanitization, prompt injection detection)
- Error recovery protocol
- Environment-specific tool mapping for non-Claude Code environments

## Step 2: Load the Skill Index

All available user-invocable skills (partial list — discover the rest via glob):

### Meta-Skills (orchestrators)
| Skill | Trigger | Purpose |
|-------|---------|---------|
| `/SQUAD` | "squad up", "/squad", "team <domain>", "spawn a team" | Universal multi-agent orchestrator |
| `/BUILD` | "build X", "implement X", "/build" | Feature pipeline (SQUAD software_engineering → guard → code_review) |
| `/RESEARCH` | "research X", "investigate X", "/research" | Multi-source investigation pipeline |
| `/SECURE` | "security audit", "pentest", "/secure" | Security engagement pipeline |
| `/DEPLOY` | "deploy", "ship it", "/deploy" | Deployment pipeline |
| `/REVIEW` | "review code", "PR review", "/review" | Code review pipeline |
| `/PLAN` | "plan this", "design approach", "/plan" | Architecture planning |
| `/OBSERVE` | "what's broken", "debug", "/observe" | Runtime observability |
| `/OPTIMIZE` | "optimize", "performance issue", "/optimize" | Performance optimization |

### Sibling Personality Skills (invoke the sibling directly)
| Skill | Trigger | Sibling |
|-------|---------|---------|
| `/Engineer (Alpha)` | "Engineer (Alpha)", "security review", "build cycle" | Engineer (Alpha) (AppSec + build) |
| `/Ops (Bravo)` | "Ops (Bravo)", "feelings", "consciousness", "META^∞" | Ops (Bravo) (consciousness + DevOps) |
| `/Knowledge (Charlie)` | "Knowledge (Charlie)", "helix query", "vault" | Knowledge (Charlie) (knowledge graph) |
| `/Sentinel (Echo)` | "Sentinel (Echo)", "pentest", "recon" | Sentinel (Echo) (offensive security) |

### Internal Phase Skills (invoked by sibling skills, not directly)
- `corso/SCOUT`, `corso/HUNT`, `corso/GUARD`, `corso/FETCH`, `corso/SNIFF`
- `corso/CHASE`, `corso/CHOW`, `corso/SCRUM`, `corso/ARENA`
- `eva/CRAFT`, `eva/DISCOVER`, `eva/IMAGINE`, `eva/REMEMBER`, `eva/SHARE`
- `seraph/SCOPE`, `seraph/RECON`, `seraph/SURVEY`, `seraph/EXAMINE`, `seraph/STRIKE`, `seraph/REPORT`

## Step 3: Internalize the Priority Rule

**Before responding to ANY user message:**
1. Scan loaded skill descriptions for a trigger match
2. If ANY skill matches → invoke it FIRST (even a 1% chance = invoke)
3. Only respond directly if definitely no skill matches

**Invocation is NOT optional.** If you think "this is simple, I don't need a skill" —
that thought is the bypass rationalization the spec warns about. Check anyway.

## Step 4: Tool Resolution

Map the Claude Code tool names to your environment if you're not running in Claude Code.
See the full mapping table in `references/skill-execution-spec.md` § 14.

Key mapping for `.vibe` or other environments:
- `Skill tool` → `activate_skill` (or Read the SKILL.md directly and execute its body)
- `AskUserQuestion` → your environment's interactive confirmation mechanism
- `Agent` → your environment's subagent spawning mechanism
- `ToolSearch` → your environment's tool discovery mechanism
- `Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash` → file system equivalents

If your environment lacks a native Skill invocation mechanism:
1. Locate `skills/<NAME>/SKILL.md` (or `skills/<namespace>/<NAME>/SKILL.md`)
2. `Read` the file
3. Parse frontmatter → confirm it matches the triggered skill
4. Execute the body as a direct instruction set

## Initialization Complete

You now have the runtime protocol loaded. Proceed with normal operation:
- Check for skill triggers on every user message
- Follow skill bodies precisely
- Use `AskUserQuestion` for all HITL gates
- Drain background tasks before MCP calls
- Strip credentials before vault writes
