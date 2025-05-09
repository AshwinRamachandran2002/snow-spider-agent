WITH wy_counts AS (
    SELECT
        "name",
        SUM("number") AS wy_count
    FROM USA_NAMES.USA_NAMES.USA_1910_CURRENT
    WHERE "state" = 'WY'
      AND "year" = 2021
      AND "gender" = 'F'
    GROUP BY "name"
),
total_counts AS (
    SELECT
        "name",
        SUM("number") AS total_count
    FROM USA_NAMES.USA_NAMES.USA_1910_CURRENT
    WHERE "year" = 2021
      AND "gender" = 'F'
    GROUP BY "name"
),
proportions AS (
    SELECT
        w."name",
        w.wy_count / t.total_count::FLOAT AS proportion
    FROM wy_counts w
    JOIN total_counts t
      ON w."name" = t."name"
)
SELECT
    "name"
FROM proportions
ORDER BY proportion DESC NULLS LAST
LIMIT 1;