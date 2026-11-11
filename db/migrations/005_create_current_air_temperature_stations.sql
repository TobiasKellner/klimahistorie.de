CREATE MATERIALIZED VIEW public."AktuelleTemperaturstationen" AS
SELECT DISTINCT ON ("STATIONS_ID")
    "STATIONS_ID", "Stationsname", "Bundesland", "Stationshoehe",
    "geoBreite", "geoLaenge", "von_datum", "bis_datum", "res", "var", "per"
FROM public."Stationstabelle"
WHERE "hasfile" IS TRUE
  AND (
      ("var" = 'air_temperature' AND "per" IN ('now', 'recent'))
      OR ("res" = 'daily' AND "var" = 'kl' AND "per" = 'recent')
  )
ORDER BY "STATIONS_ID", "bis_datum" DESC, "von_datum" DESC,
    "Stationsname", "res", "var", "per", "Abgabe";

CREATE UNIQUE INDEX aktuelle_temperaturstationen_station_id
    ON public."AktuelleTemperaturstationen" ("STATIONS_ID");

REVOKE ALL ON public."AktuelleTemperaturstationen" FROM climate_etl;
GRANT SELECT ON public."AktuelleTemperaturstationen" TO climate_reader, climate_etl;

-- Allow ETL to refresh this view without granting general owner privileges.
CREATE FUNCTION public.refresh_current_air_temperature_stations()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW public."AktuelleTemperaturstationen";
END;
$$;

REVOKE ALL ON FUNCTION public.refresh_current_air_temperature_stations() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.refresh_current_air_temperature_stations() TO climate_etl;
