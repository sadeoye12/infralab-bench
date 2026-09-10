# Building InfraLab-Bench

This document is the implementation guide for InfraLab-Bench. It defines the project boundary, benchmark contract, architecture, task-development process, review gates, evaluation method, failure taxonomy, and staged release plan.

## 1. Project objective

InfraLab-Bench will evaluate whether coding agents can diagnose and repair realistic production failures in AI infrastructure and MLOps systems from a terminal. It will focus on one evaluation loop:

```text
tasks -> agent execution -> telemetry -> verification -> failure analysis -> better tasks and evaluation data
```

The project is not intended to duplicate a general coding benchmark or build a new universal agent framework. Harbor will provide the standard agent-to-task execution layer where practical. InfraLab-Bench will concentrate its engineering effort on task quality, reproducible environments, secure behavioural verifiers, expert review, and useful analysis.

## 2. Scope

### Minimum viable benchmark

The MVP contains two complete tasks:

1. `api-schema-regression`
2. `ci-false-green`

Each task must have a broken environment, instruction, metadata, oracle solution, isolated verifier, negative controls, and documented validation results.

### Pilot release

Version `0.1.0` will contain:

- eight reviewed tasks across application code, containers, CI/CD, infrastructure as code, ML pipeline integrity, and observability;
- at least two real coding agents plus oracle and lightweight baselines;
- three attempts for every agent-task pair;
- a machine-readable result set and a concise leaderboard;
- at least one annotated failure-analysis report;
- exact run configuration and reproducibility instructions;
- documented limitations and threats to validity.

### Deferred work

The following are deliberately outside the first release:

- a custom general-purpose agent harness;
- a hosted evaluation service or polished dashboard;
- real AWS accounts or paid cloud dependencies;
- a large task count achieved at the expense of review quality;
- training a new foundation model;
- claiming broad model rankings from a small pilot suite.

## 3. Architecture

The system will be split into clear components:

| Component | Responsibility |
|---|---|
| Task ingestion | Discover tasks, parse metadata, and reject invalid definitions |
| Environment preparation | Build pinned container images and initialise the broken state |
| Agent interface | Pass the instruction and terminal environment to a supported agent |
| Execution sandbox | Enforce time, CPU, memory, network, and filesystem boundaries |
| Test harness | Start the independent verifier and collect assertion outcomes |
| Scoring engine | Convert verifier results into the official binary reward |
| Telemetry | Capture commands, timestamps, outputs, patches, and resource use |
| Result storage | Persist immutable run metadata and artefacts |
| Analysis | Aggregate metrics and apply expert failure labels |
| Reporting | Produce tables, summaries, and reproducibility records |

Core records should include `Task`, `RepositorySnapshot`, `Environment`, `AgentRun`, `Trajectory`, `Action`, `Patch`, `TestRun`, `Metric`, `EvaluationResult`, and `BenchmarkVersion`. A stable run identifier must link every emitted artefact.

## 4. Task contract

Each task will eventually use this layout:

```text
tasks/<task-id>/
├── instruction.md
├── task.toml
├── README.md
├── environment/
│   ├── Dockerfile
│   ├── docker-compose.yaml
│   └── app/
├── solution/
│   └── solve.sh
└── tests/
    ├── Dockerfile
    ├── test.sh
    └── test_outputs.py
```

### `instruction.md`

State the incident, observable symptoms, required end state, allowed actions, and relevant constraints. The instruction must be specific enough for independent reviewers to agree on what success means without prescribing a particular patch.

### `task.toml`

Record at least:

- stable task identifier and version;
- category and capability labels;
- environment and verifier image references;
- timeout, CPU, and memory limits;
- network policy;
- expected reward type;
- deterministic seed where applicable;
- supported platform requirements.

### `environment/`

Contain only information available to the agent. It must reproduce the broken state from a clean build, use pinned dependencies, expose useful diagnostic evidence, and avoid leaking verifier tests or the reference solution.

