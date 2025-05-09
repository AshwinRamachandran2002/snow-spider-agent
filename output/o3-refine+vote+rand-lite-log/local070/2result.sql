WITH china_july_dates AS (          -- 1. every DISTINCT 2021‑07 date with at least one CN city
    SELECT DISTINCT DATE(insert_date) AS dt
    FROM cities
    WHERE country_code_2 = 'cn'
      AND DATE(insert_date) BETWEEN '2021-07-01' AND '2021-07-31'
),

ordered_dates AS (                  -- 2. put the dates in order and number them
    SELECT
        dt,
        ROW_NUMBER() OVER (ORDER BY dt) AS rn
    FROM china_july_dates
),

grouped AS (                        -- 3. consecutive‑date groups
    SELECT
        dt,
        (JULIANDAY(dt) - rn) AS grp_key
    FROM ordered_dates
),

streaks AS (                        -- 4. length of every streak
    SELECT
        grp_key,
        COUNT(*) AS streak_len
    FROM grouped
    GROUP BY grp_key
),

limits AS (                         -- 5. shortest & longest streak size
    SELECT
        MIN(streak_len) AS min_len,
        MAX(streak_len) AS max_len
    FROM streaks
),

wanted_dates AS (                   -- 6. all dates belonging to the min or max streak(s)
    SELECT g.dt
    FROM grouped  AS g
    JOIN streaks  AS s ON g.grp_key = s.grp_key
    JOIN limits   AS l ON s.streak_len = l.min_len OR s.streak_len = l.max_len
),

one_city_per_date AS (              -- 7. pick exactly one CN city per date
    SELECT
        d.dt,
        UPPER(SUBSTR(c.city_name,1,1)) || LOWER(SUBSTR(c.city_name,2)) AS city_name
    FROM wanted_dates d
    JOIN cities c
         ON DATE(c.insert_date) = d.dt
        AND c.country_code_2 = 'cn'
    GROUP BY d.dt                       -- get one row per date
    HAVING MIN(c.city_id)               -- (sqlite trick: keeps the first city_id row)
)

-- 8. final output
SELECT
    dt   AS date,
    city_name
FROM one_city_per_date
ORDER BY date;