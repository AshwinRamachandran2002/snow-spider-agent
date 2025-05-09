WITH denmark AS (   -- multipolygon of Denmark (wikidata Q35)
    SELECT TO_GEOGRAPHY("geometry") AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES",
         LATERAL FLATTEN(INPUT => "all_tags") tag
    WHERE tag.value:key::string = 'wikidata'
      AND tag.value:value::string = 'Q35'
    LIMIT 1
),
point_tags AS (     -- pull relevant tags from every point
    SELECT
        p."geometry"                                            AS geom_bin,
        MAX(CASE WHEN t.value:key::string = 'highway'
                 THEN t.value:value::string END)                AS highway,
        MAX(CASE WHEN t.value:key::string = 'network'
                 THEN t.value:value::string END)                AS network
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES_POINTS"  p,
         LATERAL FLATTEN(INPUT => p."all_tags") t
    GROUP BY p."geometry"
),
bus_points AS (      -- keep only bus stops with a non‑empty network
    SELECT
        TO_GEOGRAPHY(geom_bin) AS geom,
        network
    FROM point_tags
    WHERE highway = 'bus_stop'
      AND network IS NOT NULL
      AND network <> ''
),
bus_in_denmark AS (  -- bus stops located within Denmark
    SELECT
        bp.network,
        COUNT(*) AS stops_cnt
    FROM bus_points bp
    JOIN denmark d
      ON ST_CONTAINS(d.geom, bp.geom)
    GROUP BY bp.network
)
SELECT stops_cnt
FROM bus_in_denmark
ORDER BY stops_cnt DESC NULLS LAST, network
LIMIT 1;