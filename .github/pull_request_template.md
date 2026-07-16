## Scope

<!--
Describe what this PR changes and why.
List the affected paths.
-->

**Affected paths:**
- `path/to/file` — reason
- `path/to/other` — reason

## Verification

- [ ] I have tested the changes according to the test evidence policy (CONTRIBUTING.md)
- [ ] Shell scripts pass `shellcheck` (if applicable)
- [ ] Markdown links resolve correctly
- [ ] The change matches the specification and design documents

## Rollback

<!--
Describe how to safely revert this change.
For most control-plane changes: revert the commit(s), verify no ignored paths remain.
-->

## Review-Budget Forecast

| Metric | Value |
|--------|-------|
| Additions | `XX` |
| Deletions | `XX` |
| **Total** | **`XX`** |
| Budget | 400 lines |
| ⚠️ Exceeds budget? | Yes / No |
| Action | Single PR / Chained slices / Size exception |

<!--
If total exceeds 400 lines, you MUST split into chained PRs or record
an explicit size-exception approval from a maintainer.
-->

## Checklist

- [ ] Conventional Commit message (`type(scope): description`)
- [ ] No `Co-Authored-By` or AI-attribution trailers
- [ ] No secrets, credentials, or `.env` files committed
- [ ] Independent app-repo rule respected (no Frappe app inside this workspace)
- [ ] No manual DocType directory creation
