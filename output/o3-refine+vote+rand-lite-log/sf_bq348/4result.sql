WITH historical_amenity_nodes AS (
    SELECT 
        hn."username" AS username,
        hn."id"
    FROM "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."HISTORY_NODES" hn
         LEFT JOIN "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_NODES" pn
                ON pn."id" = hn."id"          -- keep only nodes that disappeared
         , LATERAL FLATTEN(input => hn."all_tags") tag
    WHERE pn."id" IS NULL
      AND tag.value:"key"::string = 'amenity'
      AND LOWER(tag.value:"value"::string) IN ('hospital','clinic','doctors')
      -- correct bounding box: latitude first, longitude second
      AND hn."latitude"  BETWEEN 31.1798246 AND 54.3798246
      AND hn."longitude" BETWEEN 18.4519921 AND 33.6519921
)
SELECT 
    username,
    COUNT(*) AS missing_historical_nodes
FROM historical_amenity_nodes
GROUP BY username
ORDER BY missing_historical_nodes DESC NULLS LAST, username
LIMIT 3;