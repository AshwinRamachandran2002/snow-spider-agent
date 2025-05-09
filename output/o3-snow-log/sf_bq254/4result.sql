WITH estonia AS (               -- ① the Wikidata-tagged multipolygon  (Q191 = Estonia)
    SELECT TO_GEOGRAPHY(p."geometry") AS geom
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES  p,
           LATERAL FLATTEN(input => p."all_tags") t
    WHERE  p."feature_type" = 'multipolygons'
      AND  t.value:"key"    = 'wikidata'
      AND  t.value:"value"  = 'Q191'
    LIMIT 1
),
bbox AS (                        -- ② its bounding-box (envelope)
    SELECT ST_ENVELOPE(geom) AS bbox FROM estonia
),
candidates AS (                  -- ③ multipolygons inside the bbox *without* a wikidata tag
    SELECT
        mp."osm_id",
        mp."osm_way_id",
        mp."geometry",
        MAX( CASE WHEN tg.value:"key" = 'name'
                  THEN tg.value:"value"::STRING END ) AS name          -- human-readable name
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES  mp,
           bbox,
           LATERAL FLATTEN(input => mp."all_tags") tg
    WHERE  mp."feature_type" = 'multipolygons'
      AND  ST_WITHIN( TO_GEOGRAPHY(mp."geometry"), bbox.bbox )
    GROUP BY mp."osm_id", mp."osm_way_id", mp."geometry"
    HAVING SUM( CASE WHEN tg.value:"key" = 'wikidata' THEN 1 ELSE 0 END ) = 0
),
point_counts AS (                -- ④ count how many point-features fall inside each candidate
    SELECT
        c."osm_id",
        c."osm_way_id",
        COALESCE(c.name, '<no name>')     AS name,
        COUNT(*)                         AS point_cnt
    FROM   candidates                                 c
    JOIN   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS  pt
           ON  ST_CONTAINS( TO_GEOGRAPHY(c."geometry"),
                            TO_GEOGRAPHY(pt."geometry") )
    GROUP BY c."osm_id", c."osm_way_id", c.name
)
-- ⑤ return the two highest-ranked multipolygons (by contained-point count) and their names
SELECT  name,
        point_cnt
FROM    point_counts
ORDER BY point_cnt DESC NULLS LAST
LIMIT 2;