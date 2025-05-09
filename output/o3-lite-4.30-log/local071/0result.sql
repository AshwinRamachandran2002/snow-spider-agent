WITH daily AS (
    SELECT DISTINCT
        country_code_2,
        insert_date
    FROM cities
    WHERE insert_date BETWEEN '2022-06-01' AND '2022-06-30'
),
seq AS (
    SELECT
        country_code_2,
        insert_date,
        julianday(insert_date) -
        ROW_NUMBER() OVER (
            PARTITION BY country_code_2
            ORDER BY insert_date
        ) AS grp_id
    FROM daily
),
streaks AS (
    SELECT
        country_code_2,
        COUNT(*) AS streak_len
    FROM seq
    GROUP BY country_code_2, grp_id
),
max_each AS (
    SELECT
        country_code_2,
        MAX(streak_len) AS max_streak_len
    FROM streaks
    GROUP BY country_code_2
),
overall AS (
    SELECT MAX(max_streak_len) AS global_max FROM max_each
)
SELECT
    max_each.country_code_2 AS country_code
FROM max_each
JOIN overall
      ON max_each.max_streak_len = overall.global_max
ORDER BY country_code;