FROM python:3.11

WORKDIR /workspace

# Update and install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    libssl-dev \
    libffi-dev \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    tree \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip and install Python packages
RUN pip install --upgrade pip

COPY agent-ipython /usr/local/agent-ipython
RUN pip install /usr/local/agent-ipython

RUN pip install google-cloud-bigquery pyarrow db-dtypes pandas matplotlib scikit-learn seaborn numpy scipy statsmodels xgboost plotly tabulate snowflake-connector-python duckdb openpyxl
RUN pip install dbt-duckdb
RUN pip install "snowflake-snowpark-python[pandas]"
# Set the default command to run when starting the container

CMD aipy-server & tail -f /dev/null
