---
name: project-ops
description: Unified long-term project operations for OpenClaw. Use when user asks to list active projects, open a numbered project menu, choose/continue a project by id or index, update status/progress, assign agents quickly, kickoff a new push cycle with a standard log template, generate daily push suggestions from repo git status (blocker-priority first), archive half-finished work in a consistent format, or enforce standardized project documentation under .projects/{id}.
---

# Project Ops v1.4

Single source of truth: `workspace/.projects/`

## Preferred Command Interface

Use wrapper: `skills/project-ops/scripts/project.ps1`

```powershell
# /project -> menu
powershell -ExecutionPolicy Bypass -File "skills/project-ops/scripts/project.ps1"

# /project N -> choose by index
powershell -ExecutionPolicy Bypass -File "skills/project-ops/scripts/project.ps1" 2

# /project suggest (today push suggestions by blocker priority)
powershell -ExecutionPolicy Bypass -File "skills/project-ops/scripts/project.ps1" suggest

# alias
powershell -ExecutionPolicy Bypass -File "skills/project-ops/scripts/project.ps1" today

# /project push <project-id>
powershell -ExecutionPolicy Bypass -File "skills/project-ops/scripts/project.ps1" push openclaw-dashboard

# /project log <project-id> <note>
powershell -ExecutionPolicy Bypass -File "skills/project-ops/scripts/project.ps1" log openclaw-dashboard "完成接口核对，记录阶段快照"

# /project archive <project-id> [note]
powershell -ExecutionPolicy Bypass -File "skills/project-ops/scripts/project.ps1" archive openclaw-dashboard "暂缓到下个迭代"
```

## Suggestion Engine (v1.4)

`/project suggest` reads each project's `repoPath` and runs:
- `git status --porcelain -b`

Ranking factors:
1. Project status base (`blocked > active > on_hold`)
2. Merge conflicts (`unmerged`) heavy boost
3. Remote behind (`behind`) medium boost
4. Dirty tree (`staged/modified`) medium boost
5. Missing `nextAction` management boost

Output includes rank, reason signals, git summary, immediate action.

## Documentation Standard (XiaoZ-derived)

Use this standard for every managed project:
- `references/project-doc-standards.md`

Canonical docs under `.projects/<id>/`:
- `project.json` (machine-readable truth)
- `MASTER_PLAN.md` (long-range strategy + milestones)
- `NEXT_SESSION_PLAN.md` (current session target + gate)
- `Sxx/IMPLEMENTATION_REPORT.md` (session acceptance report)
- `logs/YYYY-MM-DD.md` (append-only daily trace)

Templates:
- `assets/MASTER_PLAN.template.md`
- `assets/NEXT_SESSION_PLAN.template.md`
- `assets/IMPLEMENTATION_REPORT.template.md`
- `assets/project.template.json`

## Core Engine (advanced)

Direct engine script:
`skills/project-ops/scripts/project-ops.ps1`

Actions:
- `init`
- `list`
- `menu`
- `choose`
- `status`
- `continue`
- `update`
- `assign`
- `kickoff`
- `log`
- `archive`
- `suggest`

## Data Layout

```text
.projects/
├── index.json
└── <project-id>/
    ├── project.json
    ├── MASTER_PLAN.md
    ├── NEXT_SESSION_PLAN.md
    ├── ARCHIVE.md (optional; created on archive)
    ├── logs/YYYY-MM-DD.md
    └── Sxx/IMPLEMENTATION_REPORT.md
```

## Portable Packaging (.skill)

Package this skill for reuse on another OpenClaw host:

```powershell
python "C:/Users/Administrator/AppData/Roaming/npm/node_modules/openclaw/skills/skill-creator/scripts/package_skill.py" "C:/Users/Administrator/.openclaw/workspace/skills/project-ops" "C:/Users/Administrator/.openclaw/workspace/dist"
```

Transfer `dist/project-ops.skill` to the target machine, then unpack into its `workspace/skills/project-ops` and restart gateway.

## Standard Loop

1. `/project`
2. `/project N`
3. `/project suggest`
4. `/project push <id>`
5. Work execution + `/project log <id> ...`
6. `/project archive <id> ...` (when paused/completed)
