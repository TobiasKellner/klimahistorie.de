CREATE TABLE public."Stationstabelle" (
    "STATIONS_ID" integer PRIMARY KEY,
    "Stationshoehe" integer,
    "geoBreite" double precision,
    "geoLaenge" double precision,
    "Stationsname" text,
    "Bundesland" text
);

GRANT SELECT ON TABLE public."Stationstabelle" TO climate_reader;
