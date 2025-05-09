WITH denmark AS (
    SELECT TO_GEOGRAPHY(pf."geometry") AS geom
    FROM   "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_FEATURES" pf,
           LATERAL FLATTEN(input => pf."all_tags") tag
    WHERE  tag.value:"key" = 'wikidata'
      AND  tag.value:"value" = 'Q35'
    LIMIT 1
),
bus_stops AS (
    SELECT TO_GEOGRAPHY(p."geometry") AS geom,
           net.value:"value"::STRING  AS network
    FROM   "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_FEATURES_POINTS" p,
           LATERAL FLATTEN(input => p."all_tags") hw,
           LATERAL FLATTEN(input => p."all_tags") net
    WHERE  hw.value:"key" = 'highway'
      AND  hw.value:"value" = 'bus_stop'
      AND  net.value:"key" = 'network'
),
network_counts AS (
    SELECT bs.network,
           COUNT(*) AS cnt
    FROM   denmark d
    JOIN   bus_stops bs
      ON   ST_CONTAINS(d.geom, bs.geom)
    GROUP  BY bs.network
    ORDER  BY cnt DESC, bs.network
    LIMIT 1
)
SELECT cnt AS bus_stop_count
FROM   network_counts;