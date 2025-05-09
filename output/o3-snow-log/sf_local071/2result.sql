WITH june_data AS (   -- 1. keep only June-2022 insertions, one row per country-date
    SELECT DISTINCT 
           "country_code_2",
           TO_DATE("insert_date") AS dt
    FROM CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE TO_DATE("insert_date") BETWEEN '2022-06-01' AND '2022-06-30'
),
seq AS (               -- 2. create a sequence number & gap-key per country
    SELECT
        "country_code_2",
        dt,
        ROW_NUMBER() OVER (PARTITION BY "country_code_2" ORDER BY dt)                    AS rn,
        DATEDIFF('day', DATE '2022-01-01', dt) 
          - ROW_NUMBER() OVER (PARTITION BY "country_code_2" ORDER BY dt)                AS grp_key
    FROM june_data
),
streaks AS (           -- 3. length of every consecutive-days streak
    SELECT 
        "country_code_2",
        COUNT(*) AS streak_len
    FROM seq
    GROUP BY "country_code_2", grp_key
),
max_streaks AS (       -- 4. longest streak for each country
    SELECT 
        "country_code_2",
        MAX(streak_len) AS max_streak
    FROM streaks
    GROUP BY "country_code_2"
),
global_max AS (        -- 5. overall longest streak length
    SELECT MAX(max_streak) AS gmax FROM max_streaks
)
SELECT m."country_code_2"              -- 6. countries that achieved that longest streak
FROM   max_streaks  AS m
JOIN   global_max   AS g
       ON m.max_streak = g.gmax
ORDER BY m."country_code_2";