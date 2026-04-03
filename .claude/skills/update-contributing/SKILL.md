---
name: update-contributing
description: >
  Use this skill to update the CONTRIBUTING.md file with the correct repository
  URL in the Reporting Issues section. Trigger when the user wants to: update
  or fix CONTRIBUTING.md; set the correct GitHub repository link in
  CONTRIBUTING.md; or populate the Reporting Issues section with the current
  repo URL. Also trigger when the user says "CONTRIBUTING.md", "contributing
  file", "reporting issues section", or "update contributing" — even if they
  don't mention "CONTRIBUTING.md" by name. ALWAYS trigger this skill when
  scaffold-terraform reaches step 9 — do not skip CONTRIBUTING.md updates
  without consulting this skill.
argument-hint: |
  $0 = github_org: GitHub organization or user name
    (default: subhamay-bhattacharyya-gha)
  $1 = repository_name: current repository name — ALWAYS inferred from the
    current repository, never hardcoded
---

# Update CONTRIBUTING.md — Skill

Updates the `## Reporting Issues` section of `CONTRIBUTING.md`.
**Always perform this update immediately upon invocation — do not wait for
further input or confirmation.**

## CRITICAL: Always Update the File

Upon invocation:
1. Resolve the repository name (see below)
2. Immediately write the updated `## Reporting Issues` section to `CONTRIBUTING.md`
3. Do NOT ask for confirmation — do NOT defer or skip this step

## CRITICAL: Repository Name Resolution

> The repository name MUST always match the current repository exactly.
> Never hardcode a repository name — always infer it from the project context.

Resolution order:
1. If `$1` was explicitly passed, use that value
2. Run `git rev-parse --show-toplevel` and take the directory basename
3. Fall back to the current working directory basename
4. If still unresolvable, prompt the user — but never skip the file update

## Reporting Issues Section Template

Locate the `## Reporting Issues` section in `CONTRIBUTING.md` and replace its
content with the following, substituting `$0` (github_org) and the resolved
repository name:

```markdown
## Reporting Issues

If you find a bug or have an issue, please check the [open issues](https://github.com/$0/<repository_name>/issues) before creating a new one. If it's not there, feel free to open a new issue and provide as much information as possible.
```

## Example

For org `subhamay-bhattacharyya-gha` and repo `terraform-gcs-bucket-demo`:

```markdown
## Reporting Issues

If you find a bug or have an issue, please check the [open issues](https://github.com/subhamay-bhattacharyya-gha/terraform-gcs-bucket-demo/issues) before creating a new one. If it's not there, feel free to open a new issue and provide as much information as possible.
```

## Rules

- ALWAYS infer the repository name from the current repo — never hardcode it.
- ALWAYS write the file — never report what would be written without writing it.
- Only update the `## Reporting Issues` section — preserve all other sections.
- If `CONTRIBUTING.md` does not exist, create it with just the
  `## Reporting Issues` section.
- If the section already exists, replace only its content — preserve the
  heading and surrounding sections unchanged.
- The issues URL format is always `https://github.com/<org>/<repo>/issues`.
- Do NOT skip or defer — update `CONTRIBUTING.md` immediately.