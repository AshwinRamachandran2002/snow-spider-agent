WITH dk AS (
    SELECT DISTINCT
           TO_GEOGRAPHY("geometry") AS "dk_geom"
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES"  pf,
           LATERAL FLATTEN(input => pf."all_tags") f
    WHERE  f.value:"key"::STRING  = 'wikidata'
      AND  f.value:"value"::STRING = 'Q35'
)
SELECT MAX("stop_count") AS "max_dk_bus_stop_count"
FROM (
    SELECT  f_net.value:"value"::STRING AS "bus_network",
            COUNT(DISTINCT p."osm_id")  AS "stop_count"
    FROM    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES_POINTS" p,
            LATERAL FLATTEN(input => p."all_tags") f_hi,
            LATERAL FLATTEN(input => p."all_tags") f_net,
            dk
    WHERE   f_hi.value:"key"::STRING  = 'highway'
      AND   f_hi.value:"value"::STRING = 'bus_stop'
      AND   f_net.value:"key"::STRING  = 'network'
      AND   ST_CONTAINS(dk."dk_geom", TO_GEOGRAPHY(p."geometry"))
    GROUP BY f_net.value:"value"::STRING
) sub;