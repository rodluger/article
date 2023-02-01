"""
Defines the rule ``syw__compile`` to build the article PDF.

Runs the script :doc:`pdf` to generate the article ``ms.pdf``.

"""
from pathlib import Path
from showyourwork import paths

rule:
    """
    Setup the temporary files for compilation.

    """
    name:
        "syw__compile_setup"
    message:
        "Generating the article stylesheet metadata..."
    input:
        config["ms_tex"],
        config["dependencies"][config["ms_tex"]],
        config["tex_files_in"],
        "dag.pdf" if config["dag"]["render"] else [],  # TODO(dfm): remove this?
        WORKFLOW_GRAPH,
        "showyourwork.yml",
        "zenodo.yml" if (paths.user().repo / "zenodo.yml").exists() else [],
        stylesheet=(paths.showyourwork().resources / "styles" / "build.tex").as_posix()
    output:
        temporary_tex_files(),
        compile_dir=directory(paths.user().compile.as_posix()),
    params:
        metadata=True
    script:
        "../scripts/compile_setup.py"

rule:
    """
    Compile the manuscript into the article PDF.

    """
    name:
        "syw__pdf"
    message:
        "Compiling the article PDF..."
    input:
        temporary_tex_files(),
        # TODO(dfm): Can probably remove the following once stylesheet is rm'd
        "dag.pdf" if config["dag"]["render"] else [],
        WORKFLOW_GRAPH,
        "showyourwork.yml",
        "zenodo.yml" if (paths.user().repo / "zenodo.yml").exists() else [],
        compile_dir=paths.user().compile.as_posix()
    output:
        (paths.user().compile / f'{config["ms_name"]}.pdf').as_posix(),
        (paths.user().compile / f'{config["ms_name"]}.synctex.gz').as_posix(),
    conda:
        (paths.showyourwork().envs / "tectonic.yml").as_posix()
    shell:
        """
        cd "{input.compile_dir}"
        tectonic                  \\
            --chatter minimal     \\
            --keep-logs           \\
            --keep-intermediates  \\
            --synctex             \\
            "{input[0]}"
        """

rule:
    name:
        "syw__copy_pdf"
    message:
        "Copying the article PDF..."
    input:
        (paths.user().compile / f'{config["ms_name"]}.pdf').as_posix()
    output:
        config["ms_pdf"]
    shell:
        """
        cp "{input}" "{output}"
        """

rule:
    name:
        "syw__copy_synctex"
    message:
        "Copying the article synctex..."
    input:
        (paths.user().compile / f'{config["ms_name"]}.synctex.gz').as_posix()
    output:
        config["ms_name"] + ".synctex.gz"
    shell:
        """
        cp "{input}" "{output}"
        """

rule:
    """
    Compile the manuscript into the article PDF.

    """
    name:
        "syw__compile"
    message:
        "Generating the article PDF..."
    input:
        config["ms_pdf"],
        (config["ms_name"] + ".synctex.gz" if config["synctex"] else [])
    output:
        touch(paths.user().flags / "SYW__COMPILE")
