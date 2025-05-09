WITH country_dates AS (
    -- 1. Keep one row per country & date for June 2022
    SELECT DISTINCT 
           country_code_2,
           DATE(insert_date) AS dt
    FROM cities
    WHERE insert_date >= '2022-06-01'
      AND insert_date <  '2022-07-01'
),
numbered AS (
    -- 2. Give the dates a sequential number per country
    SELECT
        country_code_2,
        dt,
        ROW_NUMBER() OVER (PARTITION BY country_code_2 ORDER BY dt)      AS rn,
        JULIANDAY(dt)                                                    AS jd
    FROM country_dates
),
grouped AS (
    -- 3. Consecutive dates share the same (jd – rn) value
    SELECT
        country_code_2,
        jd - rn AS grp
    FROM numbered
),
streaks AS (
    -- 4. Size of each consecutive‑date streak
    SELECT
        country_code_2,
        grp,
        COUNT(*) AS streak_len
    FROM grouped
    GROUP BY country_code_2, grp
),
max_per_country AS (
    -- 5. Longest streak length per country
    SELECT
        country_code_2,
        MAX(streak_len) AS max_streak
    FROM streaks
    GROUP BY country_code_2
),
longest AS (
    -- 6. Overall longest streak length
    SELECT MAX(max_streak) AS longest_len
    FROM   max_per_country
)
-- 7. Countries whose longest streak equals the overall longest
SELECT m.country_code_2
FROM   max_per_country m
JOIN   longest l ON m.max_streak = l.longest_len
ORDER BY m.country_code_2;