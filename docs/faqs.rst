FAQs
====

Below is a non-exhaustive list of frequently asked questions with suggested
answers and solutions. If you don't find what you're looking for here, consider
taking a look at the `issues <https://github.com/showyourwork/showyourwork/issues>`__
page on |showyourwork| GitHub repo. Also make sure to check out the list of
`closed issues <https://github.com/showyourwork/showyourwork/issues?q=is%3Aissue+is%3Aclosed>`__,
where you might find that others have run into your exact problem before.
Finally, always make sure you are using the latest version of |showyourwork|, as
your error could be due to a bug we have since fixed! You can always upgrade to
the latest version by running ``pip install -U showyourwork``.

As a last resort before opening an issue on the GitHub repository,
please take a look to the :ref:`known_issues` for a list of issues known by the developers,
but which have not yet been fixed in a stable release.


Debugging local builds
----------------------

A *lot* of things can generally go wrong when building an article with |showyourwork|.
The workflow will try its best to give you an informative error message, but
if you can't figure out what the problem is (or you don't know how to fix it),
consider the following tips:

- Upgrade |showyourwork| by running ``pip install -U showyourwork``.

- Upgrade ``conda`` by running ``conda upgrade conda``.

- Inspect the build logs. These live in `.showyourwork/logs` and contain a lot of
  the verbose output that's suppressed from the terminal by default (see :doc:`logging`).

- Run ``showyourwork clean`` or, if that doesn't help, ``showyourwork clean --force``.
  These commands remove all build output, which could help resolve issues caused by
  builds that are interrupted by an error or when the user cancels them halfway.
  If you don't want to lose your output, you could also try just deleting the
  temporary `.showyourwork` directory (instead of running the ``clean`` command),
  which removes the cache and forces re-evaluation of the build graph.

- Identify which part of the workflow is causing the problem. Is it during the run of a
  particular figure script? Consider adding a ``breakpoint``
  in your code to enable interactive debugging. Or is the problem specific to the LaTeX build
  step? LaTeX errors, in particular, can be extremely cryptic. Inspect the
  `.showyourwork/logs/tectonic.log` file for details. Consider commenting out
  portions of your manuscript to identify which part is causing the problem.

- If one of your figures is causing a new error, it can be helpful to temporarily
  bypass it by placing the old figure output (e.g., the `.pdf` file) in the ``src/static``
  directory and commenting out the ``\script`` command in the TeX file. This causes
  |showyourwork| to treat the figure as static, preventing it from trying to re-generate
  it the next time you run ``showyourwork``.

- Sometimes, cryptic errors can occur if you've made a mistake in the config file. Certain
  settings require a very specific YAML syntax, so please check :doc:`config` to ensure
  you've provided, e.g., the ``datasets`` information correctly.

- Check the `GitHub Issues <https://github.com/showyourwork/showyourwork/issues>`__
  to see if others have run into the same issue. It's also worth checking out the
  `closed issues <https://github.com/showyourwork/showyourwork/issues?q=is%3Aissue+is%3Aclosed>`__
  for ones that have already been resolved!

- If all else fails, feel free to `raise a new issue <https://github.com/showyourwork/showyourwork/issues/new>`__,
  and we will do our best to get back to you with suggestions promptly.

- Finally, if you're really stumped and you suspect the error is in |showyourwork| itself,
  you can try cloning `the showyourwork repository <https://github.com/showyourwork/showyourwork>`__ and
  installing |showyourwork| in development mode (run ``python setup.py develop`` inside the
  repository), which will allow you to tinker with the code, add breakpoints, print
  statements, etc.


Debugging remote builds
-----------------------

If your article build works locally but fails on GitHub Actions, a few different
things could be going on.

- A common cause is you forgot to push a
  particular script to the remote, so make sure you don't have any unstaged
  changes, and that your `.gitignore` files aren't preventing you from
  committing necessary files.

- It's also useful to make sure you've provided all the necessary repository
  secrets, such as ``SANDBOX_TOKEN``, which is used to access the Zenodo
  Sandbox API to download files from the remote cache. See :doc:`zenodo` for
  details. If you're reproducing someone else's article and don't have access
  to their API token, you can either set ``run_cache_rules_on_ci`` to ``true``
  in the config file to allow running cached rules on GitHub Actions (see :doc:`config`),
  or you can switch to a cache deposit you have read/write access to. To do this,
  delete the `zenodo.yml` file at the root of the repository and run
  ``showyourwork cache create`` (after making sure you've defined the ``$SANDBOX_TOKEN``
  environment variable; see :doc:`zenodo`). Run the workflow locally to populate the
  cache, then commit and push your results. If you've provided the ``SANDBOX_TOKEN``
  repository secret on GitHub (see :doc:`zenodo`), the workflow should now be able
  to access the Sandbox cache.

