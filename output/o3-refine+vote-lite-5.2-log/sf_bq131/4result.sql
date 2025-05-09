WITH denmark AS (   -- polygon for Denmark (wikidata = Q35)
    SELECT
        TO_GEOGRAPHY("geometry") AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES p ,
         LATERAL FLATTEN (INPUT => p."all_tags") f
    WHERE f.value:"key"  = 'wikidata'
      AND f.value:"value" = 'Q35'
      AND p."geometry" IS NOT NULL
      AND p."feature_type" = 'multipolygons'
    LIMIT 1
),
bus_stop_points AS (   -- all bus‑stop points together with their network tag
    SELECT
        TO_GEOGRAPHY(p."geometry")                                                AS geom ,
        MAX(CASE WHEN f.value:"key" = 'network' THEN f.value:"value" END)         AS network
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS p ,
         LATERAL FLATTEN (INPUT => p."all_tags") f
    WHERE p."geometry" IS NOT NULL
    GROUP BY p."geometry"
    HAVING MAX(CASE WHEN f.value:"key" = 'highway' THEN f.value:"value" END) = 'bus_stop'
),
bus_stops_in_denmark AS (
    SELECT
        b.network
    FROM bus_stop_points b ,
         denmark d
    WHERE b.network IS NOT NULL
      AND ST_CONTAINS(d.geom , b.geom)
)
SELECT  MAX(cnt) AS "NUMBER_OF_STOPS_FOR_TOP_NETWORK"
FROM (
      SELECT network , COUNT(*) AS cnt
      FROM   bus_stops_in_denmark
      GROUP  BY network
);