# Project Ops Skill for OpenClaw

`project-ops` 是一个面向 OpenClaw 的长期项目运维技能，统一管理 `.projects/` 下的项目状态、执行日志、下一步动作和日常推进建议。

## Repository Layout

- `project-ops/`：技能源码目录（可直接放进 OpenClaw `workspace/skills/`）
- `dist/project-ops.skill`：可分发复用包（zip 格式，后缀是 `.skill`）

## What This Skill Does

- 列出项目、菜单选择、按索引继续
- 更新项目状态与进度
- 记录工作日志与 kickoff
- 输出每日推进建议（基于 `git status --porcelain -b` 信号）
- 归档半成品项目
- 自动初始化项目文档脚手架：
  - `MASTER_PLAN.md`
  - `NEXT_SESSION_PLAN.md`
- 提供 XiaoZ 项目沉淀出的文档规范与模板

## Install (Option A: from source)

把本仓库中的 `project-ops` 文件夹复制到目标 OpenClaw 工作区：

```powershell
Copy-Item -Recurse -Force .\project-ops "C:\Users\Administrator\.openclaw\workspace\skills\project-ops"
openclaw gateway restart
```

## Install (Option B: from .skill package)

`.skill` 本质是 zip 包。解压到目标 `skills` 目录即可：

```powershell
Copy-Item .\dist\project-ops.skill .\dist\project-ops.zip
Expand-Archive .\dist\project-ops.zip -DestinationPath "C:\Users\Administrator\.openclaw\workspace\skills" -Force
openclaw gateway restart
```

解压后应存在：

```text
C:\Users\Administrator\.openclaw\workspace\skills\project-ops\SKILL.md
```

## Usage (OpenClaw commands)

在 OpenClaw 会话中调用包装脚本：

```powershell
# 项目菜单
powershell -ExecutionPolicy Bypass -File "skills/project-ops/scripts/project.ps1"

# 选中第 N 个项目
powershell -ExecutionPolicy Bypass -File "skills/project-ops/scripts/project.ps1" 2

# 今日推进建议
powershell -ExecutionPolicy Bypass -File "skills/project-ops/scripts/project.ps1" suggest

# kickoff 一个项目
powershell -ExecutionPolicy Bypass -File "skills/project-ops/scripts/project.ps1" push openclaw-dashboard

# 记录日志
powershell -ExecutionPolicy Bypass -File "skills/project-ops/scripts/project.ps1" log openclaw-dashboard "完成接口核对"

# 归档项目
powershell -ExecutionPolicy Bypass -File "skills/project-ops/scripts/project.ps1" archive openclaw-dashboard "暂缓到下个迭代"
```

## Project Data Contract

项目根目录：`workspace/.projects/`

每个项目建议结构：

```text
.projects/<id>/
├── project.json
├── MASTER_PLAN.md
├── NEXT_SESSION_PLAN.md
├── logs/YYYY-MM-DD.md
└── Sxx/IMPLEMENTATION_REPORT.md
```

详细规范：
- `project-ops/references/project-doc-standards.md`
- `project-ops/references/schema.md`

模板：
- `project-ops/assets/MASTER_PLAN.template.md`
- `project-ops/assets/NEXT_SESSION_PLAN.template.md`
- `project-ops/assets/IMPLEMENTATION_REPORT.template.md`
- `project-ops/assets/project.template.json`

## Security Check Note

发布前已对 `dist/project-ops.skill` 做明文密钥扫描（常见 OpenAI/GitHub/AWS/Bearer/token 模式），未发现明文 key/token。

## Compatibility

- OS: Windows (PowerShell)
- Runtime: OpenClaw gateway

## License

MIT License. See `LICENSE` (and `LICENCE` alias).
