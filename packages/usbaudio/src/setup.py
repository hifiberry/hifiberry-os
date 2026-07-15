from setuptools import setup, find_packages

setup(
    name="hifiberry-usbaudio",
    version="0.1.0",
    description="HiFiBerry USB Audio Gadget Service",
    long_description="Presents the HiFiBerry device as a UAC2 USB sound card and "
                     "routes the received audio to the HiFiBerry DAC using PipeWire.",
    author="HiFiBerry",
    author_email="support@hifiberry.com",
    license="MIT",
    packages=find_packages(exclude=["tests"]),
    install_requires=[
        # Standard library only (subprocess, argparse, json, glob).
    ],
    data_files=[
        ('/usr/lib/systemd/user', [
            'systemd/usbaudio.service',
            'systemd/usbaudio-state.service',
        ]),
        ('/usr/lib/systemd/system', ['systemd/hifiberry-usbgadget.service']),
        ('/etc/hifiberry/players.d', ['players.d/usbaudio.json']),
        ('/etc/hifiberry/players.d/icons', ['players.d/icons/usbaudio.svg']),
    ],
    entry_points={
        "console_scripts": [
            "hifiberry-usbaudio=hifiberry_usbaudio.main:main",
            "hifiberry-usbgadget=hifiberry_usbaudio.gadget_cli:main",
        ],
    },
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires=">=3.6",
)
