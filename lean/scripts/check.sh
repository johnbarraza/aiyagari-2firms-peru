#!/usr/bin/env bash
set -euo pipefail

lake build
lake env lean BN26InformalityWealthPeru/ProofInterface.lean
lake env lean BN26InformalityWealthPeru/ExtensionResults.lean

echo "Standalone Lean checks passed."
