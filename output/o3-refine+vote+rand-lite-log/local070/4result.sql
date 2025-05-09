WITH filtered AS (
    -- 1.  Chinese cities recorded in July 2021
    SELECT city_id,
           city_name,
           insert_date
    FROM cities
    WHERE country_code_2 = 'cn'
      AND insert_date BETWEEN '2021-07-01' AND '2021-07-31'
),
ordered AS (
    -- 2.  Assign each row to a consecutive‑date group
    SELECT city_id,
           city_name,
           insert_date,
           julianday(insert_date)
           - ROW_NUMBER() OVER (ORDER BY insert_date) AS grp
    FROM filtered
),
streaks AS (
    -- 3.  Length of every consecutive‑date streak
    SELECT grp,
           COUNT(*) AS streak_len
    FROM ordered
    GROUP BY grp
),
limits AS (
    -- 4.  Shortest and longest streak lengths
    SELECT MIN(streak_len) AS min_len,
           MAX(streak_len) AS max_len
    FROM streaks
),
selected AS (
    -- 5.  Rows belonging to either the shortest or longest streak(s)
    SELECT o.*
    FROM ordered o
    JOIN streaks s   ON o.grp = s.grp
    JOIN limits  l   ON s.streak_len = l.min_len
                    OR s.streak_len = l.max_len
),
one_per_date AS (
    -- 6.  Keep exactly one city per date and capitalise its name
    SELECT insert_date,
           UPPER(SUBSTR(LOWER(city_name),1,1)) || SUBSTR(LOWER(city_name),2) AS city_name,
           ROW_NUMBER() OVER (PARTITION BY insert_date ORDER BY city_id) AS rn
    FROM selected
)
-- 7.  Final result: dates & city names for the shortest and longest streaks
SELECT insert_date,
       city_name
FROM one_per_date
WHERE rn = 1
ORDER BY insert_date;