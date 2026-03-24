# project-ops schema (v1.1)

## Root

- `.projects/index.json`: lightweight registry for list/lookup
- `.projects/<id>/project.json`: canonical status
- `.projects/<id>/MASTER_PLAN.md`: strategic plan + milestone/session design
- `.projects/<id>/NEXT_SESSION_PLAN.md`: immediate execution gate
- `.projects/<id>/Sxx/IMPLEMENTATION_REPORT.md`: per-session acceptance report
- `.projects/<id>/logs/YYYY-MM-DD.md`: append-only logs

## index.json

```json
{
  "version": "1.0",
  "updatedAt": "...",
  "projects": [
    {
      "id": "openclaw-dashboard",
      "name": "OpenClaw Dashboard Enhanced",
      "status": "active",
      "progress": 60,
      "owner": "Mika",
      "type": "product",
      "updatedAt": "...",
      "path": ".projects/openclaw-dashboard/project.json"
    }
  ]
}
```

## project.json required keys

- `id` (string)
- `name` (string)
- `status` (`active|blocked|on_hold|archived|done`)
- `progress` (0-100)
- `owner` (string)
- `type` (string, e.g. product/research)
- `repoPath` (string)
- `workflowPath` (string)
- `currentGoal` (string)
- `nextAction` (string)
- `lastNote` (string)
- `agentAssignments` (array)
- `milestones` (array)
- `history` (array)
- `createdAt`, `updatedAt` (string)

## project.json recommended optional keys

- `productDecisions` (object)
- `qualityGates` (object)
- `riskRegister` (array)

## history[] minimum shape

```json
{
  "time": "2026-03-24 23:00:00 GMT+8",
  "action": "update",
  "note": "...",
  "status": "active",
  "progress": 73
}
```
