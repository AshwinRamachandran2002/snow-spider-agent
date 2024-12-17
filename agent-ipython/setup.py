import setuptools

setuptools.setup(
    name="agent-ipython",
    version="0.1.0",
    description="A Python executor server and client using IPython for AI Agents.",
    author="Canwen Xu",
    author_email="canwen.xu@snowflake.com",
    packages=setuptools.find_packages(exclude=["tests", "examples"]),
    py_modules=["client", "server"],
    install_requires=[
        "ipython>=7.0",
    ],
    entry_points={
        "console_scripts": [
            "aipy-server=server:main",
            "aipy=client:main",
        ]
    },
    python_requires=">=3.7",
)
