WITH lagged AS (
    SELECT
        "country_code_2",
        DATE("insert_date") AS d,
        CASE
            WHEN LAG(DATE("insert_date")) OVER (
                     PARTITION BY "country_code_2"
                     ORDER BY DATE("insert_date")
                 ) IS NOT NULL
                 AND julianday(DATE("insert_date")) =
                     julianday(LAG(DATE("insert_date")) OVER (
                                   PARTITION BY "country_code_2"
                                   ORDER BY DATE("insert_date")
                               )) + 1
            THEN 0
            ELSE 1
        END AS new_block
    FROM "cities"
    WHERE "insert_date" LIKE '2022-06-%'
),
streaks AS (
    SELECT
        "country_code_2",
        d,
        SUM(new_block) OVER (
            PARTITION BY "country_code_2"
            ORDER BY d
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS streak_id
    FROM lagged
),
streak_lengths AS (
    SELECT
        "country_code_2",
        streak_id,
        COUNT(*) AS len
    FROM streaks
    GROUP BY "country_code_2", streak_id
),
max_per_country AS (
    SELECT
        "country_code_2",
        MAX(len) AS longest_streak
    FROM streak_lengths
    GROUP BY "country_code_2"
),
global_max AS (
    SELECT MAX(longest_streak) AS max_len FROM max_per_country
)
SELECT m."country_code_2" AS country_code
FROM   max_per_country AS m
JOIN   global_max      AS g
  ON   m.longest_streak = g.max_len
ORDER BY country_code;