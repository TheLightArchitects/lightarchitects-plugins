# Skill Usage Guide

## Overview
This guide documents how to use skills from a Claude Code perspective and translates that to this environment.

## Skills as Guides
Skills provide a structured workflow for executing tasks. They outline the steps, tools, and parameters required for each phase.

## Invoking Skills
Skills are invoked by calling `/<SKILL NAME>`. The skill then uses built-in tools to gather context and take notes in the manifest.

### Example:
- Invoking `/SNIFF` uses the `SNIFF/SKILL.md` file as a guide.
- The skill file outlines the steps, tools, and parameters required for the phase.

## Built-in Tools
Tools like `lightarchitects_tools` are used to perform specific actions (e.g., `code_review`, `guard`, `fetch`). These tools route requests to the appropriate sibling based on the `action` and `agent` parameters.

### Example:
```json
{
  "action": "code_review",
  "agent": "corso",
  "params": {
    "spec": "..."
  }
}
```

## Manifest
The manifest (`MANIFEST.yaml`) tracks the state, progress, and findings of each phase. It is updated at each gate to reflect the current state.

### Example Manifest:
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

## Translating to This Environment
1. **Invoking Skills**:
   - When a skill is invoked (e.g., `/SNIFF`), the corresponding skill file (e.g., `SNIFF/SKILL.md`) is used as a guide.
   - The skill file outlines the steps, tools, and parameters required for the phase.

2. **Using Built-in Tools**:
   - Built-in tools like `lightarchitects_tools` are used to perform specific actions.
   - The `action` and `agent` parameters determine which sibling tool is called.

3. **Updating the Manifest**:
   - The manifest is updated at each gate to reflect the current state and findings.

## Examples

### Invoking `/SNIFF`:
1. Use the `SNIFF/SKILL.md` file as a guide.
2. Use `lightarchitects_tools` with `action: "code_review"` and `agent: "corso"`.
3. Pass the target files for analysis.
4. Update the manifest with the findings.

### Invoking `/GUARD`:
1. Use the `GUARD/SKILL.md` file as a guide.
2. Use `lightarchitects_tools` with `action: "guard"` and `agent: "corso"`.
3. Perform security scanning and threat modeling.
4. Update the manifest with the findings.

## Conclusion
This guide provides a clear understanding of how to use skills from a Claude Code perspective and translates that to this environment. It serves as a reference for future use.
