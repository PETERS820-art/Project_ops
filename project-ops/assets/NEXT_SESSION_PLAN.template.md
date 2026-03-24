# NEXT_SESSION_PLAN.md

Project: <project-id>
Current Session Target: <Sxx/Uxx>

## Context Lock
- Current gate: <blocked/unblocked>
- Must preserve: ...
- Must not do: ...

## Task Packet
- <task-1>
- <task-2>
- <task-3>

## Execution Protocol (strict)
For each issue/task:
1. Record symptom + expected behavior
2. Implement minimal patch
3. Run lint/test/build (or agreed subset)
4. Return "what changed / how to verify"
5. Append result to daily log

## Acceptance Checklist
- [ ] Target scope completed
- [ ] No regression on critical path
- [ ] User/owner sign-off received
- [ ] `project.json` + logs updated

## Rule
- Do not start next stage until explicit sign-off.