### `solution/`

Contain an expert-authored oracle repair. It validates that the task is solvable but must not define the only acceptable implementation.

### `tests/`

Run outside the agent environment and check observable behaviour. The verifier must emit a structured result and write `1` only when all mandatory assertions pass.

## 5. Building a task

Use the same sequence for every task.

### Step 1: Define the capability

Write one sentence describing the behaviour being measured. Avoid combining unrelated abilities merely to make a task appear difficult.

### Step 2: Write the success contract

List the external conditions that must hold after repair. Separate mandatory behaviour from diagnostic information. Ensure there can be more than one valid implementation.

### Step 3: Create the broken environment

Start from a working system and introduce a deliberate fault. Record the source of the fault, expected symptoms, and why the failure represents realistic engineering work. The clean task image must fail consistently.

### Step 4: Write the incident instruction

Describe what an engineer would reasonably know at the beginning of an incident. Include constraints that affect correctness or safety. Do not reveal the root cause or the exact patch.

### Step 5: Produce the oracle solution

Solve the task manually and encode a reliable reference repair. Record the commands and patch used so the task can be reproduced during review.

### Step 6: Build the isolated verifier

Test outcomes such as service startup, API behaviour, malformed-input handling, preserved functionality, permissions, policy compliance, and regressions. Do not reward the presence of a specific filename or exact source-code string when behaviour can be tested directly.

### Step 7: Add negative controls

Create plausible incorrect solutions, including partial fixes and shortcuts. Confirm that all earn `0`. Include attempts to modify tests, spoof output, disable checks, or otherwise tamper with evaluation where relevant.

### Step 8: Test determinism

Run the untouched baseline and oracle repeatedly from fresh builds. The baseline must always earn `0`; the oracle must always earn `1`. Investigate any intermittent result before accepting the task.

### Step 9: Conduct expert review

Have another reviewer reproduce the task from its documentation and inspect the instruction, environment, oracle, verifier, and negative controls. Record substantive changes resulting from review.

### Step 10: Version the task

Changing instructions, environment state, dependencies, verifier logic, or success conditions requires an explicit task-version change. Published results must identify the exact version used.

## 6. Verifier integrity

The verifier is part of the benchmark's scientific instrument and must be treated as security-sensitive.

It must:

- run in a container separate from the agent environment;
- remain unavailable to the agent before verification;
- check external behaviour and relevant invariants;
- reject partial repairs and introduced regressions;
- avoid accepting user-controlled text as proof of success;
- use clear timeouts and fail closed when a mandatory check cannot run;
- emit assertion-level diagnostic data without weakening the binary reward;
- be tested against evaluator modification, output spoofing, and expected-answer leakage.

Verifier tests should not require a single exact patch. A correct alternative repair must be accepted whenever it satisfies the stated contract.

## 7. Task review gates

A task cannot enter the benchmark until every gate passes:

- The instruction identifies the required outcome and relevant constraints.
- A clean environment reproduces the failure consistently.
- The oracle solution consistently earns `1`.
- The untouched baseline consistently earns `0`.
- Plausible incorrect and incomplete solutions earn `0`.
- The verifier accepts multiple valid implementations where alternatives exist.
- Existing functionality is checked for regressions.
- Tests, expected answers, reference solutions, and credentials do not leak.
- Dependencies and base images are pinned, preferably by digest for releases.
- The task runs without internet access.
- Runtime, CPU, and memory limits are declared.
- A second reviewer can reproduce the result using the documentation.

## 8. Pilot task specifications

### `api-schema-regression`

A FastAPI inference service starts, but a prediction endpoint returns a response that is incompatible with the published schema. The task should test code tracing, API-contract reasoning, regression repair, invalid-input behaviour, and preservation of the health endpoint.

Required verifier coverage:

- service starts within the allowed time;
- health check succeeds;
- valid prediction input returns the required schema and types;
- malformed input produces the documented client error;
- existing unaffected behaviour remains correct;
- no verifier or environment safety controls were modified.

