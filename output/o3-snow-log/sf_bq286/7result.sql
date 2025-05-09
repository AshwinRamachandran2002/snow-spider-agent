WITH total_per_name AS (
    SELECT
        "name",
        SUM("number") AS total_number
    FROM "USA_NAMES"."USA_NAMES"."USA_1910_CURRENT"
    WHERE "gender" = 'F'
      AND "year" = 2021
    GROUP BY "name"
),
wyoming_per_name AS (
    SELECT
        "name",
        SUM("number") AS wy_number
    FROM "USA_NAMES"."USA_NAMES"."USA_1910_CURRENT"
    WHERE "gender" = 'F'
      AND "year" = 2021
      AND "state" = 'WY'
    GROUP BY "name"
),
proportions AS (
    SELECT
        w."name",
        w.wy_number / t.total_number AS proportion
    FROM wyoming_per_name w
    JOIN total_per_name t
      ON w."name" = t."name"
)
SELECT "name"
FROM proportions
ORDER BY proportion DESC NULLS LAST
LIMIT 1;