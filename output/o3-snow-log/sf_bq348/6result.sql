WITH "filtered_hist_nodes" AS (
    SELECT DISTINCT
           hn."id",
           hn."username"
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."HISTORY_NODES"  hn,
         LATERAL FLATTEN( INPUT => hn."all_tags") tag
    WHERE hn."version" = 1                                               -- original creation
      AND tag.value:"key"::string   = 'amenity'
      AND tag.value:"value"::string IN ('hospital','clinic','doctors')   -- required amenities
      AND hn."latitude" ::FLOAT BETWEEN 31.1798246 AND 54.3798246        -- latitude bounds
      AND hn."longitude"::FLOAT BETWEEN 18.4519921 AND 33.6519921        -- longitude bounds
      AND NOT EXISTS (                                                   -- no longer in current data
              SELECT 1
              FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_NODES" pn
              WHERE pn."id" = hn."id"
          )
)

SELECT
       "username",
       COUNT(*) AS "historical_nodes_missing"
FROM   "filtered_hist_nodes"
GROUP  BY "username"
ORDER  BY "historical_nodes_missing" DESC NULLS LAST
LIMIT 3;