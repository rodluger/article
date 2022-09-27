import os
from pathlib import Path

from ... import paths
from ..conda_env import run_in_env
from ..patches import SNAKEMAKE


def build(snakemake_args=[]):
    """Build the article.

    This function builds the article PDF by running ``Snakemake`` in an isolated
    conda environment.

    Args:
        snakemake_args (list): Additional arguments to pass to ``Snakemake``.

    """
    snakefile = Path("${SYW_PATH}") / "workflow" / "build.smk"
    command_pre = f"SNAKEMAKE_OUTPUT_CACHE={paths.user().cache} SNAKEMAKE_RUN_TYPE='build' {SNAKEMAKE} -c1 --use-conda --reason --cache"
    command = f"{command_pre} {' '.join(snakemake_args)} -s {snakefile}"
    result = run_in_env(command, check=False)
    if result.returncode > 0:
        os._exit(1)
