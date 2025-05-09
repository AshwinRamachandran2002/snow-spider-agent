WITH yearly_causes AS (
  SELECT
    strftime('%Y', "collision_date") AS "year",
    "primary_collision_factor",
    COUNT(*) AS "count"
  FROM "collisions"
  WHERE "primary_collision_factor" IS NOT NULL AND "primary_collision_factor" != ''
  GROUP BY "year", "primary_collision_factor"
),
ranked_causes AS (
  SELECT
    "year",
    "primary_collision_factor",
    "count",
    ROW_NUMBER() OVER (PARTITION BY "year" ORDER BY "count" DESC) AS "rank"
  FROM yearly_causes
),
top_two_causes_per_year AS (
  SELECT
    "year",
    -- Ensure consistent ordering by sorting the causes alphabetically
    CASE
      WHEN MIN("primary_collision_factor") < MAX("primary_collision_factor")
      THEN MIN("primary_collision_factor") || ',' || MAX("primary_collision_factor")
      ELSE MAX("primary_collision_factor") || ',' || MIN("primary_collision_factor")
    END AS "top_two_causes"
  FROM ranked_causes
  WHERE "rank" <= 2
  GROUP BY "year"
),
most_common_top_causes AS (
  SELECT "top_two_causes"
  FROM top_two_causes_per_year
  GROUP BY "top_two_causes"
  ORDER BY COUNT(*) DESC
  LIMIT 1
),
years_with_different_top_causes AS (
  SELECT "year"
  FROM top_two_causes_per_year
  WHERE "top_two_causes" NOT IN (SELECT "top_two_causes" FROM most_common_top_causes)
)
SELECT CAST("year" AS INTEGER) AS "Year" FROM years_with_different_top_causes;