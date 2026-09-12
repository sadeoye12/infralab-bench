The nightly molecule export job is being killed by the orchestrator before it can
finish. The entrypoint is `/app/sweep/run.sh`, and production gives it a strict
3-second runtime budget.

The repaired job must write `/app/results.csv` for downstream consumers. That
CSV must contain exactly two columns, `mol_id` and `batch_id`, with one row for
every molecule matched by the sweep. The batch mapping is stored in the
`chemistry` PostgreSQL database.

Fix the pipeline so it completes within the timeout and produces the complete
CSV artifact. Do not skip candidates or replace the pipeline with hardcoded
sample output.
