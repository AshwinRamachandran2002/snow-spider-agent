WITH june_dates AS (
    -- 1) keep one row per (country , day) for June-2022
    SELECT DISTINCT 
           "country_code_2",
           substr("insert_date",1,10) AS dt          -- yyyy-mm-dd
    FROM   "cities"
    WHERE  "insert_date" LIKE '2022-06%'
),
seq AS (
    -- 2) give each day a row number and its Julian day #
    SELECT  "country_code_2",
            dt,
            ROW_NUMBER() OVER (PARTITION BY "country_code_2" ORDER BY dt) AS rn,
            CAST(julianday(dt) AS INTEGER)                                AS jd
    FROM    june_dates
),
blocks AS (
    -- 3) jd-rn is constant within a consecutive-day block; count its length
    SELECT  "country_code_2",
            jd - rn                              AS block_key,
            COUNT(*)                             AS streak_len
    FROM    seq
    GROUP BY "country_code_2", block_key
),
country_max AS (
    -- 4) longest streak per country
    SELECT  "country_code_2",
            MAX(streak_len)  AS longest_streak
    FROM    blocks
    GROUP BY "country_code_2"
),
overall_max AS (
    -- 5) overall longest streak length
    SELECT MAX(longest_streak) AS max_streak
    FROM   country_max
)
-- 6) countries whose longest streak equals the overall maximum
SELECT cm."country_code_2"
FROM   country_max  AS cm
JOIN   overall_max AS om
  ON   cm.longest_streak = om.max_streak
ORDER BY cm."country_code_2";