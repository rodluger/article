"""
Defines the rule ``syw__arxiv`` to generate a tarball for arXiv submission.

Runs the script :doc:`arxiv` to generate the tarball ``arxiv.tar.gz``.

"""


rule:
    """
    Generate a tarball for arXiv submission.

    """
    name:
        "syw__arxiv"
    message:
        "Generating the arXiv tarball..."
    input:
        temporary_tex_files(),
        (paths.user().compile / f'{config["ms_name"]}.pdf').as_posix(),
        compile_dir=paths.user().compile.as_posix(),
    output:
        "arxiv.tar.gz",
    script:
        "../scripts/arxiv.py"
