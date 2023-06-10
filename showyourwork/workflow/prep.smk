"""
The Snakefile for the article pre-processing step.

"""
from showyourwork import paths, overleaf
from showyourwork.config import render_config, parse_config, get_run_type
from showyourwork.patches import patch_snakemake_logging
from showyourwork.git import get_repo_branch


# Working directory is the top level of the user repo
workdir: paths.user().repo.as_posix()


# What kind of run is this? (clean, build, etc.)
run_type = get_run_type()


# User config. Allow Jinja2 templating syntax.
render_config()


configfile: (paths.user().temp / "showyourwork.yml").as_posix()


# Report template
report: "report/preprocess.rst"


# Remove temp flags
for file in paths.user().flags.glob("*"):
    file.unlink()


# Remove old logs
for file in paths.user().logs.glob("*.log"):
    file.unlink()


# Set up custom logging for Snakemake
patch_snakemake_logging()


# Parse the config file
parse_config()


# Hack to make the configfile generation the default rule
rule syw__main:
    input:
        config["config_json"],


# Include all other rules
include: "rules/common.smk"
include: "rules/preprocess.smk"


onstart:
    # Overleaf sync: pull in changes
    if run_type == "preprocess" and get_repo_branch() == "main":
        overleaf.pull_files(
            config["overleaf"]["pull"],
            config["overleaf"]["id"],
            commit_changes=not config["github_actions"],
            push_changes=config["github_actions"]
            and config["overleaf"]["gh_actions_sync"],
        )
