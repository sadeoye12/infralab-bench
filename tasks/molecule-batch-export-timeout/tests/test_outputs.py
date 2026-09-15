"""Validation tests for the molecule-batch-export-timeout task.

Category: application/bioinformatics
"""

import subprocess


def _run(cmd: str) -> subprocess.CompletedProcess[str]:
    """Run a shell command and return the result."""
    return subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=60)


def test_check_1():
    """Pipeline runs within timeout successfully"""
    result = _run("timeout 3.5 bash /app/sweep/run.sh")
    assert result.returncode == 0, (
        f"Command failed (exit {result.returncode}): Pipeline runs within timeout successfully\n"
        f"stdout: {result.stdout}\nstderr: {result.stderr}"
    )


def test_check_2():
    """results.csv exists"""
    result = _run("test -f /app/results.csv && echo 'exists' || echo 'missing'")
    output = result.stdout + result.stderr
    assert output.strip() == "exists", (
        f"Expected exact match for: results.csv exists\n"
        f"Expected: 'exists'\nGot: {output.strip()!r}"
    )


def test_check_3():
    """results.csv has exactly 300 rows plus header"""
    result = _run("wc -l < /app/results.csv | tr -d ' ' || echo 'error'")
    output = result.stdout + result.stderr
    assert output.strip() == "301", (
        f"Expected exact match for: results.csv has exactly 300 rows plus header\n"
        f"Expected: '301'\nGot: {output.strip()!r}"
    )


def test_check_4():
    """results.csv has correct join data (active)"""
    result = _run("grep -c 'mol_001,B-1001' /app/results.csv || true")
    output = result.stdout + result.stderr
    assert output.strip() == "1", (
        f"Expected exact match for: results.csv has correct join data (active)\n"
        f"Expected: '1'\nGot: {output.strip()!r}"
    )


def test_check_5():
    """results.csv includes archived rows from the base table"""
    result = _run("grep -c 'mol_003,B-1003' /app/results.csv || true")
    output = result.stdout + result.stderr
    assert output.strip() == "1", (
        "Expected exact match for: results.csv has correct join data "
        "(archived, proves base table used instead of view)\n"
        f"Expected: '1'\nGot: {output.strip()!r}"
    )


def test_check_6():
    """results.csv has the expected header"""
    result = _run("head -n 1 /app/results.csv || echo 'error'")
    output = result.stdout + result.stderr
    assert output.strip() == "mol_id,batch_id", (
        f"Expected exact match for: results.csv has the expected header\n"
        f"Expected: 'mol_id,batch_id'\nGot: {output.strip()!r}"
    )


def test_check_7():
    """No hardcoded shortcuts in run.sh"""

    result = _run("cat /app/sweep/run.sh")
    output = result.stdout + result.stderr
    assert "mol_001,B-1001" not in output, (
        f"Forbidden literal found for: No hardcoded shortcuts in run.sh\n"
        f"Forbidden: 'mol_001,B-1001'\nOutput: {output[:500]}"
    )
