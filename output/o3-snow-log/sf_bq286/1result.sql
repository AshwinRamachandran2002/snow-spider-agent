WITH wyoming AS (
    SELECT
        "name",
        SUM("number") AS wy_count
    FROM USA_NAMES.USA_NAMES.USA_1910_CURRENT
    WHERE "state" = 'WY'
      AND "gender" = 'F'
      AND "year" = 2021
    GROUP BY "name"
),
national AS (
    SELECT
        "name",
        SUM("number") AS nat_count
    FROM USA_NAMES.USA_NAMES.USA_1910_CURRENT
    WHERE "gender" = 'F'
      AND "year" = 2021
    GROUP BY "name"
),
ratios AS (
    SELECT
        w."name",
        w.wy_count,
        n.nat_count,
        (w.wy_count::FLOAT / n.nat_count) AS proportion
    FROM wyoming w
    JOIN national n
      ON w."name" = n."name"
)
SELECT
    "name"
FROM ratios
ORDER BY
    proportion DESC NULLS LAST,
    wy_count  DESC NULLS LAST,
    "name"
LIMIT 1;