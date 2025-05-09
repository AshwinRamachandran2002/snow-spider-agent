WITH cn_july AS (
    /* 1.  Chinese cities whose records were inserted in July-2021 */
    SELECT  "city_id",
            "city_name",
            TO_DATE("insert_date")  AS insert_dt
    FROM    CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE   "country_code_2" = 'cn'
      AND   TO_DATE("insert_date") BETWEEN '2021-07-01' AND '2021-07-31'
), 

/* 2.  Calendar of all distinct dates for those records                */
all_dates AS (
    SELECT DISTINCT insert_dt
    FROM   cn_july
),

/* 3.  Build a sequence number, then a group key that is constant
        inside each run of consecutive days                            */
seq AS (
    SELECT  insert_dt,
            ROW_NUMBER() OVER (ORDER BY insert_dt)                    AS rn,
            DATEADD(day, -ROW_NUMBER() OVER (ORDER BY insert_dt), 
                    insert_dt)                                        AS grp_key
    FROM    all_dates
),

/* 4.  Derive streak lengths                                           */
streaks AS (
    SELECT  grp_key,
            COUNT(*)      AS streak_len
    FROM    seq
    GROUP BY grp_key
),

/* 5.  Find the minimum- and maximum-length streaks                    */
limits AS (
    SELECT  MIN(streak_len) AS min_len,
            MAX(streak_len) AS max_len
    FROM    streaks
),

/* 6.  Keep the group keys that correspond to those two streaks        */
picked_keys AS (
    SELECT  grp_key
    FROM    streaks   s
    JOIN    limits    l
      ON    s.streak_len = l.min_len
      OR    s.streak_len = l.max_len
),

/* 7.  Dates that belong to the chosen streaks                         */
picked_dates AS (
    SELECT  insert_dt
    FROM    seq
    WHERE   grp_key IN (SELECT grp_key FROM picked_keys)
),

/* 8.  For every date return exactly one city (alphabetically first)   */
one_city_per_date AS (
    SELECT  d.insert_dt,
            INITCAP(MIN(c."city_name")) AS city_cased
    FROM    picked_dates d
    JOIN    cn_july     c
      ON    c.insert_dt = d.insert_dt
    GROUP BY d.insert_dt
)

/* 9.  Final ordered output                                            */
SELECT  TO_CHAR(insert_dt, 'YYYY-MM-DD')  AS "date",
        city_cased                       AS "city_name"
FROM    one_city_per_date
ORDER BY insert_dt;