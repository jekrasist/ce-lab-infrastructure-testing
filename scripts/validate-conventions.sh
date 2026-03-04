#!/usr/bin/env bash
set -euo pipefail

ERRORS=0

echo "=== Convention Validation (macOS Compatible) ==="
echo ""

# --- Check 1: Naming convention ---
echo "Checking naming conventions..."
# Using sed to extract the second quoted string since BSD grep doesn't support -P
RESOURCES=$(grep -n 'resource "' *.tf | grep -v '#' || true)

while IFS= read -r line; do
  [ -z "$line" ] && continue
  file=$(echo "$line" | cut -d: -f1)
  lineno=$(echo "$line" | cut -d: -f2)
  # Extract the resource name (the second set of quotes)
  resource_name=$(echo "$line" | sed -E 's/.*resource "[^"]+" "([^"]+)".*/\1/')

  if [[ ! "$resource_name" =~ ^[a-z][a-z0-9_]+$ ]]; then
    echo "  FAIL: $file:$lineno — resource name '$resource_name' must be lowercase with underscores"
    ERRORS=$((ERRORS + 1))
  fi
done <<< "$RESOURCES"

if [ "$ERRORS" -eq 0 ]; then
  echo "  PASS: All resource names follow conventions"
fi

# --- Check 2: Required tags ---
echo ""
echo "Checking required tags..."
REQUIRED_TAGS=("Name" "Environment" "ManagedBy")

for tag in "${REQUIRED_TAGS[@]}"; do
  TAGGED_RESOURCES=$(grep -c "resource \"aws_" *.tf || true | awk '{s+=$1} END {print s}')
  TAG_PRESENT=$(grep -c "\"$tag\"" *.tf || true | awk '{s+=$1} END {print s}')

  if [ "${TAG_PRESENT:-0}" -eq 0 ] && [ "${TAGGED_RESOURCES:-0}" -gt 0 ]; then
    echo "  FAIL: Required tag '$tag' not found in any resource"
    ERRORS=$((ERRORS + 1))
  else
    echo "  PASS: Tag '$tag' found"
  fi
done

# --- Check 3: Variable descriptions ---
echo ""
echo "Checking variable descriptions..."
if [ -f "variables.tf" ]; then
  VAR_BLOCKS=$(grep -c '^variable "' variables.tf || true)
  VAR_DESCS=$(grep -c 'description' variables.tf || true)

  if [ "$VAR_DESCS" -lt "$VAR_BLOCKS" ]; then
    echo "  FAIL: $((VAR_BLOCKS - VAR_DESCS)) variable(s) missing descriptions"
    ERRORS=$((ERRORS + 1))
  else
    echo "  PASS: All $VAR_BLOCKS variables have descriptions"
  fi
else
  echo "  SKIP: variables.tf not found"
fi

# --- Check 4: No hardcoded regions ---
echo ""
echo "Checking for hardcoded AWS regions..."
# Removed -P; using extended regex -E which works on macOS/BSD grep
HARDCODED=$(grep -nE 'region[[:space:]]*=[[:space:]]*"[a-z]{2}-[a-z]+-[0-9]"' *.tf | grep -v 'var\.' | grep -v '#' || true)

if [ -n "$HARDCODED" ]; then
  echo "  FAIL: Hardcoded region found:"
  echo "  $HARDCODED"
  ERRORS=$((ERRORS + 1))
else
  echo "  PASS: No hardcoded regions"
fi

# --- Summary ---
echo ""
echo "=== Results ==="
if [ "$ERRORS" -gt 0 ]; then
  echo "FAILED: $ERRORS convention violation(s) found"
  exit 1
else
  echo "PASSED: All convention checks passed"
  exit 0
fi
