WITH june_inserts AS (
    SELECT
        "country_code_2",
        "insert_date",
        julianday("insert_date")
        - julianday(LAG("insert_date") OVER (
              PARTITION BY "country_code_2"
              ORDER BY "insert_date"
          )) AS diff_days
    FROM "cities"
    WHERE "insert_date" LIKE '2022-06%'                       -- only June 2022 records
),
streak_groups AS (
    SELECT
        "country_code_2",
        "insert_date",
        SUM(CASE WHEN diff_days IS NULL OR diff_days <> 1
                 THEN 1 ELSE 0 END)
        OVER (PARTITION BY "country_code_2"
              ORDER BY "insert_date")            AS streak_group
    FROM june_inserts
),
streak_lengths AS (
    SELECT
        "country_code_2",
        streak_group,
        COUNT(*) AS streak_length
    FROM streak_groups
    GROUP BY "country_code_2", streak_group
),
max_streak_per_country AS (
    SELECT
        "country_code_2",
        MAX(streak_length) AS max_streak
    FROM streak_lengths
    GROUP BY "country_code_2"
),
overall_max AS (
    SELECT MAX(max_streak) AS longest_streak
    FROM max_streak_per_country
)
SELECT m."country_code_2"
FROM   max_streak_per_country AS m
JOIN   overall_max            AS o
  ON   m.max_streak = o.longest_streak
ORDER BY m."country_code_2";