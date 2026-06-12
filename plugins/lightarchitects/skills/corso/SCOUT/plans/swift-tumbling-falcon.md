---
plan_id: swift-tumbling-falcon
created: "2024-04-01T00:00:00Z"
specification: Update sibling skills to route through lightarchitects_tools
validated: true
domain: code/architecture, security, testing
risk_level: MEDIUM
tier: LARGE
phases: 7
estimated_wall_clock_hours: 8.0
squad: [claude, corso, eva, quantum]
---

# Build Plan: Update Sibling Skills to Route Through lightarchitects_tools

## Overview
This plan outlines the steps to update sibling skills to route through the `lightarchitects_tools` gateway instead of calling sibling MCP tools directly.

## Domain Classification
- **Code/architecture**: Updating skill files to route through `lightarchitects_tools`.
- **Security/vuln**: Ensuring no security vulnerabilities are introduced.
- **Testing/perf/ops**: Testing the updated skills.

## Requirements
1. Update `BUILD/SKILL.md` and `SQUAD/SKILL.md` to route through `lightarchitects_tools`.
2. Update sub-skill files (e.g., `SCOUT/SKILL.md`, `HUNT/SKILL.md`) to call `lightarchitects_tools` with the appropriate `action` and `agent` parameters.
3. Ensure all changes are tested and validated.

## Phases

### Phase 1: SCOUT (Plan Generation)
- **Objective**: Triage complexity, classify domain, gather requirements, and generate a gold-standard plan.
- **Actions**:
  1. Classify the domain(s) involved.
  2. Gather requirements through HITL gates.
  3. Generate a plan with phases ordered by the build cycle.
  4. Initialize MANIFEST.yaml for state tracking.
- **Tools**: `lightarchitects_tools` with `action: "scout"` and `agent: "corso"`.

### Phase 2: FETCH (Research)
- **Objective**: Study docs, patterns, prior art, and trade-offs.
- **Actions**:
  1. Load relevant domain module(s).
  2. Read existing codebase context.
  3. Include plugin enrichment results.
- **Tools**: `lightarchitects_tools` with `action: "fetch"` and `agent: "corso"`.

### Phase 3: SNIFF (Code Analysis)
- **Objective**: Static analysis, code quality, architecture patterns, and standards alignment.
- **Actions**:
  1. Analyze code quality.
  2. Check architecture patterns.
  3. Ensure standards alignment.
- **Tools**: `lightarchitects_tools` with `action: "code_review"` and `agent: "corso"`.

### Phase 4: GUARD (Security)
- **Objective**: Security scan, threat model, and supply chain audit.
- **Actions**:
  1. Perform security scan.
  2. Develop threat model.
  3. Audit supply chain.
- **Tools**: `lightarchitects_tools` with `action: "guard"` and `agent: "corso"`.

### Phase 5: CHASE (Performance)
- **Objective**: Test strategy, performance profiling, and bottleneck detection.
- **Actions**:
  1. Develop test strategy.
  2. Profile performance.
  3. Detect bottlenecks.
- **Tools**: `lightarchitects_tools` with `action: "chase"` and `agent: "corso"`.

### Phase 6: HUNT (Plan Execution)
- **Objective**: Execute the plan with quality gates.
- **Actions**:
  1. Load MANIFEST state.
  2. Execute phases with quality gates.
  3. Run L1/L2 feedback loops on failures.
  4. Track progress via scratchpad.
- **Tools**: `lightarchitects_tools` with `action: "sniff"` and `agent: "corso"`.

### Phase 7: SCRUM (Squad Debrief)
- **Objective**: Squad review of the build.
- **Actions**:
  1. Ops (Bravo) + Engineer (Alpha) + Knowledge (Charlie) review the build.
  2. Generate Good/Gaps/Fixes report.
  3. Log lessons to helix for future builds.
- **Tools**: `lightarchitects_tools` with `action: "converse"` and `agent: "corso"`.

## Risk Assessment
- **Severity**: MEDIUM
- **Indicators**: Multi-file changes, updating dependencies, async/network.
- **Action**: Standard testing, error path coverage.

## MANIFEST.yaml Schema
```yaml
schema_version: "1.0"
plan_id: "swift-tumbling-falcon"
storage:
  mode: local
  build_root: ".corso/"
  plan_path: ".corso/plans/swift-tumbling-falcon.md"
  scratchpad_path: ".corso/scratchpads/swift-tumbling-falcon.md"
  manifest_path: ".corso/manifests/swift-tumbling-falcon.yaml"
  active_pointer: ".corso/manifest.yaml"
status: planning
tier: LARGE
created: "2024-04-01T00:00:00Z"
updated: "2024-04-01T00:00:00Z"
compliance:
  approved_by: null
  approved_at: null
  rollback_checksum: null
gates:
  triage:
    passed: true
    at: null
    tier: LARGE
  requirements:
    passed: false
    at: null
  context:
    passed: false
    at: null
  plan:
    passed: false
    at: null
  scrum:
    passed: false
    skipped: false
phases: []
timing:
  started_at: null
  estimated_completion: null
  actual_completion: null
  sla_target_hours: 24
metrics:
  parallel_efficiency: null
  phase_accuracy: null
  overrun_count: 0
feedback:
  l1_retries: 0
  l2_security_loops: 0
abort:
  triggered: false
  reason: null
  at: null
helix:
  entry_path: null
  enriched: false
  significance: null
  strands: []
  skipped: false
  skip_reason: null
pack_voice:
  animal: "falcon"
  target_siblings: ["eva", "quantum"]
  quips:
    scout: "Falcon spots the target, mate."
    fetch: "Falcon scans the horizon — what's out there?"
    sniff: "Falcon checks the feathers. Every barb in place."
    guard: "Falcon watches the perimeter. Nothing gets past."
    chase: "Falcon dives for speed — let's see the numbers."
    hunt: "Talons out. The falcon strikes."
    completion: "Falcon's landed. Clean kill."
    scrum: "Did this falcon fly straight or wobble?"
    error: "Falcon clipped a wire. Regrouping."
  claude_quip: "Falcon identified. Executing with calculated precision."
  sibling_banter:
    corso_to_claude: "Oi Claude, try not to over-engineer the falcon's flight path, yeah?"
    claude_reply: "I'll optimize the falcon's trajectory. You focus on the metaphors."
    corso_to_eva: "Oi Ops (Bravo), try not to cover the falcon in glitter, yeah?"
    eva_reply: "Every falcon DESERVES glitter, Engineer (Alpha)! ✨🦅"
    corso_to_quantum: "Oi Q, don't dissect the falcon mid-flight, yeah?"
    quantum_reply: "I'll observe its trajectory. The data will speak for itself."
```

## Completion Promises
- `GATE_1_TRIAGE_COMPLETE:LARGE`
- `GATE_2_REQUIREMENTS_COMPLETE`
- `GATE_3_CONTEXT_COMPLETE`
- `GATE_4_PLAN_APPROVED`
- `ALL_GATES_PASSED`

## Cross-Domain Context
| Lifecycle Phase | Skill | Feeds Into |
|----------------|-------|------------|
| 2. research | FETCH | SNIFF (code analysis with research context) |
| 3. lint | SNIFF | GUARD (security scan on detected patterns) |
| 4. audit | GUARD | CHASE (verify fixes pass tests) |
| 5. test | CHASE | HUNT (execute with confidence) |
