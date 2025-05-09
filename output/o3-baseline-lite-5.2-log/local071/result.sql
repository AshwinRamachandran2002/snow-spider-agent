WITH june_cities AS (
    -- 1. keep only one row per country‑day in June 2022
    SELECT DISTINCT
           country_code_2,
           DATE(insert_date)   AS dt
    FROM   cities
    WHERE  insert_date >= '2022-06-01'
       AND insert_date <  '2022-07-01'
),
ordered AS (
    -- 2. order the dates per country
    SELECT country_code_2,
           dt,
           ROW_NUMBER() OVER (PARTITION BY country_code_2
                              ORDER BY dt)            AS rn,
           julianday(dt)                              AS jd
    FROM   june_cities
),
grouped AS (
    -- 3. equal value of (julianday – row_number) ⇒ consecutive block
    SELECT country_code_2,
           jd - rn               AS grp_key
    FROM   ordered
),
streaks AS (
    -- 4. length of every consecutive block
    SELECT country_code_2,
           grp_key,
           COUNT(*)              AS streak_len
    FROM   grouped
    GROUP BY country_code_2, grp_key
),
max_streaks AS (
    -- 5. longest block for each country
    SELECT country_code_2,
           MAX(streak_len)       AS max_len
    FROM   streaks
    GROUP BY country_code_2
),
global_max AS (
    -- 6. longest block across all countries
    SELECT MAX(max_len) AS gmax FROM max_streaks
)
-- 7. countries whose longest streak equals the global maximum
SELECT m.country_code_2
FROM   max_streaks  AS m
JOIN   global_max   AS g  ON m.max_len = g.gmax;