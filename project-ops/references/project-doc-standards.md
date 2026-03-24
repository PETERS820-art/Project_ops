# project-ops 文档规范（v1.0）

来源基线：XiaoZ 项目（`notebooklm-local-webui`）的执行文档体系。
目标：让任何 OpenClaw 实例都能在 `.projects/<id>/` 下按同一结构接管项目。

## 1) 目录规范（必选）

```text
.projects/<project-id>/
├── project.json
├── MASTER_PLAN.md
├── NEXT_SESSION_PLAN.md
├── logs/
│   └── YYYY-MM-DD.md
├── Sxx/
│   └── IMPLEMENTATION_REPORT.md
└── docs/ (可选)
    └── *.md
```

## 2) 文件职责（必选）

### `project.json`（机器可读，单一真相源）
- 保存状态字段：`status/progress/currentGoal/nextAction/lastNote`
- 保存执行轨迹：`history[]`（至少 `time/action/note`）
- 保存路由字段：`repoPath/workflowPath/owner/agentAssignments`

### `MASTER_PLAN.md`（长期战略）
必须包含：
1. Locked Product Decisions（冻结决策）
2. Milestones + Session Backlog（M*/S*）
3. Execution Contract（每个 session 的必交付项）
4. Progress Rules（进度区间定义）
5. Expansion Backlog（后续阶段）

### `NEXT_SESSION_PLAN.md`（短周期执行）
必须包含：
1. 当前目标（Current Session Target）
2. Context Lock（当前门禁与不可破坏约束）
3. Task Packet（本轮任务包）
4. 验收清单（Acceptance Checklist）
5. 下一步切换规则（Rule）

### `Sxx/IMPLEMENTATION_REPORT.md`（会话验收）
必须包含：
1. Objective
2. Delivered（文件/模块变更）
3. Result（PASS/REJECT + blocker）
4. Verification Evidence（lint/test/build 或替代证据）
5. Gate Decision（是否允许推进下一 Session）

### `logs/YYYY-MM-DD.md`（当天流水）
- 追加写入，不覆盖
- 每条记录至少包含：时间、agent、简述、状态/进度

## 3) 命名规范

- Session 主线：`S00..S99`
- UX/专项线：`U01..U99` / `X01..X99`
- 报告名固定：`IMPLEMENTATION_REPORT.md`
- 路径固定：`Sxx/IMPLEMENTATION_REPORT.md`

## 4) 状态流转规范

- `REJECT`：`nextAction` 不得推进到后续阶段
- `PASS`：允许推进，并同步 `project.json.progress`
- 任意更新后必须写 `history[]`

## 5) 最小验收清单（每次 session）

1. 更新 `project.json`（至少 `updatedAt/lastNote/nextAction/history`）
2. 写入 `logs/YYYY-MM-DD.md`
3. 产出或更新本轮 `Sxx/IMPLEMENTATION_REPORT.md`
4. 保证 `NEXT_SESSION_PLAN.md` 与当前门禁一致

## 6) 推荐模板路径

- `skills/project-ops/assets/MASTER_PLAN.template.md`
- `skills/project-ops/assets/NEXT_SESSION_PLAN.template.md`
- `skills/project-ops/assets/IMPLEMENTATION_REPORT.template.md`
