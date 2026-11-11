# syntax=docker/dockerfile:1
ARG R_IMAGE=rocker/r-ver:4.5.3@sha256:f5a72ffeea7ed592b2a5990f87101beef8ef3cae0e4ff7327088e80368f0aef9

FROM ${R_IMAGE} AS packages
RUN sed -i 's|http://|https://|g' /etc/apt/sources.list.d/ubuntu.sources \
    && apt-get -o Acquire::Retries=1 -o Acquire::https::Timeout=20 \
        -o APT::Update::Error-Mode=any update \
    && apt-get install -y --no-install-recommends build-essential cmake libuv1-dev libpq-dev \
        libgdal-dev libgeos-dev libproj-dev libudunits2-dev libssl-dev libpng-dev \
    && rm -rf /var/lib/apt/lists/*
ENV RENV_CONFIG_CACHE_ENABLED=false \
    RENV_CONFIG_AUTOLOADER_ENABLED=false \
    RENV_CONFIG_PAK_ENABLED=false
WORKDIR /build
COPY docker/renv.lock docker/restore.R ./
RUN Rscript --vanilla restore.R

FROM ${R_IMAGE} AS runtime
# Plotly's JSON serialization needs a UTF-8 process locale for hover labels.
ENV TZ=Europe/Berlin \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8
RUN sed -i 's|http://|https://|g' /etc/apt/sources.list.d/ubuntu.sources \
    && apt-get -o Acquire::Retries=1 -o Acquire::https::Timeout=20 \
        -o APT::Update::Error-Mode=any update \
    && apt-get install -y --no-install-recommends libuv1t64 libpq5 ca-certificates \
        libgdal34t64 libgeos-c1t64 libproj25 libudunits2-0 libssl3t64 libpng16-16t64 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 10001 app \
    && useradd --uid 10001 --gid app --create-home app
ENV R_LIBS_USER=/opt/library \
    SHINY_PORT=3838 \
    HOME=/home/app
WORKDIR /app
COPY --from=packages /opt/library /opt/library
COPY shiny/app.R ./app.R
COPY shiny/R/ ./R/
COPY shiny/www/ ./www/
COPY docker/start.R docker/healthcheck.R /opt/docker/
USER 10001:10001
EXPOSE 3838
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD ["Rscript", "--vanilla", "/opt/docker/healthcheck.R"]
CMD ["Rscript", "--vanilla", "/opt/docker/start.R"]
