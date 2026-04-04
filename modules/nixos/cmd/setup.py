from setuptools import setup

setup(
    name="pos",
    version="1.0.0",
    py_modules=["pos", "secrets"],
    install_requires=["click"],
    entry_points={
        "console_scripts": [
            "pos=pos:cmd",
        ],
    },
)
