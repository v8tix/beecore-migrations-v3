## Metadata

| Field        | Value                                           |
|--------------|-------------------------------------------------|
| Project      | `beecore-migrations-v3`                         |
| Date         | REPLACE: 2026-07-22                             |
| AI Agents    | Claude Sonnet 5 · Claude                        |

---

## Rules

We can use the skill to review the rules for generating files, prompts, and text. All generated content must comply with these rules.

```
cpgs-clg-ai:token-efficiency
```

---

## Task

### Title

Migrate beecore-migrations-v2 located here `/Users/vrock/Public/V8TIX/repos/Deilora/beecore-migrations-v2` to beecore-migrations-v3 located here `/Users/vrock/Public/V8TIX/repos/Deilora/beecore-migrations-v3`

### Description

Context

We are migrating from Cockroachdb to PostgreSQL, so we need to mirror the previous repository into this directory `/Users/vrock/Public/V8TIX/repos/Deilora/beecore-migrations-v3/local`

Acceptance Criteria

[ ] Check the previous repository to understand its structure and functionality.

[ ] Begin implementing each functionality incrementally.

[ ] The migration must be tested using this services `/Users/vrock/Public/V8TIX/repos/Deilora/beecore-net/cluster/docker-compose.yml`.



Other Information

Don't delete anything from `/Users/vrock/Public/V8TIX/repos/Deilora/beecore-migrations-v2`

## Agent Instructions

### Workflow

Execute this task using the following sequential skill workflow. **Invoke each skill via its slash command. Stop after each phase and wait for explicit approval before proceeding.**

**Variables:**
- `$OUTPUT_DIR` = `temp`

| # | Phase    | Skill                                       | Output Document                                           | Gate                            |
|---|----------|----------------------------------------------|------------------------------------------------------------|----------------------------------|
| 1 | Define   | `agent-skills:spec-driven-development`       | `$OUTPUT_DIR/<microservice>-<ticket>-phase-1-spec.md`      | Produce doc. Wait for approval. |
| 2 | Plan     | `agent-skills:planning-and-task-breakdown`   | `$OUTPUT_DIR/<microservice>-<ticket>-phase-2-plan.md`      | Produce doc. Wait for approval. |
| 3 | Build    | `agent-skills:incremental-implementation`    | `$OUTPUT_DIR/<microservice>-<ticket>-phase-3-build.md`     | Produce doc. Wait for approval. |
| 4 | Test     | `agent-skills:test-driven-development`       | `$OUTPUT_DIR/<microservice>-<ticket>-phase-4-test.md`      | Produce doc. Wait for approval. |
| 5 | Review   | `agent-skills:code-review-and-quality`       | `$OUTPUT_DIR/<microservice>-<ticket>-phase-5-review.md`    | Produce doc. Wait for approval. |
| 6 | Simplify | `agent-skills:code-simplification`           | `$OUTPUT_DIR/<microservice>-<ticket>-phase-6-simplify.md`  | Produce doc. Wait for approval. |
| 7 | Ship     | `agent-skills:shipping-and-launch`           | `$OUTPUT_DIR/<microservice>-<ticket>-phase-7-ship.md`      | Produce doc. Wait for approval. |

**Rules:**
- At each gate, output: current phase done, path of saved doc, next phase description, then ask: `"Proceed to phase X: <skill>? (y/n)"`
- Because we don't have a ticket assigned adapt the names as convenience
