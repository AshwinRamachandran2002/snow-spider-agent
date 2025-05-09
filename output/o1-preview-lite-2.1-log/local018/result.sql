WITH
  c2021 AS (
    SELECT "pcf_violation_category", COUNT(*) AS "count"
    FROM "collisions"
    WHERE SUBSTR("collision_date", 1, 4) = '2021' AND "pcf_violation_category" IS NOT NULL
    GROUP BY "pcf_violation_category"
    ORDER BY "count" DESC
    LIMIT 1
  ),
  t2021 AS (
    SELECT COUNT(*) AS "total_incidents"
    FROM "collisions"
    WHERE SUBSTR("collision_date", 1, 4) = '2021'
  ),
  p2021 AS (
    SELECT
      (c2021."count" * 100.0) / t2021."total_incidents" AS "percentage",
      c2021."pcf_violation_category"
    FROM c2021, t2021
  ),
  c2011 AS (
    SELECT COUNT(*) AS "count"
    FROM "collisions"
    WHERE SUBSTR("collision_date", 1, 4) = '2011' AND "pcf_violation_category" = (SELECT "pcf_violation_category" FROM p2021)
  ),
  t2011 AS (
    SELECT COUNT(*) AS "total_incidents"
    FROM "collisions"
    WHERE SUBSTR("collision_date", 1, 4) = '2011'
  ),
  p2011 AS (
    SELECT
      (c2011."count" * 100.0) / t2011."total_incidents" AS "percentage"
    FROM c2011, t2011
  )
SELECT
  ROUND(((p2011."percentage" - p2021."percentage") / p2011."percentage") * 100, 4) AS "Percentage_decrease"
FROM p2011, p2021;