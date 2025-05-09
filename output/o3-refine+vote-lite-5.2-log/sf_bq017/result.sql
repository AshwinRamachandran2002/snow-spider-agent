WITH denmark AS (   -- Denmark boundary (Wikidata = Q35)
    SELECT
        ST_UNION_AGG( ST_GEOGFROMWKB("geometry") ) AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_RELATIONS r
         , LATERAL FLATTEN( INPUT => r."all_tags") tag
    WHERE tag.value:"key"::string  = 'wikidata'
      AND tag.value:"value"::string = 'Q35'
      AND r."visible" = TRUE
),

highways AS (   -- linear highway features from PLANET_FEATURES
    SELECT
        tag.value:"value"::string      AS highway_type ,
        ST_GEOGFROMWKB( pf."geometry") AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf
         , LATERAL FLATTEN( INPUT => pf."all_tags") tag
    WHERE tag.value:"key"::string = 'highway'
      AND pf."geometry" IS NOT NULL
      AND pf."feature_type" ILIKE '%line%'       -- keep only linear geometries
)

SELECT
    highway_type,
    ROUND( SUM( ST_LENGTH( ST_INTERSECTION( hl.geom , d.geom ) ) ) , 2)  AS total_length_meters
FROM highways hl
CROSS JOIN denmark d
WHERE ST_INTERSECTS( d.geom , hl.geom )
GROUP BY highway_type
ORDER BY total_length_meters DESC NULLS LAST, highway_type
LIMIT 5;