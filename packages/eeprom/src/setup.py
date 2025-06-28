#!/usr/bin/env python3

from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="hateeprom",
    version="1.2.0",
    author="HiFiBerry",
    author_email="info@hifiberry.com",
    description="HAT EEPROM Reader/Writer Library and CLI Tool",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/hifiberry/hifiberry-os",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Operating System :: POSIX :: Linux",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Topic :: System :: Hardware",
        "Topic :: Software Development :: Libraries :: Python Modules",
    ],
    python_requires=">=3.7",
    install_requires=[
        "libgpiod",
    ],
    entry_points={
        "console_scripts": [
            "hateeprom=hateeprom.cli:main",
        ],
    },
    package_data={
        "hateeprom": ["*.py"],
    },
    include_package_data=True,
)
