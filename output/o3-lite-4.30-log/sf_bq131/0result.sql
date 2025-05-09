WITH denmark AS (  /* Denmark multipolygon (Wikidata = Q35) */
    SELECT TO_GEOGRAPHY(r."geometry") AS "geo"
    FROM "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_RELATIONS" r,
         LATERAL FLATTEN(input => r."all_tags") f
    WHERE f.value:"key" = 'wikidata'
      AND f.value:"value" = 'Q35'
    LIMIT 1
),
bus_stops_in_denmark AS (  /* Bus‑stop / platform points inside Denmark having a network tag */
    SELECT 
        p."osm_id",
        MAX(CASE WHEN t.value:"key" = 'network' 
                 THEN t.value:"value" END) AS "network_name"
    FROM "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_FEATURES_POINTS" p,
         LATERAL FLATTEN(input => p."all_tags") s,   /* stop/platform filter   */
         LATERAL FLATTEN(input => p."all_tags") t,   /* read network tag value */
         denmark d
    WHERE p."geometry" IS NOT NULL
      AND ( (s.value:"key" = 'highway'          AND s.value:"value" = 'bus_stop')
         OR (s.value:"key" = 'public_transport' AND s.value:"value" = 'platform') )
      AND ST_CONTAINS(d."geo", TO_GEOGRAPHY(p."geometry"))
    GROUP BY p."osm_id"
    HAVING MAX(CASE WHEN t.value:"key" = 'network' THEN 1 ELSE 0 END) = 1
),
network_counts AS (  /* count stops per network */
    SELECT "network_name",
           COUNT(*) AS "cnt"
    FROM bus_stops_in_denmark
    GROUP BY "network_name"
    ORDER BY "cnt" DESC NULLS LAST
    LIMIT 1
)
SELECT "cnt" AS bus_stop_count
FROM network_counts;