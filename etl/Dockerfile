# syntax=docker/dockerfile:1
ARG R_IMAGE=rocker/r-ver:4.5.3@sha256:f5a72ffeea7ed592b2a5990f87101beef8ef3cae0e4ff7327088e80368f0aef9

FROM ${R_IMAGE} AS packages
RUN sed -i 's|http://|https://|g' /etc/apt/sources.list.d/ubuntu.sources \
    && apt-get -o Acquire::Retries=1 -o Acquire::https::Timeout=20 \
        -o APT::Update::Error-Mode=any update \
    && apt-get install -y --no-install-recommends build-essential cmake libpq-dev \
        libcurl4-openssl-dev libssl-dev libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

ENV RENV_CONFIG_CACHE_ENABLED=false \
    RENV_CONFIG_AUTOLOADER_ENABLED=false \
    RENV_CONFIG_PAK_ENABLED=false

WORKDIR /build
COPY renv.lock ./renv.lock
RUN Rscript --vanilla -e "install.packages('renv')" \
    && Rscript --vanilla -e "renv::restore(lockfile = 'renv.lock', prompt = FALSE)"

FROM ${R_IMAGE} AS runtime
ENV TZ=Europe/Berlin \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    R_LIBS_USER=/opt/library \
    HOME=/home/etl

RUN sed -i 's|http://|https://|g' /etc/apt/sources.list.d/ubuntu.sources \
    && apt-get -o Acquire::Retries=1 -o Acquire::https::Timeout=20 \
        -o APT::Update::Error-Mode=any update \
    && apt-get install -y --no-install-recommends libpq5 ca-certificates \
        libcurl4t64 libssl3t64 libxml2 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 10002 etl \
    && useradd --uid 10002 --gid etl --create-home etl

WORKDIR /app
COPY --from=packages /opt/library /opt/library
COPY etl/ ./etl/

USER 10002:10002
ENTRYPOINT ["Rscript", "--vanilla", "etl/run_etl.R"]
