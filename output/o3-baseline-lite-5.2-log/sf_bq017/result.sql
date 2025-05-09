WITH denmark_boundary AS (
    /* Denmark multipolygon from its Wikidata id = Q35 */
    SELECT
        TO_GEOGRAPHY("geometry") AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES,
         LATERAL FLATTEN(input => "all_tags") tag
    WHERE "feature_type" = 'multipolygons'
      AND tag.value:"key"  = 'wikidata'
      AND tag.value:"value" = 'Q35'
    LIMIT 1               -- exactly one boundary is sufficient
),

highway_lines AS (
    /* All line features that carry a highway tag */
    SELECT
        LOWER(htag.value:"value")::string AS highway_type,
        TO_GEOGRAPHY(pf."geometry")       AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf,
         LATERAL FLATTEN(input => pf."all_tags") htag
    WHERE pf."feature_type" = 'lines'
      AND htag.value:"key"   = 'highway'
      AND pf."geometry"      IS NOT NULL
)

SELECT
    highway_type,
    ROUND( SUM(
              ST_LENGTH(
                  ST_INTERSECTION(h.geom , d.geom)   -- part of the line inside Denmark
              )
          ), 2) AS total_length_m
FROM highway_lines h
JOIN denmark_boundary d
  ON ST_INTERSECTS(h.geom , d.geom)                 -- keep only lines touching Denmark
GROUP BY highway_type
ORDER BY total_length_m DESC NULLS LAST, highway_type
LIMIT 5;     -- five longest highway types