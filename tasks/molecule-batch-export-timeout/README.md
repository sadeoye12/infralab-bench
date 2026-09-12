# Molecule Batch Export Timeout

This task evaluates whether an agent can repair a timeout-sensitive batch
pipeline that combines a molecule sweep with PostgreSQL-backed batch metadata.

## Capability

Diagnose a compact production-style data pipeline across shell, Python, YAML,
HDF5 cache metadata, and PostgreSQL, then make it produce a complete artifact
within a strict runtime budget.

## Success Contract

- `/app/sweep/run.sh` exits successfully within the orchestrator timeout.
- `/app/results.csv` exists after the pipeline runs.
- The CSV header is exactly `mol_id,batch_id`.
- The CSV contains all 300 matched molecules plus the header row.
- Batch IDs come from the `chemistry` database, including archived batches.
- The repair does not hardcode expected sample rows.

## Layout

- `environment/` contains the broken application state available to the agent.
- `solution/solve.sh` contains the oracle repair used for benchmark validation.
- `tests/test.sh` runs the verifier and writes the binary reward file.
- `tests/test_outputs.py` checks observable behavior and output integrity.

## Validation Notes

The untouched environment should fail because the job exceeds the timeout and
does not leave the required CSV artifact. The oracle solution should pass by
making the sweep path fast enough and producing the DB-backed CSV output.
