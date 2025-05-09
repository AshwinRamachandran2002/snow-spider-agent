-- Five highway classes with the greatest total geodesic length inside Denmark
WITH denmark AS (
    /* Retrieve Denmark’s multipolygon boundary (wikidata = 'Q35') */
    SELECT TO_GEOGRAPHY(r."geometry") AS geom
    FROM   "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_RELATIONS" r,
           LATERAL FLATTEN(INPUT => r."all_tags") f
    WHERE  f.value:"key"::STRING  = 'wikidata'
      AND  f.value:"value"::STRING = 'Q35'
    LIMIT 1
)
SELECT
       tag_f.value:"value"::STRING                           AS "highway_type",
       SUM( ST_LENGTH( TO_GEOGRAPHY(pf."geometry") ) )       AS "total_length_m"
FROM   "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_FEATURES" pf
       ,LATERAL FLATTEN(INPUT => pf."all_tags")               tag_f
       ,denmark                                               dk
WHERE  pf."feature_type"            = 'lines'          -- only linear features
  AND  tag_f.value:"key"::STRING    = 'highway'        -- highway-classified lines
  AND  pf."geometry"                IS NOT NULL
  AND  ST_INTERSECTS(dk.geom, TO_GEOGRAPHY(pf."geometry"))   -- inside Denmark
GROUP BY
       tag_f.value:"value"::STRING
ORDER BY
       "total_length_m" DESC NULLS LAST
LIMIT 5;