WITH parsed_nodes AS (
    SELECT 
        hn."id",
        hn."username"
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."HISTORY_NODES" hn,
         LATERAL FLATTEN( input => TRY_PARSE_JSON(hn."all_tags") ) tag
    WHERE 
          CAST(hn."latitude"  AS DOUBLE) BETWEEN 31.1798246 AND 54.3798246   -- latitude range
      AND CAST(hn."longitude" AS DOUBLE) BETWEEN 18.4519921 AND 33.6519921   -- longitude range
      AND tag.value:"key"::STRING   = 'amenity'
      AND tag.value:"value"::STRING IN ('hospital','clinic','doctors')
),
unique_hist AS (                     -- keep one record per node-id
    SELECT DISTINCT
           "id",
           "username"
    FROM parsed_nodes
),
missing AS (                         -- drop nodes still present today
    SELECT 
        uh."username"
    FROM unique_hist uh
    LEFT JOIN GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_NODES" pn
           ON pn."id" = uh."id"
    WHERE pn."id" IS NULL
)
SELECT 
    "username",
    COUNT(*) AS "missing_historical_node_count"
FROM missing
GROUP BY "username"
ORDER BY "missing_historical_node_count" DESC NULLS LAST
LIMIT 3;