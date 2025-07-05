"""
Setup configuration for Financial Data Pipeline project.
"""

from setuptools import setup, find_packages

# Read requirements from requirements.txt
with open("requirements.txt", "r", encoding="utf-8") as fh:
    requirements = [line.strip() for line in fh if line.strip() and not line.startswith("#")]

# Read long description from README
with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="financial-data-pipeline",
    version="1.0.0",
    author="Your Name",
    author_email="your.email@example.com",
    description="Automated pipeline for analyzing sectoral performance of financial markets",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/yourusername/financial-data-pipeline",
    project_urls={
        "Bug Tracker": "https://github.com/yourusername/financial-data-pipeline/issues",
        "Documentation": "https://github.com/yourusername/financial-data-pipeline/docs",
        "Source Code": "https://github.com/yourusername/financial-data-pipeline",
    },
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Financial and Insurance Industry",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Topic :: Office/Business :: Financial",
        "Topic :: Scientific/Engineering :: Information Analysis",
        "Topic :: Software Development :: Libraries :: Python Modules",
    ],
    package_dir={"": "python-scripts"},
    packages=find_packages(where="python-scripts"),
    python_requires=">=3.9",
    install_requires=requirements,
    extras_require={
        "dev": [
            "pytest>=7.2.0",
            "pytest-cov>=4.0.0",
            "pytest-mock>=3.10.0",
            "black>=22.12.0",
            "flake8>=6.0.0",
            "isort>=5.11.0",
            "mypy>=0.991",
            "pre-commit>=2.21.0",
        ],
        "docs": [
            "sphinx>=5.3.0",
            "sphinx-rtd-theme>=1.1.0",
            "mkdocs>=1.4.0",
            "mkdocs-material>=8.5.0",
        ],
        "analysis": [
            "jupyter>=1.0.0",
            "matplotlib>=3.6.0",
            "seaborn>=0.12.0",
            "plotly>=5.12.0",
        ],
    },
    entry_points={
        "console_scripts": [
            "financial-pipeline=ingestion.cli:main",
            "data-validator=utils.data_quality:main",
            "test-connections=utils.aws_utils:test_connections",
        ],
    },
    include_package_data=True,
    package_data={
        "": ["*.yaml", "*.yml", "*.json", "*.sql"],
    },
    zip_safe=False,
    keywords=[
        "finance",
        "data-engineering",
        "etl",
        "aws",
        "airflow",
        "redshift",
        "dbt",
        "stock-market",
        "sector-analysis",
        "financial-data",
        "pipeline",
        "automation",
    ],
)