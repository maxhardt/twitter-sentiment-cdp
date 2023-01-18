# Cloudera Machine Learning (CML) base image
FROM docker.repository.cloudera.com/cloudera/cdsw/ml-runtime-jupyterlab-python3.9-standard:2022.11.1-b2

# Install the transformers package and dependencies
RUN python3 -m pip install --no-cache-dir --upgrade pip && \
    python3 -m pip install --no-cache-dir \
    torch \
    transformers

# Override Runtime label and environment variables metadata
ENV ML_RUNTIME_EDITION="Hugging Face Transformers Edition" \
       	ML_RUNTIME_SHORT_VERSION="0.1" \
        ML_RUNTIME_MAINTENANCE_VERSION=0 \
        ML_RUNTIME_DESCRIPTION="This CML runtime includes the Transformers package with Pytorch backend"

ENV ML_RUNTIME_FULL_VERSION="${ML_RUNTIME_SHORT_VERSION}.${ML_RUNTIME_MAINTENANCE_VERSION}"

LABEL com.cloudera.ml.runtime.edition=$ML_RUNTIME_EDITION \
        com.cloudera.ml.runtime.full-version=$ML_RUNTIME_FULL_VERSION \
        com.cloudera.ml.runtime.short-version=$ML_RUNTIME_SHORT_VERSION \
        com.cloudera.ml.runtime.maintenance-version=$ML_RUNTIME_MAINTENANCE_VERSION \
        com.cloudera.ml.runtime.description=$ML_RUNTIME_DESCRIPTION