### `ci-false-green`

A CI workflow reports success although the intended test suite is not executed. The task should test workflow inspection, command and path reasoning, reproduction of the skipped tests, and correction without deleting or weakening the suite.

Required verifier coverage:

- the intended tests are discovered and executed;
- a known failing fixture causes the workflow-equivalent command to fail;
- the repaired application passes the real suite;
- test files and required assertions remain intact;
- the workflow does not ignore failures or force a zero exit status.

### Remaining pilot tasks

- `model-artifact-mismatch`: validate artefact identity, checksum, loading, and compatible inference.
- `docker-nonroot-failure`: restore service operation without returning to root execution.
- `terraform-iam-repair`: restore required permissions while rejecting wildcard or excessive access.
- `pipeline-data-leakage`: remove validation leakage and prove correct dataset separation.
- `observability-blackout`: restore trustworthy metrics and distinguish health from visibility.
- `dependency-upgrade-regression`: repair a version-specific input failure while preserving supported behaviour.

Use LocalStack, mocks, policy engines, or fixtures for cloud-facing tasks. Do not require personal credentials or uncontrolled external services.

## 9. Runner and command-line interface

After the two tasks prove the format, add a small Python package exposing:

```bash
uv run infralab validate
uv run infralab run --agent oracle --task all
uv run infralab report results/latest
```

The first implementation needs only four modules:

- `cli.py` for commands and argument validation;
- `runner.py` for task execution and timeouts;
- `validation.py` for task-schema and integrity checks;
- `reporting.py` for result aggregation and export.

Failure taxonomy logic may begin as a reviewed YAML vocabulary and become code only when automation provides clear value.

## 10. Run record

Every run must capture enough information for another person to reproduce it:

- benchmark and task version;
- Git commit SHA;
- environment and verifier image digests;
- model provider, exact model identifier, and model version where available;
- agent and harness name and version;
- prompt or instruction template version;
- token, time, CPU, and memory budgets;
- network policy and deterministic seed;
- start time, duration, terminal-action count, and exit state;
- patch or final filesystem diff;
- verifier assertions and binary reward;
- estimated cost where the provider exposes sufficient data;
- infrastructure-error status separate from model failure.

## 11. Evaluation protocol

Begin with four evaluation conditions:

1. Oracle solution, to establish solvability.
2. Untouched or no-op baseline, to establish failure.
3. One lightweight baseline agent.
4. At least two real coding agents for the pilot report.

Run each agent three times on every task from a fresh environment. Use the same budgets and environment policy when making direct comparisons. Do not retry selectively after observing a failure.

Report:

- overall pass rate;
- pass rate by capability category;
- 95% confidence interval for pass rates;
- per-task and across-run variance;
- median completion time;
- median number of terminal actions;
- estimated model cost where available;
- regression rate;
- failure-category distribution;
- infrastructure failures separately from agent failures.

Use paired comparisons when agents run on the same task instances. Bootstrap intervals may be used for secondary continuous metrics. Avoid presenting a single percentage without its run count and uncertainty.

## 12. Failure analysis

Assign one primary label and optional secondary labels after reviewing the trajectory and verifier output:

- `task-misinterpretation`
- `weak-exploration`
- `incorrect-root-cause`
- `environment-damage`
- `incomplete-fix`
- `regression-introduced`
- `failed-self-verification`
- `premature-termination`
- `timeout`
- `reward-hacking-attempt`
- `infrastructure-failure`

For selected runs, publish an annotated analysis covering:

1. Evidence available to the agent.
2. The action or inference where it departed from the evidence.
3. Whether it recognised and recovered from the mistake.
4. The exact behavioural condition rejected by the verifier.
5. The benchmark, verifier, agent, or training-data improvement suggested by the failure.

Do not infer private chain-of-thought. Analyse observable commands, outputs, patches, summaries, and verifier results.

## 13. Implementation phases

