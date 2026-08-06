from setuptools import setup, find_packages

setup(
    name="hifiberry-aes67",
    version="0.3.2",
    description="HiFiBerry AES67 receiver",
    long_description="Receives AES67 audio from a Dante network and routes it to "
                     "the HiFiBerry DAC using PipeWire.",
    author="HiFiBerry",
    author_email="support@hifiberry.com",
    license="MIT",
    packages=find_packages(exclude=["tests"]),
    install_requires=[
        # Standard library only (subprocess, json, http.server, urllib).
    ],
    data_files=[
        ('/usr/lib/systemd/user', [
            'systemd/aes67.service',
            'systemd/aes67-agent.service',
        ]),
        ('/etc/hifiberry/players.d', ['players.d/aes67.json']),
        ('/etc/hifiberry/players.d/icons', ['players.d/icons/aes67.svg']),
        ('/etc/hifiberry/auth.d', ['data/etc/hifiberry/auth.d/aes67.json']),
        ('/etc/configserver/conf.d', ['data/etc/configserver/conf.d/aes67.json']),
        ('/etc/audiocontrol/players.d', ['data/etc/audiocontrol/players.d/aes67.json']),
        ('/etc/nginx/hifiberry-api.d', ['debian/hifiberry-aes67.nginx']),
    ],
    entry_points={
        "console_scripts": [
            "hifiberry-aes67=hifiberry_aes67.main:main",
        ],
    },
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires=">=3.6",
)
