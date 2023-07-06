import os
import subprocess
from pathlib import Path
from tempfile import TemporaryDirectory

snakefile = """
from showyourwork.patches import get_snakemake_variable, patch_snakemake_cache_optimization

rule main:
    input:
        "C.dat"

checkpoint syw__dag:
    priority:
        snakemake.jobs.Job.HIGHEST_PRIORITY
    output:
        touch("SYW__DAG")

def WORKFLOW_GRAPH(*args):
    snakemake.workflow.checkpoints.syw__dag.get()
    dag = get_snakemake_variable("dag", None)
    patch_snakemake_cache_optimization(dag)
    return []

rule C:
    input:
        "B.dat",
        WORKFLOW_GRAPH
    output:
        "C.dat"
    shell:
        "cat {input[0]} > {output[0]}"

rule A:
    output:
        "A.dat"
    params:
        number=0.25
    shell:
        "echo {params.number} > {output}"

rule B:
    input:
        "A.dat"
    output:
        "B.dat"
    cache:
        True
    shell:
        "cat {input[0]} > {output[0]}"
"""


def test_cache_optimization():
    env = dict(os.environ)
    with TemporaryDirectory() as d:
        d = Path(d)
        cache = d / "cache"
        cache.mkdir(exist_ok=True, parents=True)

        (d / "Snakefile").write_text(snakefile)

        env["SNAKEMAKE_OUTPUT_CACHE"] = cache
        r = subprocess.run(
            ["snakemake", "-c1", "--cache"],
            env=env,
            check=True,
            cwd=d,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        # print(r.stdout.decode())
        # print(r.stderr.decode())
        text = r.stderr.decode()
        assert "rule A:" in text
        assert "rule B:" in text
        assert "rule C:" in text

        for f in d.glob("*.dat"):
            f.unlink()
        for f in d.glob("*.chk"):
            f.unlink()

        r = subprocess.run(
            ["snakemake", "-c1", "--cache"],
            env=env,
            check=False,
            cwd=d,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        print(r.stdout.decode())
        print(r.stderr.decode())

        assert 0
