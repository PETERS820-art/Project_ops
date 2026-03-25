# Changelog

All notable changes to this project will be documented in this file.

## [1.5.0] - 2026-03-25

### Added
- **SOP Levels**: Auto-detected project modes (Solo/Team/Parallel)
- **CL/PR Workflow**: Full change request and pull request lifecycle
  - `cl-new/claim/status/ready/list` commands
  - `pr-open/checks/approve/merge` commands
  - `board` command for project overview
- **github-repo-ops integration**: Repository creation as prerequisite
- **Documentation**: `cl-pr-workflow.md` guide
- **Auto branch naming**: `agent/<name>/cl-<id>` pattern

### Changed
- `repoPath` now required for `project init`
- Enhanced project.json schema with `mode`, `repoStatus` fields
- Split CL/PR logic into separate `project-cl.ps1` script

### Fixed
- PowerShell variable reference syntax in CL/PR engine
- Review counting logic for merge approval checks

### Dependencies
- Requires `github-repo-ops` skill for repo creation (v1.0.0+)

## [1.4.0] - 2026-03-24
- Initial release with project management basics

[1.5.0]: https://github.com/PETERS820-art/Project_ops/releases/tag/v1.5.0
