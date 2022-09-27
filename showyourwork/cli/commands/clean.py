import shutil
from pathlib import Path

from ... import paths
from ..conda_env import run_in_env
from ..patches import SNAKEMAKE


def clean(force, deep, options=""):
    """Clean the article build.

    Args:
        force (bool): If True, forcefully delete files in output directories.
        deep (bool): If True, delete all temporary Snakemake and showyourwork directories.
        options (str, optional): Additional options to pass to Snakemake.

    """
    if (paths.user().repo / ".snakemake" / "incomplete").exists():
        shutil.rmtree(paths.user().repo / ".snakemake" / "incomplete")
    for file in ["build.smk", "prep.smk"]:
        snakefile = snakefile = Path("${SYW_PATH}") / "workflow" / file
        command_pre = f"SNAKEMAKE_OUTPUT_CACHE={paths.user().cache} SNAKEMAKE_RUN_TYPE='clean' {SNAKEMAKE} -c1 --use-conda --reason --cache"
        command = f"{command_pre} {options} -s {snakefile} --delete-all-output"
        result = run_in_env(command)
    if (paths.user().repo / "arxiv.tar.gz").exists():
        (paths.user().repo / "arxiv.tar.gz").unlink()
    if paths.user().temp.exists():
        shutil.rmtree(paths.user().temp)
    if force:
        for file in paths.user().figures.rglob("*.*"):
            if file.name != ".gitignore":
                file.unlink()
        for file in paths.user().data.rglob("*.*"):
            if file.name != ".gitignore":
                file.unlink()
    if deep:
        if (paths.user().repo / ".snakemake").exists():
            shutil.rmtree(paths.user().repo / ".snakemake")
        if paths.user().home_temp.exists():
            shutil.rmtree(paths.user().home_temp)