### Phase 0: Validate the research question

Confirm that the selected tasks test a meaningful gap rather than duplicating existing suites. Define primary claims, intended users, comparison baselines, and threats to validity.

**Exit criterion:** a written benchmark scope and two reviewed task specifications.

### Phase 1: Prove the task format

Build `api-schema-regression` and `ci-false-green`, including oracle solutions, isolated verifiers, and negative controls.

**Exit criterion:** fresh baseline runs always score `0`, fresh oracle runs always score `1`, and a second reviewer can reproduce both.

### Phase 2: Build the core evaluator

Implement task discovery, metadata validation, local execution, binary scoring, structured results, and the minimal CLI.

**Exit criterion:** one command validates and runs both MVP tasks and emits complete run records.

### Phase 3: Harden the sandbox

Enforce network isolation, resource limits, timeouts, clean state, verifier separation, and artefact collection.

**Exit criterion:** isolation tests reject test leakage, evaluator tampering, and persistence between runs.

### Phase 4: Add metrics and reporting

Compute the agreed outcome, efficiency, reliability, behavioural, and quality measures. Generate machine-readable and human-readable reports.

**Exit criterion:** repeated runs produce a reproducible summary with uncertainty and infrastructure failures separated.

### Phase 5: Expand the task pipeline

Add the remaining six pilot tasks using the same authoring and review gates.

**Exit criterion:** all eight tasks pass baseline, oracle, determinism, isolation, negative-control, and independent-review checks.

### Phase 6: Add baseline agents

Integrate the oracle, no-op, lightweight baseline, and selected real agents through Harbor. Lock model, harness, budget, and container versions.

**Exit criterion:** every supported agent can complete a full benchmark run using one documented command or configuration.

### Phase 7: Run experimental validation

Execute three trials per agent-task pair, review failed trajectories, calculate metrics, and test whether conclusions are stable under reasonable analysis choices.

**Exit criterion:** raw results, aggregate results, uncertainty, and failure labels are internally consistent and reproducible.

### Phase 8: Publish `v0.1.0`

Publish eight tasks, comparative results, a limitations section, one failure report, exact reproduction instructions, and a tagged release. Describe the suite as a pilot benchmark.

**Exit criterion:** a new user can reproduce a sample task and verify a published result from the public documentation.

### Phase 9: Prepare community contribution

Add task proposals, contribution rules, reviewer guidance, benchmark versioning policy, and a process for accepting, rejecting, and deprecating tasks.

**Exit criterion:** external contributions can be reviewed without weakening task quality or invalidating past results.

## 14. Automated checks to add incrementally

Do not add empty workflows. Introduce each check only when its target exists:

- lint and unit tests for the Python package;
- task-schema validation;
- clean baseline smoke tests;
- oracle smoke tests;
- determinism tests across fresh builds;
- verifier-isolation and leakage tests;
- checks for mutable verifier paths and unexpected network access;
- reproducibility tests using pinned images.

## 15. Release checklist

Before `v0.1.0`:

- All eight tasks satisfy every review gate.
- All published images and dependencies are pinned.
- Every agent-task pair has three non-selective attempts.
- Raw and aggregate results identify exact versions and budgets.
- Confidence intervals and run counts accompany pass rates.
- Infrastructure failures are excluded from model-failure counts but still disclosed.
- At least one failed trajectory has a documented expert analysis.
- Limitations, ethical considerations, security assumptions, and threats to validity are explicit.
- Reproduction instructions work on a clean supported machine.
- The release is tagged and immutable result artefacts are attached.

## 16. Standard for success

The project succeeds when an external reviewer can inspect it and see evidence of five abilities: defining an AI capability precisely, building controlled terminal environments, designing trustworthy correctness oracles, comparing agents with sound experimental practice, and explaining failures from observable evidence.

Eight rigorous tasks are preferable to dozens of shallow examples. The benchmark should remain small until its verifiers, review process, and reported claims are strong enough to justify expansion.
