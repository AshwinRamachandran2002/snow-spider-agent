WITH base AS (
    -- keep one row per date & track the “consecutive‐date group” (grp)
    SELECT
        insert_date,
        city_name,
        julianday(insert_date) 
          - ROW_NUMBER() OVER (ORDER BY insert_date)              AS grp,
        ROW_NUMBER() OVER (PARTITION BY insert_date 
                           ORDER BY city_name)                    AS rn
    FROM cities
    WHERE country_code_2 = 'cn'
      AND insert_date BETWEEN '2021-07-01' AND '2021-07-31'
),
lens AS (                       -- length of every consecutive-date streak
    SELECT grp,
           COUNT(DISTINCT insert_date) AS streak_len
    FROM base
    GROUP BY grp
),
bounds AS (                     -- shortest & longest streak lengths
    SELECT MIN(streak_len) AS min_len,
           MAX(streak_len) AS max_len
    FROM lens
),
target_grps AS (                -- groups that are shortest OR longest
    SELECT grp
    FROM lens, bounds
    WHERE streak_len = min_len
       OR streak_len = max_len
)
SELECT
    b.insert_date                         AS date,
    upper(substr(b.city_name,1,1)) ||
    lower(substr(b.city_name,2))          AS city
FROM base b
JOIN target_grps USING (grp)
WHERE b.rn = 1                             -- exactly one city per date
ORDER BY b.insert_date;