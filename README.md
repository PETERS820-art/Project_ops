# Project Ops for OpenClaw

> **v1.5.0** — 多 Agent 协作版 | [Changelog](CHANGELOG.md) | [github-repo-ops](https://github.com/PETERS820-art/github-repo-ops)

[![Tag](https://img.shields.io/github/v/tag/PETERS820-art/Project_ops?label=version&color=blue)](https://github.com/PETERS820-art/Project_ops/tags)
[![License](https://img.shields.io/github/license/PETERS820-art/Project_ops)](LICENSE)

`project-ops` 是一个面向 OpenClaw 的长期项目运维技能，统一管理 `.projects/` 下的项目状态、执行日志、下一步动作和日常推进建议。

**v1.5.0 新特性：**
- 🔄 **CL/PR 工作流** — 完整的变更请求 → 审批 → 合并生命周期
- 🎯 **SOP 分级** — 自动检测项目复杂度（Solo / Team / Parallel）
- 🤝 **多 Agent 协作** — 支持并发开发、文件锁、审批门禁
- 🔗 **github-repo-ops 集成** — 一键创建 GitHub 仓库作为项目前置

---

## Repository Layout

- `project-ops/`：技能源码目录（可直接放进 OpenClaw `workspace/skills/`）
- `dist/project-ops.skill`：可分发复用包（zip 格式，后缀是 `.skill`）

---

## What This Skill Does

### Core Features
- ✅ 列出项目、菜单选择、按索引继续
- ✅ 更新项目状态与进度
- ✅ 记录工作日志与 kickoff
- ✅ 输出每日推进建议（基于 `git status --porcelain -b` 信号）
- ✅ 归档半成品项目
- ✅ 自动初始化项目文档脚手架

### v1.5.0 New Features
- 🔄 **CL/PR 工作流**（Team/Parallel 模式）
  - `cl-new/claim/status/ready/list` — 变更请求管理
  - `pr-open/checks/approve/merge` — PR 审批流程
  - `board` — 项目全景视图
- 🎯 **SOP 分级**
  - **Solo**：单 agent，直接 push
  - **Team**：2+ agents，CL 追踪 + 1 审批
  - **Parallel**：3+ agents，完整门禁 + 2 审批
- 🤝 **多 Agent 协作**
  - 自动分支命名：`agent/<name>/cl-<id>`
  - 文件锁（Parallel 模式）
  - 审批历史追踪

---

## Prerequisites

### Required: Repository

每个项目必须有仓库。创建方式：

**Option A: github-repo-ops skill（推荐）**
```powershell
powershell -File skills/github-repo-ops/scripts/repo.ps1 create my-project --private --WithReadme
```

**Option B: gh CLI 直接创建**
```powershell
gh repo create my-project --private --add-readme
```

**Option C: 使用现有本地 repo**
直接提供本地路径即可。

---

## Install

### Option A: from source

```powershell
Copy-Item -Recurse -Force .\project-ops "C:\Users\Administrator\.openclaw\workspace\skills\project-ops"
openclaw gateway restart
```

### Option B: from .skill package

```powershell
Copy-Item .\dist\project-ops.skill .\dist\project-ops.zip
Expand-Archive .\dist\project-ops.zip -DestinationPath "C:\Users\Administrator\.openclaw\workspace\skills" -Force
openclaw gateway restart
```

解压后应存在：
```text
C:\Users\Administrator\.openclaw\workspace\skills\project-ops\SKILL.md
```

---

## Usage

### Basic Commands

```powershell
# 项目菜单
powershell -ExecutionPolicy Bypass -File "skills/project-ops/scripts/project.ps1"

# 选中第 N 个项目
powershell -ExecutionPolicy Bypass -File "skills/project-ops/scripts/project.ps1" 2

# 今日推进建议
powershell -ExecutionPolicy Bypass -File "skills/project-ops/scripts/project.ps1" suggest

# 初始化项目（需要 repo）
powershell -ExecutionPolicy Bypass -File "skills/project-ops/scripts/project.ps1" init my-project "My Project" -RepoPath "C:\workspace\my-project"

# 设置 SOP 模式
powershell -ExecutionPolicy Bypass -File "skills/project-ops/scripts/project.ps1" mode team my-project

# kickoff 一个项目
powershell -ExecutionPolicy Bypass -File "skills/project-ops/scripts/project.ps1" push openclaw-dashboard

# 记录日志
powershell -ExecutionPolicy Bypass -File "skills/project-ops/scripts/project.ps1" log openclaw-dashboard "完成接口核对"

# 归档项目
powershell -ExecutionPolicy Bypass -File "skills/project-ops/scripts/project.ps1" archive openclaw-dashboard "暂缓到下个迭代"
```

### CL/PR Commands (Team/Parallel Mode)

```powershell
# 创建变更请求
powershell -File skills/project-ops/scripts/project.ps1 cl-new my-project "添加登录功能"

# 认领 CL
powershell -File skills/project-ops/scripts/project.ps1 cl-claim my-project CL-001 neon

# 标记完成
powershell -File skills/project-ops/scripts/project.ps1 cl-ready my-project CL-001 "测试通过"

# 打开 PR
powershell -File skills/project-ops/scripts/project.ps1 pr-open my-project CL-001

# 审批 PR
powershell -File skills/project-ops/scripts/project.ps1 pr-approve my-project PR-001 susu "LGTM"

# 合并 PR
powershell -File skills/project-ops/scripts/project.ps1 pr-merge my-project PR-001 abc123

# 查看项目看板
powershell -File skills/project-ops/scripts/project.ps1 board my-project
```

完整流程指南：`project-ops/references/cl-pr-workflow.md`

---

## Project Data Contract

项目根目录：`workspace/.projects/`

### Standard Structure

```text
.projects/<id>/
├── project.json              # 机器可读状态
├── MASTER_PLAN.md            # 长期战略
├── NEXT_SESSION_PLAN.md      # 当前会话目标
├── logs/
│   └── YYYY-MM-DD.md         # 追加日志
├── ops/                      # (Team/Parallel 模式)
│   ├── changes/CL-*.json     # 变更请求
│   └── prs/PR-*.json         # PR 记录
└── Sxx/
    └── IMPLEMENTATION_REPORT.md
```

### 详细文档

- `project-ops/references/project-doc-standards.md` — 文档规范
- `project-ops/references/schema.md` — JSON schema
- `project-ops/references/cl-pr-workflow.md` — CL/PR 流程指南

### 模板

- `project-ops/assets/MASTER_PLAN.template.md`
- `project-ops/assets/NEXT_SESSION_PLAN.template.md`
- `project-ops/assets/IMPLEMENTATION_REPORT.template.md`
- `project-ops/assets/project.template.json`

---

## SOP Levels

| Mode | Agents | Features | Approval |
|------|--------|----------|----------|
| **Solo** | 1 | Direct push + logs | None |
| **Team** | 2+ | CL tracking + PR | 1 reviewer |
| **Parallel** | 3+ | Full gates + file locks | 2 reviewers |

自动检测：根据 `agentAssignments` 数量自动设置，或手动指定：
```powershell
/project mode team <project-id>
/project mode parallel <project-id>
```

---

## Security Check Note

发布前已对 `dist/project-ops.skill` 做明文密钥扫描（常见 OpenAI/GitHub/AWS/Bearer/token 模式），未发现明文 key/token。

---

## Compatibility

- **OS**: Windows (PowerShell)
- **Runtime**: OpenClaw gateway
- **Dependencies**: 
  - `gh` CLI (for GitHub operations)
  - `github-repo-ops` skill v1.0.0+ (optional, for repo creation)

---

## License

MIT License. See [LICENSE](LICENSE) (and [LICENCE](LICENCE) alias).

---

## Quick Start Example

```powershell
# 1. 创建 repo
powershell -File skills/github-repo-ops/scripts/repo.ps1 create my-project --private --WithReadme

# 2. 初始化项目
powershell -File skills/project-ops/scripts/project.ps1 init my-project "My Project" -RepoPath "C:\workspace\my-project"

# 3. 设置协作模式
powershell -File skills/project-ops/scripts/project.ps1 mode team my-project

# 4. 开始协作
powershell -File skills/project-ops/scripts/project.ps1 cl-new my-project "Feature X"
powershell -File skills/project-ops/scripts/project.ps1 cl-claim my-project CL-001 neon
# ... 开发完成后 ...
powershell -File skills/project-ops/scripts/project.ps1 cl-ready my-project CL-001 "Done"
powershell -File skills/project-ops/scripts/project.ps1 pr-open my-project CL-001
```
