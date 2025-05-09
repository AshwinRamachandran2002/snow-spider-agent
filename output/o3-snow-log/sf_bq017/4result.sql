-- Five longest highway=* categories inside the Denmark (wikidata = 'Q35') multipolygon
WITH denmark AS (   -- Denmark administrative boundary
    SELECT 
        ST_UNION_AGG(TO_GEOGRAPHY(r."geometry"))        AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_RELATIONS r,
         LATERAL FLATTEN(input => r."all_tags") f
    WHERE f.value:"key"::STRING   = 'wikidata'
      AND f.value:"value"::STRING = 'Q35'
),
highway_lines AS (  -- every OSM line feature that carries a highway=* tag
    SELECT
        pf."geometry"                                 AS geom_wkb,
        tag.value:"value"::STRING                     AS highway_type
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf,
         LATERAL FLATTEN(input => pf."all_tags") tag
    WHERE pf."feature_type"        = 'lines'
      AND tag.value:"key"::STRING  = 'highway'
)
SELECT
    hl.highway_type                                                     AS "highway",
    ROUND( SUM( COALESCE(
              ST_LENGTH(                          -- metres on geography
                  ST_INTERSECTION(
                      TO_GEOGRAPHY(hl.geom_wkb), 
                      d.geom
                  )
              ), 0) ), 2)                                                AS "total_length_m"
FROM highway_lines hl
JOIN denmark d
  ON ST_INTERSECTS( TO_GEOGRAPHY(hl.geom_wkb), d.geom )
GROUP BY hl.highway_type
ORDER BY "total_length_m" DESC NULLS LAST
LIMIT 5;