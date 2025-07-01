#!/usr/bin/env python3

from setuptools import setup, find_packages

# Long description for the package
long_description = """
HAT EEPROM Reader/Writer Library and CLI Tool

This library provides functionality to read and write HAT EEPROM data using 
bitbanging I2C over GPIO pins with libgpiod. Features include:

- Enhanced error handling with proper exception raising
- Retry logic for GPIO initialization with configurable parameters  
- Randomized retry delays to prevent multi-process conflicts
- HAT specification compliant EEPROM parsing
- Vendor information extraction from ATOM 0x01
- Command-line tool and Python library
- Support for multiple EEPROM types (24C32, 24C64, 24C128, 24C256)

Version 1.3.0 includes significant reliability improvements and better
library compatibility for use in other applications.
"""

setup(
    name="hateeprom",
    version="1.3.0",
    author="HiFiBerry",
    author_email="info@hifiberry.com",
    description="HAT EEPROM Reader/Writer Library and CLI Tool",
    long_description=long_description,
    long_description_content_type="text/plain",
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
