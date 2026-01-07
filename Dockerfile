FROM rocker/shiny-verse:4.5.0

# System-Abhängigkeiten installieren
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    git \
    curl \
    libssl-dev \
    libxml2-dev \
    libpq-dev \
    libuv1-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libudunits2-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# App kopieren
# App unter Shiny-Benutzer kopieren
COPY shiny /srv/shiny-server
COPY renv.lock /srv/shiny-server/renv.lock
COPY renv/activate.R /srv/shiny-server/renv/activate.R
RUN chown -R shiny:shiny /srv/shiny-server

RUN mkdir -p /var/log/shiny-server /var/lib/shiny-server/bookmarks \
    && chown -R shiny:shiny /var/log/shiny-server /var/lib/shiny-server

# Arbeitsverzeichnis setzen
WORKDIR /srv/shiny-server

# R-Paket 'renv' installieren
RUN R -e "install.packages('renv', repos='https://cloud.r-project.org')"

# Pakete installieren
RUN R -e "renv::restore(prompt = FALSE)"

EXPOSE 3838

# Shiny Server starten
CMD ["/usr/bin/shiny-server"]
