SELECT "year"::int AS "Year"
FROM (
  SELECT
    "year",
    COUNT(*) OVER (PARTITION BY "top_causes") AS "cause_count"
  FROM (
    SELECT
      "year",
      LISTAGG("primary_collision_factor", '|') WITHIN GROUP (ORDER BY "rank") AS "top_causes"
    FROM (
      SELECT
        SUBSTR("collision_date", 1, 4) AS "year",
        "primary_collision_factor",
        COUNT(*) AS "count",
        RANK() OVER (PARTITION BY SUBSTR("collision_date", 1, 4) ORDER BY COUNT(*) DESC NULLS LAST) AS "rank"
      FROM "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."COLLISIONS"
      WHERE "primary_collision_factor" IS NOT NULL
      GROUP BY SUBSTR("collision_date", 1, 4), "primary_collision_factor"
    ) AS ranked_factors
    WHERE "rank" <= 2
    GROUP BY "year"
  ) AS top_causes_per_year
) AS causes_with_counts
WHERE "cause_count" = 1;