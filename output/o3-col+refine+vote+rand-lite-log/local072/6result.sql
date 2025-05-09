WITH country_nine AS (          -- country that appears on exactly 9 different Jan-2022 days
    SELECT "country_code_2"
    FROM   "cities"
    WHERE  "insert_date" LIKE '2022-01%'
    GROUP  BY "country_code_2"
    HAVING COUNT(DISTINCT "insert_date") = 9
), jan_dates AS (               -- those 9 dates with helpers for streak detection
    SELECT DISTINCT
           "insert_date",
           "country_code_2",
           julianday("insert_date")                    AS jd,
           ROW_NUMBER() OVER (ORDER BY "insert_date")  AS rn
    FROM   "cities"
    WHERE  "country_code_2" IN (SELECT "country_code_2" FROM country_nine)
      AND  "insert_date"    LIKE '2022-01%'
), seq_groups AS (              -- constant (jd-rn) within any consecutive run
    SELECT *,
           jd - rn AS grp_key
    FROM   jan_dates
), longest AS (                 -- pick the longest consecutive-day streak
    SELECT  "country_code_2",
            MIN("insert_date") AS start_date,
            MAX("insert_date") AS end_date,
            COUNT(*)           AS consecutive_days
    FROM    seq_groups
    GROUP  BY "country_code_2", grp_key
    ORDER  BY consecutive_days DESC
    LIMIT 1
), window_rows AS (             -- every row that falls inside that streak
    SELECT c.*
    FROM   "cities" c
    JOIN   longest l
      ON   c."country_code_2" = l."country_code_2"
     AND   c."insert_date" BETWEEN l.start_date AND l.end_date
)
SELECT  l."country_code_2"                                                    AS country_code,
        l.start_date,
        l.end_date,
        l.consecutive_days,
        ROUND( SUM(CASE WHEN w."capital" = 1 THEN 1 ELSE 0 END) * 1.0
              / COUNT(*), 3)                                                  AS capital_city_share
FROM    longest      l
JOIN    window_rows  w  ON w."country_code_2" = l."country_code_2"
GROUP  BY l."country_code_2", l.start_date, l.end_date, l.consecutive_days;