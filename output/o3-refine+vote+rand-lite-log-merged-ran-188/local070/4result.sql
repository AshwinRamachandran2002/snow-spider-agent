WITH china AS (
    -- 1.  Chinese city records in July-2021
    SELECT city_id,
           city_name,
           insert_date
    FROM   cities
    WHERE  country_code_2 = 'cn'
      AND  insert_date BETWEEN '2021-07-01' AND '2021-07-31'
),
-- 2.  Distinct dates we actually have
dates AS (
    SELECT DISTINCT insert_date
    FROM   china
),
-- 3.  Give every date a running number
ordered AS (
    SELECT insert_date,
           ROW_NUMBER() OVER (ORDER BY insert_date) AS rn
    FROM   dates
),
-- 4.  “grp_key” = date shifted back by its row_number → same value within a consecutive-day streak
grp AS (
    SELECT insert_date,
           DATE(insert_date, '-' || rn || ' day') AS grp_key
    FROM   ordered
),
-- 5.  Build every streak with its length
streaks AS (
    SELECT grp_key,
           MIN(insert_date) AS streak_start,
           MAX(insert_date) AS streak_end,
           COUNT(*)         AS len
    FROM   grp
    GROUP BY grp_key
),
-- 6.  What is the shortest and what is the longest streak length?
limits AS (
    SELECT MIN(len) AS min_len,
           MAX(len) AS max_len
    FROM   streaks
),
-- 7.  Keep only streaks whose length = shortest OR longest
wanted_streaks AS (
    SELECT s.grp_key,
           s.len
    FROM   streaks  s
    JOIN   limits   l
           ON s.len = l.min_len
           OR s.len = l.max_len
),
-- 8.  All dates that belong to the wanted streak(s)
wanted_dates AS (
    SELECT g.insert_date,
           w.len
    FROM   grp g
    JOIN   wanted_streaks w
           ON g.grp_key = w.grp_key
),
-- 9.  Pick exactly one city per date (alphabetically first), and capitalize it
city_per_date AS (
    SELECT wd.insert_date,
           UPPER(SUBSTR(MIN(c.city_name),1,1)) ||
           LOWER(SUBSTR(MIN(c.city_name),2))        AS city_name
    FROM   wanted_dates wd
    JOIN   china        c
           ON c.insert_date = wd.insert_date
    GROUP BY wd.insert_date
)
-- 10.  Final output: one row per date, ordered chronologically
SELECT insert_date,
       city_name
FROM   city_per_date
ORDER  BY insert_date;