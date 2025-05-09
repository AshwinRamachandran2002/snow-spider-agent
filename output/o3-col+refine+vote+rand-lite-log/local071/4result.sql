WITH date_positions AS (
    SELECT
        country_code_2,
        insert_date,
        ROW_NUMBER() OVER (
            PARTITION BY country_code_2
            ORDER BY insert_date
        ) AS rn
    FROM cities
    WHERE insert_date LIKE '2022-06-%'
),
grouped_days AS (
    SELECT
        country_code_2,
        julianday(insert_date) - rn AS grp_key
    FROM date_positions
),
streaks AS (
    SELECT
        country_code_2,
        grp_key,
        COUNT(*) AS streak_len
    FROM grouped_days
    GROUP BY country_code_2, grp_key
),
longest_per_country AS (
    SELECT
        country_code_2,
        MAX(streak_len) AS longest_streak
    FROM streaks
    GROUP BY country_code_2
),
max_streak_val AS (
    SELECT MAX(longest_streak) AS max_len
    FROM longest_per_country
)
SELECT country_code_2
FROM longest_per_country
WHERE longest_streak = (SELECT max_len FROM max_streak_val);