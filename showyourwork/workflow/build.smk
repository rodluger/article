"""
The Snakefile for the main article build step.

"""
from showyourwork import paths, exceptions, overleaf
from showyourwork.patches import patch_snakemake_wait_for_files, patch_snakemake_logging, patch_snakemake_missing_input_leniency
from showyourwork.config import parse_config, get_run_type
from showyourwork.logging import get_logger
from showyourwork.userrules import process_user_rules
from showyourwork.git import get_repo_branch
import snakemake


# Working directory is the top level of the user repo
workdir: paths.user().repo.as_posix()


# What kind of run is this? (clean, build, etc.)
run_type = get_run_type()


# The configfile is autogenerated by the `prep.smk` workflow
if (paths.user().temp / "config.json").exists():


    # Load the autogenerated config
    configfile: (paths.user().temp / "config.json").as_posix()


    # Workflow report template
    report: "report/workflow.rst"


    # Remove old flags
    for file in paths.user().flags.glob("*"):
        file.unlink()


    # Set up custom logging for Snakemake
    patch_snakemake_logging()


    # Parse the config file
    parse_config()


    # Hack to make the pdf generation the default rule
    rule syw__main:
        input:
            config["ms_pdf"],
            (config["ms_name"] + ".synctex.gz" if config["synctex"] else [])

    # Wrap other top-level rules to ensure tempfiles are properly
    # deleted; these are the rules we actually call from the Makefile
    rule syw__arxiv_entrypoint:
        input:
            "arxiv.tar.gz"

    rule syw__ar5ivist_entrypoint:
        input:
            (paths.user().compile_html / "index.html").as_posix()
        output:
            (paths.user().html / "index.html").as_posix()
        params:
            compile_dir=paths.user().compile_html.as_posix(),
            output_dir=paths.user().html.as_posix()
        shell:
            "cp -r {params.compile_dir} {params.output_dir}"


    # Include all other rules
    include: "rules/common.smk"
    include: "rules/dag.smk"
    include: "rules/arxiv.smk"
    include: "rules/compile.smk"
    include: "rules/zenodo.smk"
    include: "rules/figure.smk"
    include: "rules/ar5ivist.smk"
    include: "rules/render_dag.smk"

    # Resolve ambiguities in rule order
    ruleorder: syw__compile > syw__arxiv
    ruleorder: syw__compile > syw__ar5ivist


    # Include custom rules defined by the user
    include: (paths.user().repo / "Snakefile").as_posix()
    process_user_rules()


    # Hack to display a custom message when a figure output is missing
    patch_snakemake_wait_for_files()


    # Snakemake workflows complete successfully if there's no rule to generate
    # a given file but it is present on disk. This is bad for third-party
    # reproducibility, so here we hack it to require all inputs to be present.
    if config["require_inputs"]:
        patch_snakemake_missing_input_leniency()


else:


    if run_type != "clean":
        raise exceptions.MissingConfigFile()


onsuccess:


    # Overleaf sync: push changes
    if run_type == "build" and get_repo_branch() == "main":
        overleaf.push_files(config["overleaf"]["push"], config["overleaf"]["id"])


    # We're done
    get_logger().info("Done!")
