WITH denmark AS (
    SELECT den."geometry" AS "denmark_geom"
    FROM "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_FEATURES" den,
         LATERAL FLATTEN(input => den."all_tags") den_tags
    WHERE den_tags.value:"key"::STRING = 'wikidata'
      AND den_tags.value:"value"::STRING = 'Q35'
    LIMIT 1
),
bus_stops_in_denmark AS (
    SELECT pf."osm_id", network_f.value:"value"::STRING AS "bus_network"
    FROM "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_FEATURES_POINTS" pf,
         LATERAL FLATTEN(input => pf."all_tags") highway_f,
         LATERAL FLATTEN(input => pf."all_tags") network_f,
         denmark
    WHERE highway_f.value:"key"::STRING = 'highway'
      AND highway_f.value:"value"::STRING = 'bus_stop'
      AND network_f.value:"key"::STRING = 'network'
      AND ST_WITHIN(TO_GEOGRAPHY(pf."geometry"), TO_GEOGRAPHY(denmark."denmark_geom"))
)
SELECT COUNT(*) AS "Number_of_bus_stops"
FROM bus_stops_in_denmark
GROUP BY "bus_network"
ORDER BY COUNT(*) DESC NULLS LAST
LIMIT 1;