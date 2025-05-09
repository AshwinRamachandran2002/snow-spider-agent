WITH denmark AS (   -- Denmark multipolygon (wikidata = Q35)
    SELECT
        ST_UNION_AGG( ST_GEOGFROMWKB("geometry") )            AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES p
    CROSS JOIN LATERAL FLATTEN( INPUT => PARSE_JSON(p."all_tags") ) tag
    WHERE tag.value:"key"  ::STRING = 'wikidata'
      AND tag.value:"value"::STRING = 'Q35'
),

highway_lines AS (   -- all OSM highways represented as lines
    SELECT
        tag.value:"value"::STRING                             AS highway_type,
        ST_GEOGFROMWKB(p."geometry")                          AS geog
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES p
    CROSS JOIN LATERAL FLATTEN( INPUT => PARSE_JSON(p."all_tags") ) tag
    WHERE p."feature_type" = 'lines'
      AND tag.value:"key"::STRING = 'highway'
      AND p."geometry" IS NOT NULL
)

SELECT
    highway_type,
    ROUND( SUM( ST_LENGTH( ST_INTERSECTION(hl.geog , d.geom) ) ) , 2 ) AS total_length_m
FROM highway_lines hl
CROSS JOIN denmark d
WHERE ST_INTERSECTS( hl.geog , d.geom )
GROUP BY highway_type
ORDER BY total_length_m DESC NULLS LAST, highway_type
LIMIT 5;