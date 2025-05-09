/* Top‑3 users with the most HISTORICAL nodes
   (amenity = hospital / clinic / doctors)
   that are no longer present in the current PLANET_NODES
   within the specified rectangle.
*/
WITH hist_nodes AS (          -- all historical nodes of interest
    SELECT DISTINCT
           hn."id",
           hn."username"
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."HISTORY_NODES" hn,
         LATERAL FLATTEN(INPUT => hn."all_tags") tag
    WHERE ARRAY_SIZE(hn."all_tags") > 0
      AND tag.value:"key"::STRING   = 'amenity'
      AND tag.value:"value"::STRING ILIKE ANY ('%hospital%', '%clinic%', '%doctors%')
      AND hn."latitude"  BETWEEN 31.1798246 AND 54.3798246      -- Y (lat)
      AND hn."longitude" BETWEEN 18.4519921 AND 33.6519921      -- X (lon)
),
curr_nodes AS (               -- current nodes of the same amenity in the rectangle
    SELECT DISTINCT
           pn."id"
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_NODES" pn,
         LATERAL FLATTEN(INPUT => pn."all_tags") tag
    WHERE ARRAY_SIZE(pn."all_tags") > 0
      AND tag.value:"key"::STRING   = 'amenity'
      AND tag.value:"value"::STRING ILIKE ANY ('%hospital%', '%clinic%', '%doctors%')
      AND pn."latitude"  BETWEEN 31.1798246 AND 54.3798246
      AND pn."longitude" BETWEEN 18.4519921 AND 33.6519921
),
gone AS (                     -- historical nodes that disappeared
    SELECT h."username"
    FROM   hist_nodes h
    WHERE  h."id" NOT IN (SELECT "id" FROM curr_nodes)
)
SELECT
       "username",
       COUNT(*) AS disappeared_nodes
FROM   gone
GROUP BY "username"
ORDER BY disappeared_nodes DESC NULLS LAST,
         "username"
LIMIT 3;