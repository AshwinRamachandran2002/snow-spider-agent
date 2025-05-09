WITH january_cities AS (
    /*  All rows inserted in January‑2022  */
    SELECT  c.city_id,
            c.city_name,
            c.capital,
            c.insert_date,
            c.country_code_2,
            cc.country_name
    FROM    cities            AS c
    JOIN    cities_countries  AS cc
           ON c.country_code_2 = cc.country_code_2
    WHERE   c.insert_date BETWEEN '2022-01-01' AND '2022-01-31'
),
/*  Country that has insertions on exactly nine different January‑2022 days  */
candidate_country AS (
    SELECT country_name
    FROM   january_cities
    GROUP  BY country_name
    HAVING COUNT(DISTINCT insert_date) = 9
    LIMIT  1
),
/*  Distinct insertion dates for that country  */
distinct_dates AS (
    SELECT DISTINCT insert_date
    FROM   january_cities
    WHERE  country_name = (SELECT country_name FROM candidate_country)
),
/*  Row number to help build consecutive‑day groups  */
ordered AS (
    SELECT insert_date,
           ROW_NUMBER() OVER (ORDER BY insert_date) AS rn
    FROM   distinct_dates
),
/*  Gap‑and‑islands technique: julian_day – rn is constant inside each streak  */
islands AS (
    SELECT insert_date,
           julianday(insert_date) - rn AS grp
    FROM   ordered
),
/*  Aggregate each consecutive streak  */
streaks AS (
    SELECT grp,
           MIN(insert_date) AS start_date,
           MAX(insert_date) AS end_date,
           COUNT(*)         AS days_in_streak
    FROM   islands
    GROUP  BY grp
),
/*  Longest consecutive streak (ties broken by earliest start) */
longest AS (
    SELECT *
    FROM   streaks
    ORDER  BY days_in_streak DESC, start_date
    LIMIT  1
),
/*  All city rows that fall within the longest streak  */
period_rows AS (
    SELECT jc.*
    FROM   january_cities jc
    JOIN   longest l
           ON jc.insert_date BETWEEN l.start_date AND l.end_date
    WHERE  jc.country_name = (SELECT country_name FROM candidate_country)
)
SELECT
       (SELECT country_name FROM candidate_country)             AS country_name,
       longest.start_date,
       longest.end_date,
       longest.days_in_streak                                   AS consecutive_days,
       ROUND( SUM(CASE WHEN period_rows.capital = 1 THEN 1 ELSE 0 END)
             *1.0 / COUNT(*)
            ,4)                                                 AS capital_proportion
FROM   period_rows
CROSS  JOIN longest;