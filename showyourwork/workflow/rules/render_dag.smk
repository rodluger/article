"""
Defines the rule ``syw__render_dag`` to render the article DAG.

Runs the script :doc:`render_dag` to generate ``dag.pdf``.

"""
from showyourwork import paths

# All figure output files
figures = config["tree"]["figures"].keys()


rule:
    """
    Render the article DAG.

    """
    name:
        "syw__render_dag"
    message:
        "Rendering the article DAG..."
    input:
        config["ms_tex"],
        config["dependencies"][config["ms_tex"]],
        WORKFLOW_GRAPH,
        "showyourwork.yml",
    output:
        "dag.pdf",
    conda:
        (paths.showyourwork().envs / "render_dag.yml").as_posix()
    params:
        repo=paths.user().repo,
        flags=paths.user().flags,
        data=paths.user().data,
        scripts=paths.user().scripts,
        figures=paths.user().figures,
        tex=paths.user().tex,
        compile=paths.user().compile,
        preprocess=paths.user().preprocess,
        resources=paths.showyourwork().resources,
    script:
        "../scripts/render_dag.py"
