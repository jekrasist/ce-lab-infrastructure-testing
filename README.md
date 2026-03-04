# Lab M5.05 - Infrastructure Testing & Validation

## Testing Layers

### Layer 1: Static Analysis
- `terraform fmt -check` — enforces consistent formatting
- `terraform validate` — checks syntax and provider compatibility
- `tflint` — catches provider-specific issues and best practice violations

### Layer 2: Convention Validation (`scripts/validate-conventions.sh`)
- Resource naming must be lowercase with underscores
- Required tags: `Name`, `Environment`, `ManagedBy`
- All variables must have descriptions
- No hardcoded AWS regions

### Layer 3: Plan Validation (`scripts/validate-plan.sh`)
- Verifies all expected resource types appear in the plan
- Warns on unexpected resource destruction
- Validates resource count

### CI Pipeline (`.github/workflows/ci.yml`)
- Runs all three layers automatically on every PR
- Blocks merge if any check fails
- Plan validation depends on static analysis passing first

### Pre-Commit Hooks
- Run `./scripts/install-hooks.sh` to install
- Automatically checks formatting, validation, and conventions before each commit

## Key Learnings
- Multiple test layers catch different categories of issues
- Static analysis is fast and catches syntax errors early
- Custom scripts enforce organization-specific standards
- Plan parsing validates the intended infrastructure changes
- Pre-commit hooks shift testing left to the developer's machine