- A different issue potentially affecting remote builds is hysteresis in your local workflow:
  for example, you may have built your article successfully, then deleted one
  of the scripts needed to generate a figure. The next time you build your
  article, the build could succeed since the figure output is present and there
  are no new instructions specifying how to build it (because the input file
  was deleted). On the remote, however, where the output file does not exist,
  you will get a build failure. You can avoid these sorts of issues by setting
  ``require_inputs`` to ``true``
  in the config file (see :doc:`config`), although in recent versions of |showyourwork|
  that should already be the default.

- Another issue has to do with the fact that |showyourwork| uses conda environments
  instead of actual containers or virtual machines. Conda environments are not always
  free of contamination from packages installed in the global scope. For instance,
  one can import a package from outside the workflow's isolated conda environment
  by tinkering with the ``$PATH`` environment variable within a Python script.
  Such a workflow could succeed locally but fail on the remote, where that package
  may not be present in the global environment. This can especially be a problem if you
  are using tools, packages, or software that are not managed by conda. In that
  case, make sure you are also installing them and making them available to the
  GitHub Actions runner. An example of this is covered below in :ref:`latex_matplotlib`,
  where ``matplotlib`` may require access to a full LaTeX installation to render LaTeX
  strings. Such builds will fail on the remote unless LaTeX is manually installed
  in the workflow YAML file.

- Finally, one can mimic the behavior of the remote build by setting the ``CI=true``
  environment variable prior to running ``showyourwork``. Depending on the nature
  of the error, it could also make sense to look into tools that allow direct
  interaction with the runner on GitHub Actions, such as
  `action-tmate <https://github.com/mxschmitt/action-tmate>`_.


Issues with ``conda``
---------------------

