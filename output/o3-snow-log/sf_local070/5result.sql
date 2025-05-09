/* 1) pull all chinese city rows inserted in July-2021                          */
WITH cn_july AS (
    SELECT DISTINCT 
           TO_DATE("insert_date") AS dt
    FROM   "CITY_LEGISLATION"."CITY_LEGISLATION"."CITIES"
    WHERE  "country_code_2" = 'cn'
      AND  TO_DATE("insert_date") BETWEEN '2021-07-01' AND '2021-07-31'
),

/* 2) number the dates and build a key that is constant within each
      block of consecutive days (date – row_number)                            */
dates_with_grp AS (
    SELECT  dt,
            ROW_NUMBER() OVER (ORDER BY dt)                                   AS rn,
            DATEDIFF('day', DATE '1970-01-01', dt) - 
            ROW_NUMBER() OVER (ORDER BY dt)                                   AS grp_id
    FROM    cn_july
),

/* 3) length of every consecutive-date streak                                  */
streaks AS (
    SELECT  grp_id,
            MIN(dt)                       AS start_dt,
            MAX(dt)                       AS end_dt,
            COUNT(*)                      AS len
    FROM    dates_with_grp
    GROUP BY grp_id
),

/* 4) locate shortest and longest streak lengths                               */
limits AS (
    SELECT  MIN(len) AS min_len,
            MAX(len) AS max_len
    FROM    streaks
),

/* 5) choose one (earliest) streak for each of shortest & longest lengths      */
picked_streaks AS (
    SELECT  s.grp_id
    FROM    streaks            s
    JOIN    limits             l  ON s.len IN (l.min_len, l.max_len)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY s.len ORDER BY s.start_dt) = 1
),

/* 6) every date that belongs to those two picked streaks                      */
chosen_dates AS (
    SELECT  dt
    FROM    dates_with_grp
    WHERE   grp_id IN (SELECT grp_id FROM picked_streaks)
),

/* 7) for each chosen date pick exactly one city (alphabetically first)        */
one_city_per_day AS (
    SELECT  cd.dt,
            INITCAP(c."city_name")                            AS city_name,
            ROW_NUMBER() OVER (PARTITION BY cd.dt 
                               ORDER BY c."city_name")        AS rn
    FROM    chosen_dates                 cd
    JOIN    "CITY_LEGISLATION"."CITY_LEGISLATION"."CITIES"  c
           ON  TO_DATE(c."insert_date") = cd.dt
           AND c."country_code_2" = 'cn'
)

SELECT  TO_CHAR(dt, 'YYYY-MM-DD')     AS "date",
        city_name
FROM    one_city_per_day
WHERE   rn = 1
ORDER BY dt;