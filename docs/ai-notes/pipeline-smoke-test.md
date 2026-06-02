# Pipeline Smoke Test

Purpose: record that the agent-pipeline Issue→PR wiring was smoke-tested end-to-end.

Date: 2026-06-02

What this verifies:
- The repository's pipeline wiring resolves to `freaxnx01/agent-pipeline@v1`.
- A labeled issue triggers the pipeline and produces a draft pull request.
- The pipeline posts a metrics comment back on the originating issue.
