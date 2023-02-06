import inspect
import json
from collections import defaultdict

from showyourwork import paths
from showyourwork.dependencies import write_manuscript_dependencies

working_directory = paths.work(config).root

checkpoint _syw_dependency_check:
    input:
        paths.work(config).dependencies
    output:
        working_directory / "manuscript_dependencies.json"
    run:
        write_manuscript_dependencies(input[0], output[0])

def get_manuscript_dependencies(*_):
    # This checkpoint call serves two purposes: (1) it makes sure that we have
    # extracted the list of all dependencies from the manuscript, and (2) it
    # ensures that the DAG of jobs has been constructed.
    with checkpoints._syw_dependency_check.get().output[0].open() as f:
        manuscript_dependencies = json.load(f)

    # Walk up the call stack to find an object called "dag"... yeah, this is a
    # hack, but we haven't found a better approach yet!
    dag = None
    for level in inspect.stack():
        dag = level.frame.f_locals.get("dag", None)
        if dag is not None:
            break
    
    # If "dag" is still None, then we couldn't find it. We shouldn't ever hit
    # this (until snakemake renames the variable...), but we have a check just
    # to be sure.
    if dag is None:
        raise RuntimeError(
            "Could not find DAG object in call stack. This error shouldn't "
            "ever be hit, but you found it! Please report the issue on the "
            "showyourwork GitHub page."
        )

    # Map the full tree of data dependencies. Here we're collecting the
    # "parents" for every file that has a rule defined.
    parents = defaultdict(set)
    for job in dag.jobs:
        for output in job.output:
            parents[output] |= set(str(f) for f in job.input)
    parents = {k: list(sorted(v)) for k, v in parents.items()}

    # Store the dependency tree in the global "config" object. This is also a
    # bit of a hack, but this gives us a nice way to provide downstream rules
    # with access to the computed dependency tree.
    config["_dependency_tree"] = parents

    # Also save the manuscript dependencies to the "config" object for
    # downstream usage.
    config["_manuscript_dependencies"] = manuscript_dependencies

    return manuscript_dependencies

rule _syw_dump_dependencies:
    input:
        get_manuscript_dependencies
    output:
        working_directory / "_dependency_tree.json"
    run:

        with open(output[0], "w") as f:
            json.dump(config["_dependency_tree"], f)