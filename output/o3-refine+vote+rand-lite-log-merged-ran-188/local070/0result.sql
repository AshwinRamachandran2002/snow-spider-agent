WITH china_july AS (
    SELECT
        city_id,
        city_name,
        DATE(insert_date) AS dt
    FROM cities
    WHERE LOWER(country_code_2) = 'cn'
      AND insert_date LIKE '2021-07-%'
),
ordered_dates AS (
    SELECT
        dt,
        ROW_NUMBER() OVER (ORDER BY dt) AS rn,
        JULIANDAY(dt)                   AS jd
    FROM (SELECT DISTINCT dt FROM china_july)
),
grouped AS (
    SELECT
        dt,
        jd - rn AS grp                -- same value ⇒ consecutive-day group
    FROM ordered_dates
),
streaks AS (
    SELECT
        grp,
        COUNT(*) AS streak_len
    FROM grouped
    GROUP BY grp
),
bounds AS (
    SELECT
        MIN(streak_len) AS min_len,
        MAX(streak_len) AS max_len
    FROM streaks
),
target_groups AS (
    SELECT grp
    FROM streaks, bounds
    WHERE streak_len = min_len
       OR streak_len = max_len
)
SELECT
    g.dt AS date,
    MIN(UPPER(SUBSTR(c.city_name, 1, 1)) || LOWER(SUBSTR(c.city_name, 2))) AS city_name
FROM grouped        AS g
JOIN target_groups  AS tg ON g.grp = tg.grp
JOIN china_july     AS c  ON c.dt  = g.dt
GROUP BY g.dt
ORDER BY g.dt;