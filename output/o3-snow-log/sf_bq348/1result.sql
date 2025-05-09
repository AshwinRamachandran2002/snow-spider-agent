WITH historical_nodes AS (
    SELECT
        hn."id",
        hn."username"
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."HISTORY_NODES" hn
    LEFT JOIN GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_NODES" pn
           ON pn."id" = hn."id"
    , LATERAL FLATTEN(INPUT => hn."all_tags") f            -- expand tags
    WHERE
          hn."version" = 1                                 -- original creation
      AND pn."id" IS NULL                                  -- no longer present
      AND hn."latitude"  BETWEEN 31.1798246 AND 54.3798246
      AND hn."longitude" BETWEEN 18.4519921 AND 33.6519921
      AND LOWER(f.value:"key"::string)   = 'amenity'
      AND LOWER(f.value:"value"::string) IN ('hospital','clinic','doctors')
)
SELECT
    "username",
    COUNT(DISTINCT "id") AS "node_count"
FROM historical_nodes
GROUP BY "username"
ORDER BY "node_count" DESC NULLS LAST
LIMIT 3;