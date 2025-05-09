WITH denmark AS (
    SELECT
        TO_GEOGRAPHY("geometry") AS geom
    FROM "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_FEATURES",
         LATERAL FLATTEN(INPUT => "all_tags") den_tag
    WHERE den_tag.value:"key"::STRING  = 'wikidata'
      AND den_tag.value:"value"::STRING = 'Q35'
      AND "feature_type" = 'multipolygons'
    LIMIT 1
)
SELECT
    hw_tag.value:"value"::STRING                                 AS "highway_type",
    ROUND(SUM(ST_LENGTH(TO_GEOGRAPHY(pf."geometry"))) / 1000, 4) AS "total_km"
FROM denmark d,
     "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_FEATURES" pf,
     LATERAL FLATTEN(INPUT => pf."all_tags") hw_tag
WHERE pf."feature_type" = 'lines'
  AND hw_tag.value:"key"::STRING = 'highway'
  AND ST_INTERSECTS(TO_GEOGRAPHY(pf."geometry"), d.geom)
GROUP BY "highway_type"
ORDER BY "total_km" DESC NULLS LAST, "highway_type"
LIMIT 5;