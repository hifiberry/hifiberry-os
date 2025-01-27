from setuptools import setup

setup(
    name="configurator",
    version="1.0.0",
    description="System configuration scripts",
    long_description="System configuration scripts",
    author="HiFiBerry",
    author_email="support@hifiberry.com",
    license="MIT",
    packages=["configurator"],
    entry_points={
        "console_scripts": [
            "config-asoundconf=configurator.asoundconf:main",
            "config-configtxt=configurator.configtxt:main",
            "config-hattools=configurator.hattools:main",
            "config-installer=configurator.installer:main",
            "config-detect=configurator.soundcard_detector:main",
            "config-detectpi=configurator.pimodel:main",
            "config-soundcard=configurator.soundcard:main"
        ],
    },
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires=">=3.6",
)

