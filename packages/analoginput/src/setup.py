from setuptools import setup, find_packages

setup(
    name="hifiberry-analoginput",
    version="1.0.0",
    description="HiFiBerry Analog Input Service",
    long_description="HiFiBerry Analog Input Service for managing analog input functionality. "
                     "Connects ALSA ADC nodes to effect_input.proc using PipeWire.",
    author="HiFiBerry",
    author_email="support@hifiberry.com",
    license="MIT",
    packages=find_packages(),
    install_requires=[
        # Uses standard library only (subprocess, argparse, sys)
    ],
    data_files=[
        ('/usr/lib/systemd/user', [
            'systemd/hifiberry-analoginput.service'
        ]),
    ],
    entry_points={
        "console_scripts": [
            "hifiberry-analoginput=hifiberry_analoginput.main:main",
        ],
    },
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires=">=3.6",
)
