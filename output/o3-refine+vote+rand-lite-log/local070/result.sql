WITH filtered AS (
    SELECT 
        city_id,
        city_name,
        date(insert_date) AS dt
    FROM cities
    WHERE lower(country_code_2) = 'cn'
      AND date(insert_date) BETWEEN '2021-07-01' AND '2021-07-31'
),
daily_city AS (           -- keep exactly one record per date
    SELECT 
        dt,
        upper(substr(city_name,1,1)) || lower(substr(city_name,2)) AS city_name
    FROM (
        SELECT 
            dt,
            city_name,
            ROW_NUMBER() OVER (PARTITION BY dt ORDER BY city_name) AS rn
        FROM filtered
    )
    WHERE rn = 1
),
streak_prep AS (
    SELECT
        dt,
        city_name,
        ROW_NUMBER() OVER (ORDER BY dt)              AS rn,
        julianday(dt)                                AS jd
    FROM daily_city
),
streak_groups AS (
    SELECT
        dt,
        city_name,
        jd - rn AS grp_id
    FROM streak_prep
),
streak_lengths AS (
    SELECT
        grp_id,
        COUNT(*) AS streak_len
    FROM streak_groups
    GROUP BY grp_id
),
limits AS (               -- shortest and longest streak lengths
    SELECT 
        MIN(streak_len) AS min_len,
        MAX(streak_len) AS max_len
    FROM streak_lengths
),
chosen_grps AS (
    SELECT grp_id
    FROM streak_lengths
    JOIN limits
      ON streak_len = min_len
      OR streak_len = max_len
)
SELECT 
    dt  AS date,
    city_name
FROM streak_groups
JOIN chosen_grps USING (grp_id)
ORDER BY dt;