rule sywplug__tex_copy_files_to_build:
    """
    Copy files that are required to build the document from the project
    directory to the build directory.
    """
    input:
        "{file}"
    output:
        SYW__WORK_PATHS.build / "{file}"
    run:
        utils.copy_file_or_directory(input[0], output[0])


build_dir = SYW__WORK_PATHS / "build"
style_paths = set()

def _build_dependendencies_for(doc):
    deps_func = get_document_dependencies(doc)
    def impl(*_):
        deps = deps_func()
        return [build_dir / dep for dep in deps]
    return impl

for doc in SYW__DOCUMENTS:
    doc_dir = Path(doc).parent
    name = paths.path_to_rule_name(doc)
    pdf = SYW__WORK_PATHS.output / Path(doc).with_suffix(".pdf")

    # If multiple documents live within the same directory, we only want to copy
    # the style files once.
    #
    # TODO(dfm): These rules are also implemented nearly identically in the
    # dependencies file. Could we refactor this?
    if str(doc_dir) not in style_paths:
        style_paths.add(str(doc_dir))

        rule:
            """
            Copy the appropriate ``showyourwork`` style file to the build work
            directory. In this case, we're using the ``build.tex`` style, which
            defines all our custom macros.
            """
            name:
                f"sywplug__tex_build_style_{name}"
            input:
                SYWPLUG__TEX_RESOURCE("resources", "build.tex")
            output:
                build_dir / doc_dir / "showyourwork.tex"
            run:
                utils.copy_file_or_directory(input[0], output[0])

        rule:
            """
            Copy the ``showyourwork`` class file to the build work directory. If
            the project contains a ``showyourwork.sty`` file in the same
            directory as the document, we use that instead of the standard one
            provided by showyourwork, allowing users to customize behavior.
            """
            name:
                f"sywplug__tex_build_class_{name}"
            input:
                sywplug__tex_local_or_provided_style(doc)
            output:
                build_dir / doc_dir / "showyourwork.sty"
            run:
                utils.copy_file_or_directory(input[0], output[0])

    rule:
        """
        Copy the document from the parent work directory to the build work
        directory.
        """
        name:
            f"sywplug__tex_build_doc_{name}"
        input:
            SYW__WORK_PATHS.root / doc
        output:
            build_dir / doc
        run:
            utils.copy_file_or_directory(input[0], output[0])

    rule:
        """
        Compile the document using ``tectonic``.
        """
        name:
            f"sywplug__tex_build_{name}"
        input:
            dependencies=_build_dependendencies_for(doc),
            document=build_dir / doc,
            style=build_dir / doc_dir / "showyourwork.tex",
            classfile=build_dir / doc_dir / "showyourwork.sty",
        output:
            pdf,
            output_directory=directory(SYW__WORK_PATHS.output),
        conda:
            SYWPLUG__TEX_RESOURCE("envs", "tectonic.yml")
        shell:
            """
            tectonic                                 \\
                --chatter minimal                    \\
                --keep-logs                          \\
                --keep-intermediates                 \\
                --synctex                            \\
                --outdir {output.output_directory:q} \\
                {input.document:q}
            """

    rule:
        """
        Copy the output PDF from the output directory to the same directory as
        the source file.
        """
        name:
            f"sywplug__tex_build_copy_output_{name}"
        input:
            pdf
        output:
            Path(doc).with_suffix(".pdf")
        run:
            utils.copy_file_or_directory(input[0], output[0])
