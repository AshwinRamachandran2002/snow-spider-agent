WITH chinese_july AS (
    SELECT 
        DATE("insert_date")          AS dt,
        "city_name"
    FROM   "cities"
    WHERE  "country_code_2" = 'cn'
      AND  DATE("insert_date") BETWEEN '2021-07-01' AND '2021-07-31'
),
-- distinct dates that actually occur
dates_only AS (
    SELECT DISTINCT dt
    FROM   chinese_july
),
-- give each date a row number to detect gaps
ordered AS (
    SELECT 
        dt,
        ROW_NUMBER() OVER (ORDER BY dt)          AS rn,
        JULIANDAY(dt)                            AS jd
    FROM   dates_only
),
-- consecutive‑date groups
grouped AS (
    SELECT 
        dt,
        jd - rn                                   AS grp_id
    FROM   ordered
),
-- length of each consecutive streak
streaks AS (
    SELECT 
        grp_id,
        COUNT(*)                  AS len,
        MIN(dt)                   AS start_dt
    FROM   grouped
    GROUP BY grp_id
),
-- shortest and longest streak lengths
limits AS (
    SELECT 
        (SELECT MIN(len) FROM streaks) AS shortest,
        (SELECT MAX(len) FROM streaks) AS longest
),
-- pick one (earliest) streak for each of shortest and longest
chosen AS (
    SELECT grp_id
    FROM (
        SELECT grp_id, len, start_dt,
               ROW_NUMBER() OVER (PARTITION BY len ORDER BY start_dt) AS rnk
        FROM   streaks, limits
        WHERE  len = limits.shortest
           OR  len = limits.longest
    )
    WHERE  rnk = 1          -- earliest if tie
),
-- all dates that belong to the selected streak(s)
streak_dates AS (
    SELECT dt
    FROM   grouped
    WHERE  grp_id IN (SELECT grp_id FROM chosen)
),
-- one city per date (lexicographically first)
city_per_date AS (
    SELECT 
        sd.dt,
        (SELECT city_name
         FROM   chinese_july cj
         WHERE  cj.dt = sd.dt
         ORDER  BY city_name
         LIMIT 1) AS city_name
    FROM   streak_dates sd
)
SELECT 
    dt                                          AS date,
    UPPER(SUBSTR(city_name,1,1)) || LOWER(SUBSTR(city_name,2)) AS city_name
FROM   city_per_date
ORDER BY dt;