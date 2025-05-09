WITH bbox AS (   -- geographic limits from the 4 given geo-points (lat , lon)
    SELECT 18.4519921 AS min_lon ,
           33.6519921 AS max_lon ,
           31.1798246 AS min_lat ,
           54.3798246 AS max_lat
),
hist AS (        -- disappeared historical amenity nodes inside bbox
    SELECT h."username"
    FROM  GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."HISTORY_NODES"  h
          JOIN bbox b
                ON  h."longitude" BETWEEN b.min_lon AND b.max_lon
                AND h."latitude"  BETWEEN b.min_lat  AND b.max_lat
          CROSS JOIN LATERAL FLATTEN(input => h."all_tags") t
          LEFT  JOIN GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_NODES" p
                 ON p."id" = h."id"
    WHERE t.value:"key"::STRING = 'amenity'
      AND LOWER(t.value:"value"::STRING) IN ('hospital','clinic','doctors')
      AND p."id" IS NULL          -- node no longer exists in current planet_nodes
)
SELECT  "username",
        COUNT(*) AS "disappeared_nodes"
FROM    hist
GROUP BY "username"
ORDER BY "disappeared_nodes" DESC NULLS LAST
LIMIT 3;