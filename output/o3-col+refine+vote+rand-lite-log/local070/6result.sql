WITH cn_july AS (
    SELECT DATE("insert_date") AS dt,
           "city_name"
    FROM   "cities"
    WHERE  "country_code_2" = 'cn'
      AND  DATE("insert_date") BETWEEN '2021-07-01' AND '2021-07-31'
),
ordered_dates AS (
    SELECT DISTINCT
           dt,
           JULIANDAY(dt)                         AS jd,
           ROW_NUMBER() OVER (ORDER BY dt)       AS rn
    FROM   cn_july
),
streaks AS (
    SELECT (jd - rn) AS grp,
           COUNT(*)  AS len
    FROM   ordered_dates
    GROUP  BY grp
),
target_groups AS (
    SELECT grp
    FROM   streaks
    WHERE  len = (SELECT MIN(len) FROM streaks)
       OR  len = (SELECT MAX(len) FROM streaks)
),
target_dates AS (
    SELECT od.dt
    FROM   ordered_dates od
    JOIN   target_groups tg ON tg.grp = (od.jd - od.rn)
),
one_city_per_date AS (
    SELECT td.dt,
           MIN(cj.city_name) AS city_name
    FROM   target_dates td
    JOIN   cn_july cj ON cj.dt = td.dt
    GROUP  BY td.dt
)
SELECT dt   AS "date",
       SUBSTR(UPPER(city_name),1,1) || LOWER(SUBSTR(city_name,2)) AS "city_name"
FROM   one_city_per_date
ORDER  BY dt;