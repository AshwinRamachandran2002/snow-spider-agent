WITH cn_july AS (
    -- All Chinese city rows in July-2021
    SELECT city_id,
           city_name,
           insert_date
    FROM   cities
    WHERE  country_code_2 = 'cn'
      AND  insert_date BETWEEN '2021-07-01' AND '2021-07-31'
),
distinct_dates AS (          -- one row per date
    SELECT DISTINCT insert_date
    FROM   cn_july
),
grp_dates AS (               -- build “streak key” for consecutive dates
    SELECT insert_date,
           julianday(insert_date)
           - ROW_NUMBER() OVER (ORDER BY insert_date) AS grp_key
    FROM   distinct_dates
),
streaks AS (                 -- length of every streak
    SELECT grp_key,
           COUNT(*) AS streak_len
    FROM   grp_dates
    GROUP BY grp_key
),
targets AS (                 -- keep only shortest and longest streak(s)
    SELECT grp_key
    FROM   streaks
    WHERE  streak_len = (SELECT MIN(streak_len) FROM streaks)
       OR  streak_len = (SELECT MAX(streak_len) FROM streaks)
),
chosen_dates AS (            -- pick exactly one city per target date
    SELECT gd.insert_date,
           MIN(cj.city_id) AS city_id          -- arbitrary single city
    FROM   grp_dates  gd
    JOIN   targets    t  ON t.grp_key = gd.grp_key
    JOIN   cn_july    cj ON cj.insert_date = gd.insert_date
    GROUP  BY gd.insert_date
)
SELECT cd.insert_date,
       UPPER(SUBSTR(c.city_name,1,1))
       || LOWER(SUBSTR(c.city_name,2)) AS city_name
FROM   chosen_dates cd
JOIN   cities        c ON c.city_id = cd.city_id
ORDER BY cd.insert_date;