WITH jan_counts AS (       -- 1. Countries that have data on exactly 9 different January-2022 days
    SELECT country_code_2,
           COUNT(DISTINCT insert_date) AS jan_days
    FROM   cities
    WHERE  insert_date LIKE '2022-01-%'
    GROUP  BY country_code_2
    HAVING jan_days = 9
),
target_country AS (        -- 2. Keep (the) country with 9 days (only one expected; otherwise first)
    SELECT country_code_2
    FROM   jan_counts
    LIMIT  1
),
d AS (                     -- 3. Prepare dated rows for that country
    SELECT c.insert_date,
           julianday(c.insert_date)                                    AS jd,
           ROW_NUMBER() OVER (ORDER BY c.insert_date, c.city_id)       AS rn
    FROM   cities  AS c
    JOIN   target_country AS t
           ON c.country_code_2 = t.country_code_2
    WHERE  c.insert_date LIKE '2022-01-%'
),
streaks AS (               -- 4. Detect consecutive-day streaks
    SELECT (jd - rn)                       AS grp,
           MIN(insert_date)                AS streak_start,
           MAX(insert_date)                AS streak_end,
           COUNT(*)                        AS streak_len
    FROM   d
    GROUP  BY grp
),
longest AS (               -- 5. Pick the longest streak
    SELECT streak_start, streak_end, streak_len
    FROM   streaks
    ORDER  BY streak_len DESC, streak_start
    LIMIT  1
),
streak_cities AS (         -- 6. All rows that fall inside the longest streak
    SELECT c.*
    FROM   cities AS c
    JOIN   target_country AS t
           ON c.country_code_2 = t.country_code_2
    JOIN   longest         AS l
           ON c.insert_date BETWEEN l.streak_start AND l.streak_end
)
-- 7. Final answer: country, streak period, length, & capital-city proportion
SELECT  cc.country_name,
        tc.country_code_2,
        jc.jan_days,
        l.streak_start,
        l.streak_end,
        l.streak_len,
        ROUND( SUM(sc.capital) * 1.0 / COUNT(*), 4 )  AS capital_proportion
FROM    target_country  AS tc
JOIN    jan_counts      AS jc ON jc.country_code_2 = tc.country_code_2
JOIN    cities_countries AS cc ON cc.country_code_2 = tc.country_code_2
JOIN    longest         AS l
JOIN    streak_cities   AS sc
GROUP   BY cc.country_name,
         tc.country_code_2,
         jc.jan_days,
         l.streak_start,
         l.streak_end,
         l.streak_len;