|showyourwork| relies heavily on ``conda`` to manage virtual environments and
package/dependencies installations
(if you don't have ``conda`` installed in the first place, please see :doc:`install`).
If you're running into issues when creating,
activating, or using ``conda`` environments, the first thing you should do is
upgrade ``conda``:

.. code-block:: bash

    conda upgrade conda

Another common error is the ``UnsatisfiableError`` thrown when ``conda`` fails to
resolve dependencies while setting up a new environment. Quite often,
these issues arise when the ``channel_priority`` config setting is set to ``strict``;
read more about that `here <https://conda.io/projects/conda/en/latest/user-guide/tasks/manage-channels.html>`__.
You may, in particular, get a long error message that looks something like this:

.. code-block:: text

    Collecting package metadata (repodata.json): done
    Solving environment: \
    Found conflicts! Looking for incompatible packages.
    This can take several minutes.  Press CTRL-C to abort.
    failed                                                                                                                                                                          \
    Solving environment: \
    Found conflicts! Looking for incompatible packages.
    This can take several minutes.  Press CTRL-C to abort.
    failed

    UnsatisfiableError: The following specifications were found to be incompatible with each other:

    Output in format: Requested package -> Available versions

    Package python conflicts for:

    ...

    Note that strict channel priority may have removed packages required for satisfiability.

The last sentence is key: consider running

.. code-block:: bash

    conda config --set channel_priority false

or change the corresponding setting in your ``.condarc`` file (if you have one). This will give
``conda`` more flexibility in choosing the channels from which to install packages. Note that
``snakemake`` may explicitly warn you that this is a *bad idea* for reproducibility -- it's much
better to require specific, explicit provenances for every package to ensure identical builds on
all machines. However, there are still **lots of wrinkles** to be sorted out regarding strict
channel priorities on the ``conda`` side -- `see here <https://github.com/conda/conda/issues/11555>`__.
For a longer discussion on issues and best practice recommendations related to the reproducibility
of ``conda`` environments -- and a discussion of reproducibility of software in general --
please check out :doc:`reproducibility`.


Issues with ``datrie``
----------------------

The ``datrie`` package, a dependency  of ``snakemake``, does not currently (as of
the writing of these docs) have
`wheels built for distributions of Python >= 3.9 <https://pypi.org/project/datrie/#files>`__.
If you don't have a valid ``C/C++``
compiler set up on your machine, the installation of this dependency might fail
when running ``pip install showyourwork``. One workaround is to install ``datrie``
using ``conda``:

.. code-block:: bash

    conda install -c conda-forge datrie

and then re-run ``pip install showyourwork``.


`IncompleteFilesException`
--------------------------

If you run your workflow and interrupt it (e.g., by hitting ``Ctrl + C``) while
a rule is being executed, or if an error in your code causes the workflow to
fail, you may end up with a situation where Snakemake marks some of your output
files as "incomplete". This is useful in cases where the interruption may have
corrupted those files. Snakemake tries to be conservative about this, and requires
users to either re-run the problematic rule or manually mark the files as
incomplete. When this happens, ``showyourwork`` tells the user:

.. code-block:: text

  If you are sure that certain files are not incomplete, mark them as complete with

    showyourwork --cleanup-metadata <filenames>

  To re-generate the files rerun your command with the --rerun-incomplete flag.

Sometimes, however, the ``--cleanup-metadata`` argument does not successfully
clean up the incomplete files. This may be due to either an issue with Snakemake
(see
`here <https://github.com/snakemake/snakemake/issues/828>`__
and `here <https://github.com/snakemake/snakemake/issues/1497>`__) or an issue
with |showyourwork|
(see `here <https://github.com/showyourwork/showyourwork/issues/103>`__); we're
still looking into how to fix this.

If you find yourself stuck trying to cleanup the metadata (in cases where
you would like to keep your current output files), you can try
manually deleting the folder `.snakemake/incomplete`, which keeps track of
that metadata. Alternatively, you can manually delete all of the problematic
output files, which will trigger a re-run of the corresponding rule.


Issues due to git
-----------------

The |showyourwork| workflow relies heavily on command line calls to ``git``.
The pipeline is tested for ``git>=2.24.0``, so certain issues may arise with
older versions. For instance, prior to version ``0.3.0.dev9`` of ``showyourwork``,
the current git branch was determined by running ``git branch --show-current``,
an option that was only introduced in ``git==2.22.0`` and led to strange
behavior on platforms running older versions of ``git``. This issue has since
been addressed, but there may be others that you might encounter if your
``git`` is significantly out of date.
You can always check which version of ``git`` you are using by
running ``git --version``, and upgrade it if needed using ``homebrew`` (MacOS)
or ``apt-get`` (Linux).


Permissions errors in GitHub Actions
------------------------------------

If you try to build a |showyourwork| article from a repository fork
on GitHub Actions, you may run into the following error when the action
attempts to push the results to the ``-pdf`` branch:

.. code-block:: text

    Uploading output
    /tmp/tmp.KORuhtnUA7
    Switched to a new branch 'main-pdf'
    [main-pdf (root-commit) 224ecfd] force-push article output
    2 files changed, 0 insertions(+), 0 deletions(-)
    create mode 100644 arxiv.tar.gz
    create mode 100644
    remote: Permission to $USER/$REPO.git denied to github-actions[bot].
    fatal: unable to access 'https://github.com/$USER/$REPO/': The requested URL returned error: 403

This happens because the default GitHub Actions permissions for the ``GITHUB_TOKEN``
secret are set to ``restricted`` for repository forks. To get the build to work,
go to

.. raw:: html

    <pre>
    https://github.com/<span class="text-highlight">$USER/$REPO</span>/settings/actions
    </pre>

and change the permissions to ``permissive``:

.. image:: _static/workflow_permissions.png
   :width: 60%
   :align: center


.. _latex_matplotlib:


Rendering LaTeX in matplotlib
-----------------------------

When plotting with ``matplotlib``, if you run into errors that look like

.. code-block:: text

    FileNotFoundError: [Errno 2] No such file or directory: 'latex'

or

.. code-block:: text

    RuntimeError: Failed to process string with tex because latex could not be found

you are probably missing a proper ``latex`` installation. Recall that |showyourwork|
uses ``tectonic`` to build your article, which is not compatible with ``matplotlib``.
Instead, you'll have to install a separate TeX distribution, such as TeXLive or MiKTeX.
The same applies to runs on GitHub actions.

The simplest workaround is to disable LaTeX rendering in ``matplotlib``:

.. code-block:: python

    import matplotlib.pyplot as plt
    plt.rcParams.update({"text.usetex": False})

Math-mode strings can still be parsed using the built-in ``matplotlib`` renderer,
and in most cases this will do what you need.
Alternatively, if you just want to use the LaTeX font in your plots, see :ref:`latex_matplotlib_no_install` below.
In some cases, however, the built-in
renderer may not cut it. If you really need a proper LaTeX installation, you'll
have to do a bit of extra work to get your build to pass on GitHub Actions.
First, add the following step to the `build.yml` and `build-pull-request.yml`
workflows in your `.github/workflows` folder, just before the |showyourwork|
``build`` step:

.. code-block:: yaml

    - name: Install TinyTex for matplotlib LaTeX rendering
      id: tinytex
      shell: bash -l {0}
      run: |
        wget -qO- "https://yihui.org/tinytex/install-bin-unix.sh" | sh
        sudo ~/bin/tlmgr install type1cm cm-super

This will install `TinyTex <https://yihui.org/tinytex/>`_, a
very lightweight TeX distribution that should provide everything you need. Note
that this step also installs the ``type1cm`` and ``cm-super`` LaTeX packages,
which may be required by ``matplotlib``. You can specify additional packages
in the same line if needed.

Then, in order for ``matplotlib`` to execute ``latex``, the `~/bin` path needs to
be in the system ``$PATH``. This variable gets overwritten when running scripts inside isolated
``conda`` environments (as |showyourwork| does), so you'll need to add `~\bin`
to the ``$PATH`` *within* your Python script. Therefore, add the
following bit of boilerplate to the top of any scripts that require LaTeX parsing:

.. code-block:: python

    import os
    from pathlib import Path
    os.environ["PATH"] += os.pathsep + str(Path.home() / "bin")

To save some typing, you could instead add this boilerplate to the
`src/scripts/paths.py` file so that
these commands get executed whenever that file is imported into your scripts.


.. _latex_matplotlib_no_install:

Using LaTeX fonts in matplotlib without installing LaTeX
--------------------------------------------------------

If you just want ``matplotlib`` to use Computer Modern fonts so that the font in your plots matches the font in your manuscript,
you can accomplish this without the full LaTeX installation described above.
Just add the following lines to `src/scripts/matplotlibrc`:

.. code-block:: python

    # set font to match LaTeX's Computer Modern
    font.family: serif
    font.serif: cmr10
    mathtext.fontset: cm
    axes.formatter.use_mathtext: True # needed when using cm=cmr10 for normal text


Using `paths.py` within subdirectories
--------------------------------------

For complicated workflows, you may wish to organize your `scripts` directory into
subdirectories. However, this creates a problem with using the ``paths`` module,
since ``import paths`` relies on `paths.py` being in the same directory as your scripts.

In this case, you can simply copy or simlink the `paths.py` file to whichever
subdirectories you need to call it from. Alternatively, you could also
add ``showyourwork`` as a dependency in `environment.yml`, and add the
following to the top of your scripts:

.. code-block:: python

    from showyourwork.paths import user as Paths

    paths = Paths()

You can now use ``paths.data``, ``paths.figures``, etc. as usual.
See `this comment <https://github.com/showyourwork/showyourwork/issues/110#issuecomment-1156785408>`_
for a brief discussion.


Using LaTeX Workshop in VSCode
------------------------------

If you edit and build your articles in `VSCode <https://code.visualstudio.com/>`_,
you need to specify some settings so that VSCode knows
to use |showyourwork| to build your document.

Any new |showyourwork| comes with a default behaviour defines in the
workspace-specific settings file, ``.vscode/settings.json``, in the root directory of the repo.
with the following lines:

.. code-block:: python

    {
      "latex-workshop.latex.external.build.command": "showyourwork",
      "latex-workshop.latex.external.build.args": ["build"],
      "latex-workshop.view.pdf.viewer": "tab",
      "latex-workshop.latex.outDir": "%WORKSPACE_FOLDER%"
    }

As it is, this enables you to build the document
using ``LaTeX Workshop: Build LaTeX project`` in the command palette
or from the left sidebar.

You can edit this file to add more features, such as enabling AutoBuild on save.
open your article pdf in a VSCode tab or a browser tab.
Feel free to change ``tab`` to ``browser`` if you would rather LaTeX Workshop
open your article in a browser tab.

For more details, please refer to the
`LaTeX Workshop documentation <https://github.com/James-Yu/LaTeX-Workshop/wiki>`_.


Figures not getting generated
-----------------------------

If you are getting LaTeX build errors due to a figure not being present, the first
thing you should do is check the build logs in `.showyourwork/logs/showyourwork.log`.
Did the figure script get executed? If so, perhaps the figure was saved to the incorrect
path (did you remember to save it to `src/tex/figures`? See :ref:`paths.py <paths>`). If the figure script is not
being executed, check if you included the appropriate ``\script`` command in the figure
environment in your manuscript (see :doc:`latex`). One other common pitfall is either a
missing figure ``\label`` or a duplicate one. Figure nodes in the article graph are
labeled according to the figure ``\label``, so defining the same label for two different
figures means only one will be indexed by `showyourwork`!


Missing LaTeX class files
-------------------------

If your manuscript uses a custom class file that ``tectonic`` isn't able to automatically
download (like those required by some journals) you may run into a LaTeX compilation
error like this one:

.. code-block:: text

  Failed to compile manuscript. Perhaps you forgot to `\usepackage{showyourwork}`?
  For more information, check out the log file:
  .showyourwork/logs/tectonic.log

The errors printed to the terminal are often cryptic, but if we open the log file
linked above, we can see that the issue is due to a missing class file (in this case,
`aastex631.cls`):

.. code-block:: text

  **
  (ms.tex
  LaTeX2e <2020-02-02> patch level 5
  L3 programming layer <2020-03-06>

  ! LaTeX Error: File `aastex631.cls' not found.

  Type X to quit or <RETURN> to proceed,
  or enter new name. (Default extension: cls)

  Enter file name:

Prior to version ``0.3.1``, `showyourwork` shipped with class files for some of the
major astronomy journals (ApJ, A&A, and MNRAS), so if you were using any of those
you were unlikely to run into this error. However, for various reasons
(such as issues with long-term maintenance of these classes and
better interfacing with Overleaf) we decided it was
best to stop automatically providing these class files as of version ``0.3.1``.

Therefore, articles that define a version of `showyourwork` greater than or equal
to ``0.3.1`` in `showyourwork.yml` must provide all the necessary class and auxiliary
files in `src/tex` as ``git``-tracked files. This applies to both articles created using
``showyourwork setup`` and articles for which the version in `showyourwork.yml` is manually
upgraded. (It does not apply to articles with older version specs, *even if you upgrade your
local installation of showyourwork*.)

So, if you run into this error, we recommend you download all required files directly from
the journal and include them (making sure to ``git add`` them) in your `src/tex` folder.


Branch rename failed
--------------------

In versions of ``showyourwork`` prior to ``0.4.0``, users may occasionally run into the
following error when attempting to run a third party's workflow:

.. code-block:: text

   Fetching Overleaf repo...
   error: refname refs/heads/master not found
   fatal: Branch rename failed

This is a bug in ``showyourwork`` related to the fact that the default git branch on Overleaf
projects is called ``master``, while the default branch on GitHub is called ``main``. This
isn't an issue unless users don't have the correct credentials to access an Overleaf repository,
in which case the ``git clone`` silently fails and no ``master`` branch is created.
If you run into this error, delete or comment out the ``overleaf:`` section of the ``environment.yml``
workflow config and re-run the workflow, or simply upgrade |showyourwork|.


Debugging in |showyourwork|'s conda environment
-----------------------------------------------

Sometimes when debugging it can be helpful to bypass the ``showyourwork build`` command and
run your code manually in the same environment |showyourwork| is using. To do that, you
need to access the `conda environment <https://docs.conda.io/en/latest/>`_ that Snakemake
creates.

If conda is not your default package manager you may need to activate it using
``conda activate``. Once activated, you can view the environments that exist on your
computer using ``conda env list``. On a Unix machine, the output will look something like this:

.. code-block:: text

  base     /path/to/miniconda3
           /path/to/my-article/.snakemake/conda/28e8667c7a3a18371030aff088ceb5c5_

where "`/path/to/`" is often your home directory or wherever you installed Anaconda and cloned your article's repository.

The environment for the |showyourwork| project is not given a name, but the path
to the environment should be listed. The environment path will be something of the form:
`the path to your article` + ``.snakemake/conda`` + `a long
hexadecimal string (called a hash)`. In this example the environment path is
``/path/to/my-article/.snakemake/conda/28e8667c7a3a18371030aff088ceb5c5_``.

To activate the environment, copy and paste that full path and run ``conda activate <full path>``.
For example:

.. code-block:: text

  conda activate /path/to/my-article/.snakemake/conda/28e8667c7a3a18371030aff088ceb5c5_

Ideally there is only one environment per article that fits this format. If this isn't the
case, we recommend selecting the most recent environment (lowest on the list).

From this point, anything you run using the ``python`` command should use the same conda
environment |showyourwork| is using behind the scenes. You can confirm this by running
``which python`` and verifying that the path includes ``.snakemake/conda/``.
