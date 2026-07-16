# Contributing to Creativa Digital

## Repository Scope

This is a **control-plane repository**. It versions only:

- Consultancy standards and conventions
- Reusable templates and documented scripts
- Architecture Decision Records (ADRs)
- Runbooks and quality policy

It does **not** contain client applications, Frappe apps, Bench runtimes, production artifacts, or secrets.

## App-Repository Rule

Each custom Frappe app **must** reside in its own independent Git repository. Do not create a Frappe app inside this workspace or add one as a submodule. App-specific development happens in the app's own repository.

## Commit Convention

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short description>

<optional body>
<optional footer>
```

Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `ci`, `style`.

Examples:

- `docs(adr): add control-plane topology ADR`
- `chore(gitignore): add benches/ and secrets exclusion`
- `docs(runbook): document local Bench lifecycle`

**Do not** add `Co-Authored-By` or AI-attribution trailers to commits.

## Pull Request Policy

### Review Budget

Every PR must forecast its **changed lines** (additions + deletions). The review budget is **400 changed lines**. Work forecast to exceed this budget **must** be split into chained, reviewable slices unless an explicit size exception is accepted.

### Test Evidence

Every functional change **must** include test evidence. For this control-plane workspace, "test evidence" means:

- **Scripts**: shellcheck-clean output, manual or automated run showing the guard/error path
- **Documentation**: proof of links resolving, linted markdown
- **Policy/Governance**: reviewer verification that the change matches the spec

### PR Template

All PRs must use the [pull request template](.github/pull_request_template.md), which requires:

- [ ] Scope and affected paths
- [ ] Verification steps performed
- [ ] Rollback instructions
- [ ] Review-budget forecast check

### Rollback

Every PR must include rollback instructions. For a control-plane change, rollback typically means reverting the commit(s) and verifying that no ignored directory or asset was left behind.

## Branch Strategy

We use an environment branch chain:

```
develop  →  qa  →  uat  →  main
```

- `develop` is the default working branch.
- All feature/fix branches branch from and merge into `develop`.
- Merges progress through the chain: `develop → qa → uat → main`.

## Code Style

- Keep functions small and single-purpose.
- Keep files below 300 lines when practical; split by responsibility.
- Shell scripts: use `set -euo pipefail`, validate arguments, refuse paths outside expected directories.
- Markdown: one sentence per line in source for cleaner diffs.

## DocType Folder Rule

Never create DocType directories manually. Frappe migrations create them automatically. Any change that manually creates a DocType directory structure will be rejected.

## Questions?

Open an issue in this repository or reach out in the team channel.
