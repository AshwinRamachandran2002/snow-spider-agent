WITH jan22 AS (                             -- all January-2022 rows
    SELECT
        country_code_2,
        DATE(insert_date) AS insert_dt,
        *
    FROM   cities
    WHERE  strftime('%Y-%m', insert_date) = '2022-01'
),
target_country AS (                         -- country having exactly 9 distinct insert days
    SELECT country_code_2
    FROM   jan22
    GROUP  BY country_code_2
    HAVING COUNT(DISTINCT insert_dt) = 9
    LIMIT  1
),
country_days AS (                           -- distinct days for that country
    SELECT
        insert_dt,
        ROW_NUMBER() OVER (ORDER BY insert_dt) AS rn
    FROM   (SELECT DISTINCT insert_dt
            FROM   jan22
            WHERE  country_code_2 = (SELECT country_code_2 FROM target_country))
),
streaks AS (                                -- tag consecutive-day blocks
    SELECT
        (julianday(insert_dt) - rn)            AS streak_id,
        MIN(insert_dt)                         AS streak_start,
        MAX(insert_dt)                         AS streak_end,
        COUNT(*)                               AS streak_len
    FROM   country_days
    GROUP  BY streak_id
),
longest AS (                                 -- longest consecutive period
    SELECT *
    FROM   streaks
    ORDER  BY streak_len DESC, streak_start
    LIMIT  1
),
period_rows AS (                             -- all rows that fall inside that period
    SELECT *
    FROM   jan22
    WHERE  country_code_2 = (SELECT country_code_2 FROM target_country)
      AND  insert_dt BETWEEN (SELECT streak_start FROM longest)
                         AND     (SELECT streak_end   FROM longest)
)
SELECT
    cc.country_name,
    tc.country_code_2,
    l.streak_start,
    l.streak_end,
    l.streak_len,
    ROUND( SUM(CASE WHEN pr.capital = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*), 4) AS capital_ratio
FROM               longest          AS l
CROSS JOIN         target_country   AS tc
JOIN               cities_countries AS cc
                       ON cc.country_code_2 = tc.country_code_2
JOIN               period_rows      AS pr
                       ON 1 = 1
GROUP BY cc.country_name,
         tc.country_code_2,
         l.streak_start,
         l.streak_end,
         l.streak_len;