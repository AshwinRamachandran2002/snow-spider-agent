WITH june_dates AS (
    SELECT 
        "country_code_2",
        "insert_date"
    FROM "cities"
    WHERE "insert_date" BETWEEN '2022-06-01' AND '2022-06-30'
),
numed AS (
    SELECT
        "country_code_2",
        "insert_date",
        ROW_NUMBER() OVER (
            PARTITION BY "country_code_2"
            ORDER BY "insert_date"
        ) AS rn
    FROM june_dates
),
streak_groups AS (
    SELECT
        "country_code_2",
        julianday("insert_date") - rn AS grp_key
    FROM numed
),
streak_lengths AS (
    SELECT
        "country_code_2",
        grp_key,
        COUNT(*) AS streak_len
    FROM streak_groups
    GROUP BY "country_code_2", grp_key
),
max_per_country AS (
    SELECT
        "country_code_2",
        MAX(streak_len) AS max_streak
    FROM streak_lengths
    GROUP BY "country_code_2"
),
overall_max AS (
    SELECT MAX(max_streak) AS longest_streak
    FROM max_per_country
)
SELECT "country_code_2"
FROM   max_per_country
WHERE  max_streak = (SELECT longest_streak FROM overall_max);