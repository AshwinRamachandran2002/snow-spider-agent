WITH cn_dates AS (
    /* 1.  All distinct July‑2021 dates for Chinese cities                       */
    SELECT DISTINCT DATE("insert_date") AS "date"
    FROM   "cities"
    WHERE  "country_code_2" = 'cn'
      AND  "insert_date" BETWEEN '2021-07-01' AND '2021-07-31'
),
seq AS (
    /* 2.  Attach a running row number so we can detect consecutive streaks      */
    SELECT  "date",
            ROW_NUMBER() OVER (ORDER BY "date")          AS "rn",
            JULIANDAY("date")                            AS "jd"
    FROM    cn_dates
),
streaks AS (
    /* 3.  Consecutive dates share the same (jd‑rn) value → streak identifier    */
    SELECT  "date",
            "jd" - "rn"  AS "grp"
    FROM    seq
),
streak_len AS (
    /* 4.  How long is every streak?                                             */
    SELECT  "grp",
            COUNT(*)    AS "len"
    FROM    streaks
    GROUP BY "grp"
),
limits AS (
    /* 5.  Shortest and longest streak lengths                                   */
    SELECT  MIN("len") AS "min_len",
            MAX("len") AS "max_len"
    FROM    streak_len
),
target_groups AS (
    /* 6.  Which streak(s) are the shortest  OR  the longest?                    */
    SELECT  "grp"
    FROM    streak_len, limits
    WHERE   "len" = "min_len"
       OR   "len" = "max_len"
),
target_dates AS (
    /* 7.  All dates belonging to those target streak groups                     */
    SELECT  s."date"
    FROM    streaks s
    JOIN    target_groups g
           ON s."grp" = g."grp"
),
one_city_per_date AS (
    /* 8.  Pick exactly one city per date (alphabetically first)                 */
    SELECT  DATE(c."insert_date")            AS "date",
            MIN(LOWER(c."city_name"))        AS "city_name_raw"
    FROM    "cities"        c
    JOIN    target_dates    d
           ON DATE(c."insert_date") = d."date"
    WHERE   c."country_code_2" = 'cn'
    GROUP BY DATE(c."insert_date")
)
/* 9.  Final formatted result                                                    */
SELECT  "date",
        UPPER(SUBSTR("city_name_raw",1,1))
        || LOWER(SUBSTR("city_name_raw",2))  AS "city_name"
FROM    one_city_per_date
ORDER BY "date";