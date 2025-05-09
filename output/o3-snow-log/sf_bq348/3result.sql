WITH amenity_hist_nodes AS (
    -- pick original (version = 1) historical nodes having amenity = hospital / clinic / doctors
    SELECT DISTINCT 
           hn."id",
           hn."username"
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."HISTORY_NODES"  hn,
         LATERAL FLATTEN(INPUT => hn."all_tags") f
    WHERE hn."version" = 1
      -- geographical bounding box
      AND hn."latitude"  BETWEEN 31.1798246 AND 54.3798246
      AND hn."longitude" BETWEEN 18.4519921 AND 33.6519921
      -- amenity filter
      AND f.value:"key"::STRING = 'amenity'
      AND LOWER(f.value:"value"::STRING) IN ('hospital','clinic','doctors')
      -- node no longer exists in the current planet_nodes table
      AND hn."id" NOT IN (
            SELECT pn."id"
            FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_NODES" pn
      )
)

SELECT  "username",
        COUNT(*) AS "missing_historical_nodes"
FROM    amenity_hist_nodes
GROUP BY "username"
ORDER BY "missing_historical_nodes" DESC NULLS LAST
LIMIT 3;