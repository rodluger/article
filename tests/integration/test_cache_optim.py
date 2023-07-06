import pytest
from helpers import TemporaryShowyourworkRepository

from showyourwork.config import edit_yaml
from showyourwork.subproc import get_stdout

A = """
# Record the number
with open(snakemake.output[0], "w") as f:
    f.write(str(snakemake.params.number))
"""

B = """
# Take the square root of the input
with open(snakemake.input[0], "r") as f:
    number = float(f.read())
with open(snakemake.output[0], "w") as f:
    f.write(str(number ** 0.5))
"""

C = """
# Double the input
with open(snakemake.input[0], "r") as f:
    number = float(f.read())
with open(snakemake.output[0], "w") as f:
    f.write(str(number * 2))
"""

SNAKEFILE = """
rule C:
    input:
        "src/data/B.dat"
    output:
        "src/data/C.dat"
    script:
        "src/scripts/C.py"

rule A:
    output:
        "src/data/A.dat"
    params:
        number=0.25
    script:
        "src/scripts/A.py"

rule B:
    input:
        "src/data/A.dat"
    output:
        "src/data/B.dat"
    cache:
        True
    script:
        "src/scripts/B.py"
"""


class BaseClass(TemporaryShowyourworkRepository):
    local_build_only = True

    def customize(self):
        with edit_yaml(self.cwd / "showyourwork.yml") as config:
            config["optimize_caching"] = True
            config["dependencies"] = {"src/tex/ms.tex": ["src/data/C.dat"]}
        with open(self.cwd / "Snakefile", "w") as f:
            f.write(SNAKEFILE)
        with open(self.cwd / "src" / "scripts" / "A.py", "w") as f:
            f.write(A)
        with open(self.cwd / "src" / "scripts" / "B.py", "w") as f:
            f.write(B)
        with open(self.cwd / "src" / "scripts" / "C.py", "w") as f:
            f.write(C)

    def build_local(self):
        # Run once to cache things
        print(f"[{self.repo}] Building the article locally (1/2)...")
        get_stdout("CI=false showyourwork build", shell=True, cwd=self.cwd)

        # Delete all output, but keep the cache
        if not self.cache:
            get_stdout("mv .showyourwork/cache .", shell=True, cwd=self.cwd)
        get_stdout(
            "CI=false showyourwork clean --force", shell=True, cwd=self.cwd
        )
        if not self.cache:
            get_stdout(
                "mkdir -p .showyourwork && mv cache .showyourwork/",
                shell=True,
                cwd=self.cwd,
            )

        # Run a second time so we can restore from the cache
        print(f"[{self.repo}] Building the article locally (2/2)...")
        get_stdout("CI=false showyourwork build", shell=True, cwd=self.cwd)

    def check_build(self):
        # Rule `A` should not have run!
        assert (self.cwd / "src" / "data" / "C.dat").exists()
        assert not (self.cwd / "src" / "data" / "A.dat").exists()


class TestLocalCacheOptimization(BaseClass):
    """
    Test the feature that removes jobs from the DAG that are
    made redundant by a downstream cache hit.

    Tests the local cache only.

    See details `here <https://github.com/showyourwork/showyourwork/issues/124>`__.

    """

    cache = False  # (`cache` = the Zenodo Sandbox cache)


@pytest.mark.remote
class TestRemoteCacheOptimization(BaseClass):
    """
    Test the feature that removes jobs from the DAG that are
    made redundant by a downstream cache hit.

    Tests the remote (Zenodo Sandbox) cache only.

    See details `here <https://github.com/showyourwork/showyourwork/issues/124>`__.

    """

    cache = True  # (`cache` = the Zenodo Sandbox cache)
