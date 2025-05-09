WITH dates AS (
    -- 1. get every distinct July‑2021 date that has at least one Chinese city record
    SELECT DISTINCT
           insert_date AS date
    FROM   cities
    WHERE  country_code_2 = 'cn'
      AND  insert_date BETWEEN '2021-07-01' AND '2021-07-31'
),
seq AS (
    -- 2. turn consecutive calendar days into the same “grp” number
    SELECT  date,
            CAST(julianday(date)
                 - ROW_NUMBER() OVER (ORDER BY date)         -- gap‑and‑islands trick
                 AS INTEGER)        AS grp
    FROM    dates
),
streaks AS (
    -- 3. measure each streak’s length
    SELECT  grp,
            MIN(date)                AS start_date,
            MAX(date)                AS end_date,
            COUNT(*)                 AS len
    FROM    seq
    GROUP BY grp
),
-- 4. pick ONE longest and ONE shortest streak (earliest if ties)
longest AS (
    SELECT grp FROM streaks ORDER BY len DESC, start_date LIMIT 1
),
shortest AS (
    SELECT grp FROM streaks ORDER BY len ASC, start_date LIMIT 1
),
wanted_streaks AS (
    SELECT 'longest'  AS which, grp FROM longest
    UNION ALL
    SELECT 'shortest', grp FROM shortest
),
dates_in_streaks AS (
    -- 5. all individual dates belonging to those two streaks
    SELECT s.date, w.which
    FROM   seq s
    JOIN   wanted_streaks w
           ON s.grp = w.grp
),
one_city_per_date AS (
    -- 6. for every such date choose exactly one city (alphabetically)
    SELECT  d.date,
            ( SELECT city_name
              FROM   cities c
              WHERE  c.country_code_2 = 'cn'
                AND  c.insert_date     = d.date
              ORDER BY LOWER(city_name)
              LIMIT 1 )               AS city_name
    FROM    dates_in_streaks d
)
-- 7. final output
SELECT  date,
        UPPER(SUBSTR(city_name,1,1)) || LOWER(SUBSTR(city_name,2)) AS city_name
FROM    one_city_per_date
ORDER BY date;