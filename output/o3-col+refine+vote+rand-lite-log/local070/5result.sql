WITH julydates AS (
    -- every distinct July-2021 date that has at least one Chinese city row
    SELECT DISTINCT DATE(insert_date) AS dt
    FROM   cities
    WHERE  country_code_2 = 'cn'
      AND  insert_date BETWEEN '2021-07-01' AND '2021-07-31'
),
ordered AS (
    -- give the dates a running number & their Julian-day value
    SELECT dt,
           ROW_NUMBER() OVER (ORDER BY dt)   AS rn,
           julianday(dt)                     AS jd
    FROM   julydates
),
grp AS (
    -- consecutive calendar days share the same grp value
    SELECT dt,
           rn - CAST(jd AS INTEGER)          AS grp
    FROM   ordered
),
streaks AS (
    -- length (number of days) of every consecutive-date streak
    SELECT grp,
           COUNT(*)                          AS len
    FROM   grp
    GROUP  BY grp
),
limits AS (
    SELECT MIN(len) AS shortest ,
           MAX(len) AS longest
    FROM   streaks
),
target_dates AS (
    -- keep only the dates that belong to either the shortest or longest streak
    SELECT g.dt
    FROM   grp      AS g
    JOIN   streaks  AS s USING (grp)
    JOIN   limits   AS l ON s.len IN (l.shortest , l.longest)
),
sample_city AS (
    -- pick exactly ONE city for every selected date (alphabetically-first)
    SELECT DATE(insert_date)               AS dt ,
           MIN(LOWER(city_name))           AS city_name
    FROM   cities
    WHERE  country_code_2 = 'cn'
      AND  DATE(insert_date) IN (SELECT dt FROM target_dates)
    GROUP  BY dt
)
SELECT dt                                          AS date ,
       UPPER(SUBSTR(city_name,1,1)) ||
       LOWER(SUBSTR(city_name,2))                  AS city
FROM   sample_city
ORDER  BY dt;