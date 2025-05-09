WITH
Total2021 AS (
  SELECT COUNT(*) AS total_accidents_2021
  FROM "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."COLLISIONS"
  WHERE "collision_date" LIKE '%2021%'
),
Total2011 AS (
  SELECT COUNT(*) AS total_accidents_2011
  FROM "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."COLLISIONS"
  WHERE "collision_date" LIKE '%2011%'
),
MostCommonCause AS (
  SELECT "primary_collision_factor", COUNT(*) AS cause_accidents_2021
  FROM "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."COLLISIONS"
  WHERE "collision_date" LIKE '%2021%'
    AND "primary_collision_factor" IS NOT NULL
    AND "primary_collision_factor" <> ''
  GROUP BY "primary_collision_factor"
  ORDER BY cause_accidents_2021 DESC NULLS LAST
  LIMIT 1
),
Cause2011 AS (
  SELECT COUNT(*) AS cause_accidents_2011
  FROM "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."COLLISIONS"
  WHERE "collision_date" LIKE '%2011%'
    AND "primary_collision_factor" = (SELECT "primary_collision_factor" FROM MostCommonCause)
)
SELECT
  MostCommonCause."primary_collision_factor" AS "Cause",
  ROUND(
    ((Cause2011.cause_accidents_2011 * 100.0) / Total2011.total_accidents_2011)
    -
    ((MostCommonCause.cause_accidents_2021 * 100.0)/ Total2021.total_accidents_2021)
  , 4) AS "Percentage_Decrease"
FROM MostCommonCause, Cause2011, Total2021, Total2011;