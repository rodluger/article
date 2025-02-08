from helpers import TemporaryShowyourworkRepository


class TestOrcidID(TemporaryShowyourworkRepository):
    """Test a paper in which the user input its  OrcidID."""

    # No need to test this on CI
    local_build_only = True

    def customize(self):
        """Create and edit all the necessary files for the workflow."""

        # Import the variable into the tex file
        ms = self.cwd / "src" / "tex" / "ms.tex"
        with open(ms) as f:
            ms_orig = f.read()
        with open(ms, "w") as f:
            ms_new = ms_orig.replace(
                r"\author{@showyourwork}",
                r"\author[0000-0000-0000-0000]{@showyourwork}",
            )
            print(ms_new, file=f)
