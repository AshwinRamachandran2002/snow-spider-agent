WITH total_name_counts AS (
    /* total female births per name across all states in 2021 */
    SELECT
        "name",
        SUM("number") AS total_count
    FROM USA_NAMES.USA_NAMES.USA_1910_CURRENT
    WHERE "year" = 2021
      AND "gender" = 'F'
    GROUP BY "name"
),
wyoming_2021 AS (
    /* female births in Wyoming in 2021 with their share of national total */
    SELECT
        w."name",
        w."number" AS wy_count,
        t.total_count,
        w."number" / t.total_count AS wy_share
    FROM USA_NAMES.USA_NAMES.USA_1910_CURRENT w
    JOIN total_name_counts t
      ON w."name" = t."name"
    WHERE w."year"  = 2021
      AND w."gender" = 'F'
      AND w."state"  = 'WY'
)
SELECT "name"
FROM wyoming_2021
ORDER BY wy_share DESC NULLS LAST
LIMIT 1;