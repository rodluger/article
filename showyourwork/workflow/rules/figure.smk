"""
Defines rules ``syw__figX`` to generate figure output, where ``X`` is the
figure number.

"""
from showyourwork import paths


figures = config["tree"]["figures"]
fignum = 1
graphics_with_rules = []

for figure_name in figures:
    # Get figure metadata
    figscript = figures[figure_name]["script"]
    graphics = figures[figure_name]["graphics"]
    dependencies = figures[figure_name]["dependencies"]
    command = figures[figure_name]["command"]
    static = figures[figure_name]["static"]

    # If we already have a rule to generate all of the
    # graphics for this figure, skip it
    if all(graphic in graphics_with_rules for graphic in graphics):
        continue
    graphics_with_rules.extend(graphics)

    # If there's no command to generate this figure, skip it
    if command is None:
        continue

    # Static figures don't have scripts
    if figscript is None:
        figscript = []

    # User-friendly rule name
    rulename = f"syw__fig{fignum}"
    fignum += 1

    rule:
        """
        Generate a figure given a figure script and optional dependencies.

        """
        name:
            rulename
        message:
            "Generating figure output: {output}..."
        input:
            figscript,
            dependencies,
            "environment.yml" if not static else [],
        output:
            report(graphics, category="Figure"),
        conda:
            (paths.user().repo / "environment.yml").as_posix()
        params:
            command=command,
        shell:
            "{params.command}"
