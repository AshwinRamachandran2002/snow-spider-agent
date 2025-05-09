WITH china_july AS (
    SELECT 
        DATE(insert_date) AS dt,
        city_id,
        city_name
    FROM cities
    WHERE country_code_2 = 'cn'
      AND DATE(insert_date) BETWEEN '2021-07-01' AND '2021-07-31'
),
distinct_dates AS (          -- one row per date
    SELECT DISTINCT dt
    FROM china_july
),
ordered AS (                 -- give each date a row number
    SELECT 
        dt,
        ROW_NUMBER() OVER (ORDER BY dt)            AS rn,
        julianday(dt)                              AS jd
    FROM distinct_dates
),
grp_calc AS (                -- consecutive‑date groups
    SELECT 
        dt,
        jd - rn                                AS grp_id
    FROM ordered
),
streaks AS (                 -- length of each streak
    SELECT 
        grp_id,
        COUNT(*)                AS len,
        MIN(dt)                 AS first_dt
    FROM grp_calc
    GROUP BY grp_id
),
chosen AS (                  -- identify the shortest & longest streaks
    SELECT 
        (SELECT grp_id 
         FROM streaks 
         WHERE len = (SELECT MIN(len) FROM streaks)
         ORDER BY first_dt
         LIMIT 1) AS short_grp,
        (SELECT grp_id 
         FROM streaks 
         WHERE len = (SELECT MAX(len) FROM streaks)
         ORDER BY first_dt
         LIMIT 1) AS long_grp
),
streak_dates AS (            -- all dates belonging to those two streaks
    SELECT dt
    FROM grp_calc, chosen
    WHERE grp_id IN (short_grp, long_grp)
),
one_city_per_date AS (       -- pick exactly one city for each date
    SELECT 
        sd.dt,
        (SELECT city_name 
         FROM china_july cj 
         WHERE cj.dt = sd.dt 
         ORDER BY city_id 
         LIMIT 1) AS city_name
    FROM streak_dates sd
)
SELECT 
    dt  AS date,
    UPPER(SUBSTR(city_name,1,1)) || LOWER(SUBSTR(city_name,2)) AS city_name
FROM one_city_per_date
ORDER BY dt;