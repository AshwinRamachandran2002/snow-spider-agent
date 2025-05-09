WITH dates_per_country AS (
    -- keep one row per country & day in June 2022
    SELECT DISTINCT
           country_code_2,
           date(insert_date) AS d
    FROM   cities
    WHERE  insert_date BETWEEN '2022-06-01' AND '2022-06-30'
),
numbered AS (
    -- give each country’s days a running number
    SELECT
           country_code_2,
           d,
           ROW_NUMBER() OVER (PARTITION BY country_code_2 ORDER BY d) AS rn,
           julianday(d)                                        AS jd
    FROM   dates_per_country
),
grouped AS (
    -- consecutive days share the same (jd‑rn) value
    SELECT
           country_code_2,
           jd - rn AS grp_key
    FROM   numbered
),
streaks AS (
    -- length of every streak for each country
    SELECT
           country_code_2,
           COUNT(*) AS streak_len
    FROM   grouped
    GROUP BY country_code_2, grp_key
),
country_max AS (
    -- longest streak per country
    SELECT
           country_code_2,
           MAX(streak_len) AS max_streak
    FROM   streaks
    GROUP BY country_code_2
),
overall_max AS (
    -- the longest streak observed among all countries
    SELECT MAX(max_streak) AS global_max FROM country_max
)
-- countries whose longest streak equals the global longest streak
SELECT country_code_2
FROM   country_max
JOIN   overall_max ON max_streak = global_max;