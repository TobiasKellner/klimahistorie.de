# Basis-Image mit R und Shiny-Server
FROM rocker/shiny:latest

# Systemabhängigkeiten für R-Pakete installieren
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libpq-dev

# create shiny directory inlcuding renv
RUN mkdir -p /home/user1/shiny/renv

# copy shiny app into container
COPY shiny /home/user1/shiny

# copy renv project files into container
COPY renv.lock /home/user1/shiny/renv.lock
COPY renv/activate.R /home/user1/shiny/renv/activate.R

# create user user1 (uid/gid same as on host)
#RUN groupadd -g 1090 user1 && \
#    useradd -u 1090 -g 1090 user1 && \
#    chown -R user1:user1 /home/user1

RUN useradd -m user1
RUN chown -R user1:user1 /home/user1

RUN mkdir -p /usr/local/lib/R/site-library && \
    chown -R user1:user1 /usr/local/lib/R/site-library && \
    chmod -R 777 /usr/local/lib/R/site-library


# switch to user user1 and set working directory
USER user1
WORKDIR /home/user1/shiny

# define libPaths to be within user directory
#RUN mkdir -p /home/user1/R/x86_64-pc-linux-gnu-library/4.3
#RUN echo ".libPaths('/home/user1/R/x86_64-pc-linux-gnu-library/4.3')" \
#      >> /home/user1/shiny/.Rprofile

# install R packages
#ENV RENV_VERSION 1.0.11
#RUN R -e "install.packages(\
#      'remotes', repos = c(CRAN = 'https://cloud.r-project.org')\
#      )"
#RUN R -e "remotes::install_github('rstudio/renv')"


# Installiere Abhängigkeiten (falls nötig)
RUN R -e "install.packages(c('shiny', 'remotes', 'renv', 'config', 'ggplot2', 'dplyr', 'dbplyr', 'shinyjs', 'shinycssloaders', 'bs4Dash', 'htmltools', 'lubridate', 'purrr', 'stringr', 'plotly', 'leaflet', 'DBI', 'RPostgres'))"


# set working directory to shiny app root directory
WORKDIR /home/user1/shiny

# Starte den Shiny-Server mit dem neuen App-Pfad
CMD ["R", "-e", "shiny::runApp(host='0.0.0.0', port=3838, launch.browser = FALSE)"]
