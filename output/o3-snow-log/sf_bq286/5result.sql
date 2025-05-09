WITH total_counts AS (
    SELECT
        "name",
        SUM("number") AS total_number
    FROM USA_NAMES.USA_NAMES.USA_1910_CURRENT
    WHERE "gender" = 'F'
      AND "year"   = 2021
    GROUP BY "name"
),
wy_counts AS (
    SELECT
        "name",
        SUM("number") AS wy_number
    FROM USA_NAMES.USA_NAMES.USA_1910_CURRENT
    WHERE "gender" = 'F'
      AND "year"   = 2021
      AND "state"  = 'WY'
    GROUP BY "name"
)
SELECT
    wy."name"
FROM wy_counts wy
JOIN total_counts tot
  ON wy."name" = tot."name"
ORDER BY (wy.wy_number / NULLIF(tot.total_number, 0)) DESC NULLS LAST
LIMIT 1;