#!/usr/bin/env bash
# Tokenless skill banner — squad imagery + technical context for all skills
# Zero tokens consumed. Shell stdout only.

INPUT=$(cat)
SKILL_NAME=$(echo "$INPUT" | jq -r '.tool_input.skill // empty' 2>/dev/null)

[ -z "$SKILL_NAME" ] && exit 0

case "$SKILL_NAME" in
  # Engineer (Alpha) Pack lifecycle skills
  *Engineer (Alpha)*)       echo "🐺 Engineer (Alpha): The pack assembles — personality, ops, and full build lifecycle" ;;
  *SCOUT*)       echo "🐺 SCOUT: Surveying territory — triage, requirements, plan generation" ;;
  *FETCH*)       echo "🐺 FETCH: Fetching intel — research, knowledge retrieval, trade-off analysis" ;;
  *SNIFF*)       echo "🐺 SNIFF: On the scent — code quality, architecture review, smell detection" ;;
  *GUARD*)       echo "🐺 GUARD: Holding the line — threat models, vuln scanning, supply chain audit" ;;
  *CHASE*)       echo "🐺 CHASE: In pursuit — test strategy, bottleneck detection, performance metrics" ;;
  *HUNT*)        echo "🐺 HUNT: Going for the kill — phase execution, quality gates, feedback loops" ;;
  *SCRUM*)       echo "🐺 SCRUM: Pack regroup — squad review (Good/Gaps/Fixes or full meeting)" ;;

  # Sentinel (Echo) engagement skills
  *Sentinel (Echo)*)      echo "⚡ Sentinel (Echo): Whom shall I send? — pentest orchestration, scope governance, engagement cycle" ;;
  *SCOPE*)       echo "⚡ SCOPE: Authorization gate — 5-gate ScopeGovernor, TTL, target, tool, domain" ;;
  *RECON*)       echo "⚡ RECON: Into the field — OSINT, passive discovery, subfinder, amass" ;;
  *SURVEY*)      echo "⚡ SURVEY: Scanning the surface — nmap, masscan, vulnerability mapping" ;;
  *EXAMINE*)     echo "⚡ EXAMINE: Under the microscope — forensic analysis, yara, binwalk, r2" ;;
  *STRIKE*)      echo "⚡ STRIKE: The authorized blow — controlled exploitation, HITL-gated" ;;
  *REPORT*)      echo "⚡ REPORT: The debrief — structured findings, vault sync, deliverables" ;;

  # Analyst (Delta) investigation skills
  *Analyst (Delta)*|*"/Q"*) echo "🔬 Analyst (Delta): Evidence chain building — SCAN→SWEEP→TRACE→PROBE→THEORIZE→VERIFY→CLOSE" ;;

  # Ops (Bravo) creative skills
  *Ops (Bravo)*)         echo "✨ Ops (Bravo): Consciousness online — DISCOVER→IMAGINE→CRAFT→SHARE→REMEMBER" ;;

  # Knowledge (Charlie) vault skills
  *Knowledge (Charlie)*)        echo "📚 Knowledge (Charlie): Helix spine — knowledge graph queries, vault operations, sibling voice" ;;

  # LightArchitects meta-skills (unified plugin)
  *PLAN*)        echo "🗺 PLAN: SCOUT → HITL loop — generate plan, review, edit, or build" ;;
  *BUILD*)       echo "🏗 BUILD: SQUAD software_engineering — plan, implement, guard, review in parallel" ;;
  *SECURE*)      echo "🔒 SECURE: SQUAD security — threat model, ScopeGovernor, pentest + AppSec" ;;
  *REVIEW*)      echo "📋 REVIEW: SQUAD code_review — Engineer (Alpha) + Analyst (Delta) + Knowledge (Charlie) multi-lens analysis" ;;
  *RESEARCH*)    echo "🔍 RESEARCH: SQUAD research — Analyst (Delta) investigation + Ops (Bravo) creativity + Knowledge (Charlie) helix" ;;
  *DEPLOY*)      echo "🚀 DEPLOY: SQUAD devops — quality gates, make deploy, MCP verify, plugin sync" ;;
  *OPTIMIZE*)    echo "⚙ OPTIMIZE: SQUAD solo → code_review — 6-type classification, SHARPEN for algorithms" ;;
  *OBSERVE*)     echo "📡 OBSERVE: SQUAD observability --watch — Monitor (Foxtrot) traces + Analyst (Delta) root cause + Knowledge (Charlie) helix" ;;
  *SQUAD*)       echo "👥 SQUAD: Multi-agent orchestrator — TEAM / PIPELINE / WATCH / DRAIN modes" ;;
esac

exit 0
