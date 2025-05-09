WITH june_cities AS (             -- 1. cities inserted in June-2022 (distinct dates)
    SELECT DISTINCT
           "country_code_2",
           TO_DATE("insert_date")        AS dt
    FROM   CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE  TO_DATE("insert_date")
           BETWEEN '2022-06-01' AND '2022-06-30'
),

ranked AS (                       -- 2. give every country its ordered dates
    SELECT
        "country_code_2",
        dt,
        ROW_NUMBER() OVER (PARTITION BY "country_code_2" ORDER BY dt)                         AS rn,
        DATEDIFF('day', DATE '1970-01-01', dt)                                                AS serial_day
    FROM june_cities
),

grp AS (                          -- 3. same (serial_day – rn) ⇢ one consecutive group
    SELECT
        "country_code_2",
        serial_day - rn                                               AS grp_id,
        COUNT(*)                                                      AS streak_len
    FROM ranked
    GROUP BY "country_code_2", grp_id
),

streaks AS (                      -- 4. longest streak length per country
    SELECT
        "country_code_2",
        MAX(streak_len)                                               AS max_streak
    FROM grp
    GROUP BY "country_code_2"
),

max_overall AS (                  -- 5. global longest streak
    SELECT MAX(max_streak) AS global_max FROM streaks
)

-- 6. countries whose longest streak equals the global longest
SELECT s."country_code_2"
FROM   streaks      s
JOIN   max_overall  m  ON s.max_streak = m.global_max
ORDER  BY s."country_code_2";