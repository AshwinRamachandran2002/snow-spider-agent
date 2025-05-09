WITH q191 AS (  -- 1. multipolygon that carries wikidata = 'Q191'
    SELECT TO_GEOGRAPHY(pf."geometry") AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf ,
         LATERAL FLATTEN(input => pf."all_tags") tag
    WHERE pf."feature_type" = 'multipolygons'
      AND tag.value:"key"::STRING  = 'wikidata'
      AND tag.value:"value"::STRING = 'Q191'
    LIMIT 1
),

candidate_base AS (  -- 2. every multipolygon + flag whether it has a wikidata tag
    SELECT
        pf."osm_id",
        pf."geometry",
        pf."all_tags",
        MAX(CASE WHEN t.value:"key"::STRING = 'wikidata' THEN 1 ELSE 0 END) AS has_wikidata
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf ,
         LATERAL FLATTEN(input => pf."all_tags", OUTER => TRUE) t
    WHERE pf."feature_type" = 'multipolygons'
    GROUP BY pf."osm_id", pf."geometry", pf."all_tags"
),

candidates AS (  -- 3. polygons inside the Q191 area and without wikidata tag
    SELECT cb."osm_id",
           cb."geometry",
           cb."all_tags"
    FROM candidate_base cb
    CROSS JOIN q191
    WHERE cb.has_wikidata = 0
      AND cb."geometry" IS NOT NULL
      AND ST_INTERSECTS(TO_GEOGRAPHY(cb."geometry"), q191.geom)
),

point_counts AS (  -- 4. count points inside each candidate polygon
    SELECT
        c."osm_id",
        COUNT(*) AS pts_inside
    FROM candidates c
    JOIN GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS p
      ON ST_CONTAINS(TO_GEOGRAPHY(c."geometry"), TO_GEOGRAPHY(p."geometry"))
    GROUP BY c."osm_id"
),

named AS (  -- 5. attach the name tag
    SELECT
        pc."osm_id",
        pc.pts_inside,
        MAX(CASE WHEN t.value:"key"::STRING = 'name'
                 THEN t.value:"value"::STRING END) AS name
    FROM point_counts pc
    JOIN GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf
      ON pf."osm_id" = pc."osm_id"
    ,  LATERAL FLATTEN(input => pf."all_tags", OUTER => TRUE) t
    GROUP BY pc."osm_id", pc.pts_inside
)

SELECT name
FROM   named
ORDER  BY pts_inside DESC NULLS LAST, name
LIMIT  2;