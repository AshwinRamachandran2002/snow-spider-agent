WITH wyoming_counts AS (
    SELECT
        "name",
        SUM("number") AS wy_count
    FROM USA_NAMES.USA_NAMES.USA_1910_CURRENT
    WHERE "gender" = 'F'
      AND "year" = 2021
      AND "state" = 'WY'
    GROUP BY "name"
),
totals AS (
    SELECT
        "name",
        SUM("number") AS total_count
    FROM USA_NAMES.USA_NAMES.USA_1910_CURRENT
    WHERE "gender" = 'F'
      AND "year" = 2021
    GROUP BY "name"
)
SELECT
    w."name" AS "most_popular_name"
FROM wyoming_counts w
JOIN totals t
  ON w."name" = t."name"
ORDER BY
    (w.wy_count / t.total_count) DESC NULLS LAST
LIMIT 1;