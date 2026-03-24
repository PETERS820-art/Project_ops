# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.0] - 2026-03-24

### Added
- Published reusable `project-ops` OpenClaw skill source under `project-ops/`.
- Added distributable package `dist/project-ops.skill`.
- Added OpenClaw-friendly installation and usage guide in `README.md`.
- Added `LICENSE` and `LICENCE` files (MIT).
- Added XiaoZ-derived documentation standards:
  - `project-ops/references/project-doc-standards.md`
  - templates for `MASTER_PLAN`, `NEXT_SESSION_PLAN`, `IMPLEMENTATION_REPORT`
- Enhanced `project-ops` init flow to scaffold:
  - `.projects/<id>/MASTER_PLAN.md`
  - `.projects/<id>/NEXT_SESSION_PLAN.md`

### Security
- Ran plaintext secret/token scan on package and repo content before publish.
- No plaintext key/token found in released artifacts.

[1.4.0]: https://github.com/PETERS820-art/Project_ops/releases/tag/v1.4.0
