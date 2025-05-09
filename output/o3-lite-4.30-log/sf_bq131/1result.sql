WITH den AS (
    SELECT ST_GEOGFROMWKB(r."geometry") AS den_geom
    FROM "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_RELATIONS" r,
         LATERAL FLATTEN(input => r."all_tags") f
    WHERE f.value:"key"  = 'wikidata'
      AND f.value:"value" = 'Q35'
    LIMIT 1
),
network_counts AS (
    SELECT g_net.value:"value" AS network,
           COUNT(*)            AS stop_count
    FROM den,
         "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_FEATURES_POINTS" pt,
         LATERAL FLATTEN(input => pt."all_tags") g_hw,
         LATERAL FLATTEN(input => pt."all_tags") g_net
    WHERE g_hw.value:"key"   = 'highway'
      AND g_hw.value:"value" = 'bus_stop'
      AND g_net.value:"key"  = 'network'
      AND ST_CONTAINS(den.den_geom, ST_GEOGFROMWKB(pt."geometry"))
    GROUP BY g_net.value:"value"
)
SELECT MAX(stop_count) AS bus_stop_count
FROM network_counts;