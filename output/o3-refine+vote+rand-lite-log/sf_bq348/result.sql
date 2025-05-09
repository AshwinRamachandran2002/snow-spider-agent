/*  Top‑3 users who created (hospital / clinic / doctors) nodes
    inside the required lat‑lon rectangle, but whose nodes
    have disappeared from the current PLANET_NODES table            */
WITH hist_nodes AS (
    SELECT DISTINCT
           hn."id",
           hn."username"
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."HISTORY_NODES" hn
         ,LATERAL FLATTEN(INPUT => hn."all_tags") tag          -- explode tag array
    WHERE tag.value:"key"::string       = 'amenity'
      AND tag.value:"value"::string     IN ('hospital','clinic','doctors')
      -- bounding‑box  (lat, lon)  :  31.1798246 ≤ lat ≤ 54.3798246
      --                               18.4519921 ≤ lon ≤ 33.6519921
      AND hn."latitude" ::DOUBLE BETWEEN 31.1798246 AND 54.3798246
      AND hn."longitude"::DOUBLE BETWEEN 18.4519921 AND 33.6519921
),
missing_now AS (                      -- keep only nodes no longer present today
    SELECT h."id", h."username"
    FROM   hist_nodes h
    LEFT JOIN GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_NODES" pn
           ON h."id" = pn."id"
    WHERE  pn."id" IS NULL
)
SELECT   "username",
         COUNT(DISTINCT "id") AS "historical_node_count"
FROM     missing_now
GROUP BY "username"
ORDER BY "historical_node_count" DESC NULLS LAST,
         "username"
LIMIT 3;