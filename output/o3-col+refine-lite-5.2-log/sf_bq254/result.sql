WITH q191_env AS (            -- 1. envelope of the Q191 multipolygon
    SELECT ST_Envelope(ST_GeogFromWKB(pf."geometry")) AS env
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES"  pf ,
           LATERAL FLATTEN(INPUT => pf."all_tags") tag
    WHERE  pf."feature_type" = 'multipolygons'
      AND  tag.value:"key"::STRING   = 'wikidata'
      AND  tag.value:"value"::STRING = 'Q191'
    LIMIT  1
),
candidates AS (                -- 2. multipolygons inside that envelope, but without a wikidata tag
    SELECT pf."osm_way_id",
           pf."geometry",
           MAX(CASE WHEN tag.value:"key"::STRING = 'name'
                    THEN tag.value:"value"::STRING END) AS name
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES"  pf
           JOIN q191_env q
             ON ST_Intersects(ST_GeogFromWKB(pf."geometry"), q.env)
           , LATERAL FLATTEN(INPUT => pf."all_tags") tag
    WHERE  pf."feature_type" = 'multipolygons'
    GROUP  BY pf."osm_way_id", pf."geometry"
    HAVING SUM(CASE WHEN tag.value:"key"::STRING = 'wikidata' THEN 1 ELSE 0 END) = 0
),
pts_in_poly AS (               -- 3. count points contained in each candidate multipolygon
    SELECT c."osm_way_id",
           c.name,
           COUNT(*) AS point_cnt
    FROM   candidates                                            c
           JOIN GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES_POINTS" p
             ON ST_Contains(ST_GeogFromWKB(c."geometry"),
                            ST_GeogFromWKB(p."geometry"))
    GROUP  BY c."osm_way_id", c.name
)
-- 4. return the two candidates with the highest point counts
SELECT "osm_way_id",
       COALESCE(name, '<no name>') AS "name",
       point_cnt
FROM   pts_in_poly
ORDER  BY point_cnt DESC NULLS LAST, "osm_way_id"
LIMIT  2;