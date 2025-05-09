/* Top-2 multipolygons inside Estonia (Q191 bbox) without their own
   wikidata tag, ranked by the number of points that fall inside them */
WITH est_bbox AS (                  -- Estonia’s bounding box
    SELECT ST_ENVELOPE(ST_GEOGFROMWKB(p."geometry")) AS bbox
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES p,
           LATERAL FLATTEN(input => p."all_tags") tag
    WHERE  p."feature_type" = 'multipolygons'
      AND  tag.value:"key"::STRING   = 'wikidata'
      AND  tag.value:"value"::STRING = 'Q191'
    LIMIT 1
), candidates AS (                  -- MPs within bbox, lacking wikidata
    SELECT  mp."osm_way_id",
            ST_GEOGFROMWKB(mp."geometry")                          AS geog,
            MAX(CASE WHEN tag.value:"key"::STRING = 'name'
                     THEN tag.value:"value"::STRING END)           AS name
    FROM    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES mp
    CROSS   JOIN est_bbox
          , LATERAL FLATTEN(input => mp."all_tags", OUTER => TRUE) tag
    WHERE   mp."feature_type" = 'multipolygons'
      AND   ST_INTERSECTS(ST_GEOGFROMWKB(mp."geometry"), est_bbox.bbox)
    GROUP  BY mp."osm_way_id", mp."geometry"
    HAVING  COUNT_IF(tag.value:"key"::STRING = 'wikidata') = 0
), ranked AS (                     -- count interior points
    SELECT  c."osm_way_id",
            c.name,
            COUNT(*) AS pts
    FROM    candidates c
    JOIN    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS p
          ON ST_CONTAINS(c.geog, ST_GEOGFROMWKB(p."geometry"))
    GROUP  BY c."osm_way_id", c.name
)
SELECT  "osm_way_id",
        name,
        pts
FROM    ranked
ORDER BY pts DESC NULLS LAST
LIMIT 2;