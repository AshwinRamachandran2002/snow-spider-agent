WITH q191_poly AS (   -- geometry of the multipolygon carrying wikidata = 'Q191'
    SELECT
        ST_GEOGFROMWKB("geometry") AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf ,
         LATERAL FLATTEN (INPUT => pf."all_tags") tag
    WHERE pf."feature_type" = 'multipolygons'
      AND tag.value:"key"::string   = 'wikidata'
      AND tag.value:"value"::string = 'Q191'
    LIMIT 1
),
candidate_polys AS (  -- all neighbouring multipolygons *without* their own wikidata tag
    SELECT
        pf."osm_way_id"                                          AS osm_way_id,
        ST_GEOGFROMWKB(pf."geometry")                            AS geom,
        MAX( CASE WHEN tag.value:"key"::string = 'name'
                  THEN tag.value:"value"::string END )           AS name
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf
    CROSS JOIN q191_poly q                                       -- for spatial filter
         , LATERAL FLATTEN (INPUT => pf."all_tags") tag
    WHERE pf."feature_type" = 'multipolygons'
      AND ST_INTERSECTS( ST_GEOGFROMWKB(pf."geometry"), q.geom )
    GROUP BY pf."osm_way_id", pf."geometry"
    HAVING MAX( CASE WHEN tag.value:"key"::string = 'wikidata' THEN 1 END ) IS NULL
),
point_feats AS (      -- all points that may fall inside the polygons
    SELECT ST_GEOGFROMWKB("geometry") AS geom
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS
    WHERE  "geometry" IS NOT NULL
)

SELECT
       c.name,
       c.osm_way_id,
       COUNT(p.geom)                               AS points_inside
FROM   candidate_polys  c
LEFT  JOIN point_feats  p
       ON ST_CONTAINS(c.geom , p.geom)
GROUP BY c.name, c.osm_way_id
ORDER  BY points_inside DESC NULLS LAST,
          c.osm_way_id
LIMIT 2;