"""Install script for `showyourwork`."""
from pathlib import Path

from setuptools import find_namespace_packages, setup

setup(
    name="showyourwork",
    author="Rodrigo Luger",
    author_email="rodluger@gmail.com",
    url="https://github.com/showyourwork/showyourwork",
    description="A workflow for open-source scientific articles",
    long_description=open("README.md", "r").read(),
    long_description_content_type="text/markdown",
    license="MIT",
    packages=find_namespace_packages(),
    use_scm_version={
        "write_to": Path("showyourwork") / "_showyourwork_version.py",
        "write_to_template": '__version__ = "{version}"',
    },
    python_requires=">=3.8",
    install_requires=[
        "graphviz>=0.19.1",
        "jinja2>=3.0.3",
        "pyyaml>=6.0",
        "requests>=2.25.1",
        "click>=8.1.3",
        "cookiecutter>=2.1.1",
        "packaging>=21.3",
        "snakemake==7.20.0",
    ],
    extras_require={
        "tests": [
            "pytest>=7.0.0",
            "pytest-asyncio-cooperative>=0.28.0",
        ]
    },
    entry_points={
        "console_scripts": [
            "showyourwork=showyourwork.cli:entry_point",
        ]
    },
    include_package_data=True,
    zip_safe=False,
)
