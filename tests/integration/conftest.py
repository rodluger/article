import os
import shutil
from pathlib import Path

import pytest

from showyourwork.git import get_repo_sha


def pytest_sessionstart(session):
    # Clean the sandbox
    for folder in (Path(__file__).parents[0] / "sandbox").glob("*"):
        if folder.is_dir():
            shutil.rmtree(folder)


def pytest_addoption(parser):
    parser.addoption(
        "--remote",
        action="store_true",
        dest="remote",
        default=False,
        help="enable remote tests",
    )
    parser.addoption(
        "--workflow-version",
        action="store",
        default=get_repo_sha(),
        help="version of showyourwork to use in showyourwork.yml",
    )
    parser.addoption(
        "--action-spec",
        action="store",
        default="showyourwork",
        help="version spec of showyourwork to install on GH Actions",
    )


def pytest_configure(config):
    config.addinivalue_line(
        "markers", "remote: a test that requires remote access"
    )
    os.environ["WORKFLOW_VERSION"] = str(
        config.getoption("--workflow-version")
    )
    os.environ["ACTION_SPEC"] = str(config.getoption("--action-spec"))


def pytest_collection_modifyitems(config, items):
    if config.getoption("--remote"):
        return
    skipper = pytest.mark.skip(reason="need --remote option to run")
    for item in items:
        if "remote" in item.keywords:
            item.add_marker(skipper)
