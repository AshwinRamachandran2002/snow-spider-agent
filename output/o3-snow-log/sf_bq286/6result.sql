WITH FEMALE_2021 AS (
    /* all female births in 2021 */
    SELECT
        "name",
        "state",
        SUM("number") AS cnt
    FROM USA_NAMES.USA_NAMES.USA_1910_CURRENT
    WHERE "gender" = 'F'
      AND "year"   = 2021
    GROUP BY "name", "state"
),
WY_COUNTS AS (
    /* Wyoming‐specific counts */
    SELECT
        "name",
        cnt AS wy_cnt
    FROM FEMALE_2021
    WHERE "state" = 'WY'
),
TOTAL_COUNTS AS (
    /* Total counts across all states */
    SELECT
        "name",
        SUM(cnt) AS total_cnt
    FROM FEMALE_2021
    GROUP BY "name"
),
RATIOS AS (
    /* Proportion of each name coming from Wyoming */
    SELECT
        w."name",
        w.wy_cnt / t.total_cnt AS proportion
    FROM WY_COUNTS w
    JOIN TOTAL_COUNTS t
      ON w."name" = t."name"
)
SELECT "name"
FROM RATIOS
ORDER BY proportion DESC NULLS LAST
LIMIT 1;