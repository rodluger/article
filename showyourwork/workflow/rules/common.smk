from pathlib import Path
from showyourwork import paths


def temporary_tex_files(root=paths.user().compile):
    files = [
        Path(config["ms_tex"]).relative_to(
            paths.user().tex.relative_to(paths.user().repo)
        ),
        config["stylesheet"],
    ] + [Path(f).name for f in config["tex_files_in"]]
    if root == paths.user().compile:
        files.append(config["stylesheet_meta_file"])
    return [(root / f).as_posix() for f in files]
