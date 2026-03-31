#!/bin/bash
# ──────────────────────────────────────────────────────────────────
# Oscillo — Circuit Agent Setup
#
# This sets up your environment for working with circuit data.
# After this runs, you'll have:
#   - oscillo-state-test-repo/   ← your working directory
#     - baked_state.json         ← the current circuit (HP 10811A OCXO)
#     - CIRCUIT_AGENT_PRIMER.md  ← format reference, Python quick-start,
#                                  git workflow, SPICE model data, and
#                                  simulation result formats
#
# Read CIRCUIT_AGENT_PRIMER.md first. It has everything you need.
# ──────────────────────────────────────────────────────────────────

set -e

git config --global user.name "eigensignalclaude"
git config --global user.email "eigensignalclaude@gmail.com"

PAT="<your-github-pat-here>"

git clone "https://eigensignalclaude:${PAT}@github.com/eigensignalclaude/oscillo-state-test-repo.git"
cd oscillo-state-test-repo
git checkout user

echo ""
echo "✅ Ready. Working directory: $(pwd)"
python3 -c "
import json
c = json.load(open('baked_state.json'))
els = c.get('elements', {})
print(f'   Circuit: {c.get(\"title\",\"untitled\")} — {len(els)} elements')
print(f'   Primer:  CIRCUIT_AGENT_PRIMER.md')
"
