CREATE TABLE public."Tagesdaten" (
    "STATIONS_ID" integer NOT NULL,
    "MESS_DATUM" text NOT NULL CHECK ("MESS_DATUM" ~ '^[0-9]{8}$'),
    "QN_3" integer,
    "FX" double precision,
    "FM" double precision,
    "QN_4" integer,
    "RSK" double precision,
    "RSKF" integer,
    "SDK" double precision,
    "SHK_TAG" integer,
    "NM" double precision,
    "VPM" double precision,
    "PM" double precision,
    "TMK" double precision,
    "UPM" double precision,
    "TXK" double precision,
    "TNK" double precision,
    "TGK" double precision,
    "eor" text,
    PRIMARY KEY ("STATIONS_ID", "MESS_DATUM")
);

GRANT SELECT ON TABLE public."Tagesdaten" TO climate_reader;
GRANT SELECT, INSERT, UPDATE ON TABLE public."Tagesdaten" TO climate_etl;
