.. _known_issues:

Known issues
============

This page collects issues that are known by the developers but they
are not yet fixed in the latest release.

Each entry reports also the original issue tracker from GitHub.

`Build on github is broken with 'pulp' has no attribute 'list_solvers' (#435) <https://github.com/showyourwork/showyourwork/issues/435>`_
-----------------------------------------------------------------------------------------------------------------------------------------

When using *showyourwork!*, along with the local version you installed on your computer
another one will be installed by GitHub for its server-side action
in order to compile the final document when you push your changes to the upstream repository.

If you see this error in your workflow logs you need to change what version of *showyourwork!*
is installed on the GitHub side.
This  can be directly done by editing the ``.github/workflows/build.yml`` file saved
in your local *showyourwork!* article directory.

For example, if you want GitHub to install and use the latest development version of *showyourwork!*,
then look for the following lines in the ``build.yml`` and ``build-pull-request.yml`` workflow files
and modify the ``Build the article PDF`` step like this,

.. code-block:: yaml

    - name: Build the article PDF
      id: build
      with:
        showyourwork-spec: git+https://github.com/showyourwork/showyourwork
      uses: showyourwork/showyourwork-action@v1

`'\variable' command does not work inside '\caption{...}' (#419) <https://github.com/showyourwork/showyourwork/issues/419>`_
----------------------------------------------------------------------------------------------------------------------------

When putting the ``\variable{}`` command inside (e.g. a figure's) ``\caption{}``, then the
corresponding ``Snakefile`` rule will not be triggered.

A workaround is to explicitly define in the ``showyourwork.yml`` that the main
manuscript depends on the output of this ``Snakefile`` rule, ensuring it will always be
executed. Then, ``\variable{}`` will simply work like ``\include{}`` (which may also be
used in this case).

`Package 'showyourwork' requires a different Python' (#505) <https://github.com/showyourwork/showyourwork/issues/505>`_
-----------------------------------------------------------------------------------------------------------------------

This is an error that arises from a change in the conda installation on the remote.

The solution is to add update the version of the Github Action used by the ``build.yml`` and ``build-pull-request.yml`` workflows
to use the latest unreleased version of the action:

.. code-block:: yaml

      - name: Build the article PDF
        id: build
        with:
          showyourwork-spec: git+https://github.com/showyourwork/showyourwork
        uses: showyourwork/showyourwork-action@main
        env:
          SANDBOX_TOKEN: ${{ secrets.SANDBOX_TOKEN }}
          OVERLEAF_TOKEN: ${{ secrets.OVERLEAF_TOKEN }}

`KeyError: 'tex_files_out' (#400) <https://github.com/showyourwork/showyourwork/issues/400>`_
-----------------------------------------------------------------------------------------------------------------------------------------

This error should arise only if you are using showyourwork v0.4.3
or if you updated your project ot that specific version.

If this is your case and you do not want to update showyourwork
to the latest development version, please comment line 405 in
`src/showyourwork/workflow/scripts/preprocess.py` which should be
`if graphic not in config["tex_files_out"]`.
