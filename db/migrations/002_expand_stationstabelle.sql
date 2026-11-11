-- Existing six-column rows cannot be assigned reliable product/period metadata.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM public."Stationstabelle") THEN
        RAISE EXCEPTION 'Stationstabelle ist bereits befüllt. Vor Migration 002 ist eine geplante Übernahme der vorhandenen Daten erforderlich.';
    END IF;
END
$$;

ALTER TABLE public."Stationstabelle"
    DROP CONSTRAINT "Stationstabelle_pkey",
    ADD COLUMN "von_datum" date NOT NULL,
    ADD COLUMN "bis_datum" date NOT NULL,
    ADD COLUMN "Abgabe" text NOT NULL,
    ADD COLUMN "res" text NOT NULL,
    ADD COLUMN "var" text NOT NULL,
    ADD COLUMN "per" text NOT NULL,
    ADD COLUMN "hasfile" boolean,
    ADD CONSTRAINT "Stationstabelle_pkey" PRIMARY KEY (
        "STATIONS_ID", "res", "var", "per", "von_datum", "bis_datum", "Abgabe"
    );
