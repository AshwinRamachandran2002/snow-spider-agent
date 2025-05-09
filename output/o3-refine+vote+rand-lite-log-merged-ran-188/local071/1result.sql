WITH june_dates AS (
    -- keep one row per country/date for June 2022
    SELECT DISTINCT
           country_code_2,
           insert_date
    FROM   cities
    WHERE  insert_date BETWEEN '2022-06-01' AND '2022-06-30'
),
seq AS (   -- assign a sequence number per country ordered by date
    SELECT
        country_code_2,
        insert_date,
        julianday(insert_date) 
        - ROW_NUMBER() OVER (PARTITION BY country_code_2
                             ORDER BY insert_date)     AS grp
    FROM   june_dates
),
streaks AS (  -- length of each consecutive‑days streak
    SELECT
        country_code_2,
        COUNT(*) AS streak_len
    FROM   seq
    GROUP BY
        country_code_2,
        grp
),
max_per_country AS (   -- longest streak for every country
    SELECT
        country_code_2,
        MAX(streak_len) AS max_streak
    FROM   streaks
    GROUP BY
        country_code_2
),
overall_max AS (       -- the longest streak observed across all countries
    SELECT MAX(max_streak) AS longest_streak
    FROM   max_per_country
)
-- return the 2‑letter country codes that share that longest streak
SELECT m.country_code_2
FROM   max_per_country m
JOIN   overall_max      o ON m.max_streak = o.longest_streak;