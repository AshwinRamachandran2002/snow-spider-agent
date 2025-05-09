WITH june_cities AS (
    SELECT 
        country_code_2,
        insert_date,
        julianday(insert_date) AS jd
    FROM cities
    WHERE insert_date >= '2022-06-01'
      AND insert_date <  '2022-07-01'
),
ordered AS (
    SELECT
        country_code_2,
        insert_date,
        jd,
        ROW_NUMBER() OVER (PARTITION BY country_code_2 ORDER BY insert_date) AS rn
    FROM june_cities
),
grouped AS (
    SELECT
        country_code_2,
        (jd - rn) AS grp_key          -- same value => consecutive‑date run
    FROM ordered
),
streak_lengths AS (
    SELECT
        country_code_2,
        grp_key,
        COUNT(*) AS streak_len
    FROM grouped
    GROUP BY country_code_2, grp_key
),
country_max AS (
    SELECT
        country_code_2,
        MAX(streak_len) AS max_streak
    FROM streak_lengths
    GROUP BY country_code_2
),
global_max AS (
    SELECT MAX(max_streak) AS longest_overall
    FROM country_max
)
SELECT 
    country_code_2
FROM country_max
WHERE max_streak = (SELECT longest_overall FROM global_max);