WITH june_dates AS (          -- 1. keep one record per country‑day in June 2022
    SELECT DISTINCT
           country_code_2,
           DATE(insert_date) AS d
    FROM cities
    WHERE insert_date BETWEEN '2022-06-01' AND '2022-06-30'
),
num AS (                      -- 2. number the days per country
    SELECT
        country_code_2,
        d,
        ROW_NUMBER() OVER (PARTITION BY country_code_2 ORDER BY d) AS rn,
        CAST(julianday(d) AS INTEGER)                             AS jd
    FROM june_dates
),
grp AS (                      -- 3. identify consecutive‑day “islands”
    SELECT
        country_code_2,
        jd - rn AS grp_key     -- constant within a streak
    FROM num
),
streak_len AS (               -- 4. length of each streak
    SELECT
        country_code_2,
        grp_key,
        COUNT(*) AS len
    FROM grp
    GROUP BY country_code_2, grp_key
),
max_per_ctry AS (             -- 5. longest streak per country
    SELECT
        country_code_2,
        MAX(len) AS max_len
    FROM streak_len
    GROUP BY country_code_2
),
overall_max AS (              -- 6. longest streak length observed
    SELECT MAX(max_len) AS global_max FROM max_per_ctry
)
SELECT
    country_code_2            -- 7. countries that share that longest streak
FROM max_per_ctry
WHERE max_len = (SELECT global_max FROM overall_max);