WITH jan2022 AS (     -- all city rows recorded in January‑2022
    SELECT  city_id,
            city_name,
            country_code_2,
            capital,
            DATE(insert_date) AS dt
    FROM    cities
    WHERE   strftime('%Y',insert_date)='2022'
      AND   strftime('%m',insert_date)='01'
),
country_with_9_days AS (          -- country that has rows on 9 distinct January dates
    SELECT  country_code_2
    FROM    jan2022
    GROUP BY country_code_2
    HAVING  COUNT(DISTINCT dt)=9
),
distinct_days AS (                -- the 9 distinct insertion dates for that country
    SELECT  DISTINCT dt
    FROM    jan2022
    WHERE   country_code_2 = (SELECT country_code_2 FROM country_with_9_days)
),
seq AS (                           -- give every date a grouping key so consecutive
    SELECT  dt,
            julianday(dt)-ROW_NUMBER() OVER(ORDER BY dt) AS grp
    FROM    distinct_days
),
streaks AS (                       -- each run of consecutive dates
    SELECT  grp,
            MIN(dt) AS start_date,
            MAX(dt) AS end_date,
            COUNT(*) AS len
    FROM    seq
    GROUP BY grp
),
longest_streak AS (                -- longest consecutive run
    SELECT  start_date,
            end_date
    FROM    streaks
    ORDER BY len DESC, start_date
    LIMIT 1
),
rows_in_longest AS (               -- all city rows that fall inside that run
    SELECT  *
    FROM    jan2022
    WHERE   country_code_2 = (SELECT country_code_2 FROM country_with_9_days)
      AND   dt BETWEEN (SELECT start_date FROM longest_streak)
                   AND (SELECT end_date   FROM longest_streak)
),
cnts AS (                          -- count rows & capital‑city rows
    SELECT  COUNT(*)             AS total_rows,
            SUM(capital)         AS capital_rows
    FROM    rows_in_longest
)
SELECT  cc.country_name                              AS country,
        (SELECT start_date FROM longest_streak)      AS longest_period_start,
        (SELECT end_date   FROM longest_streak)      AS longest_period_end,
        cnts.total_rows,
        cnts.capital_rows,
        ROUND(1.0*cnts.capital_rows/cnts.total_rows,4) AS capital_city_proportion
FROM    cnts
JOIN    cities_countries cc
       ON cc.country_code_2 = (SELECT country_code_2 FROM country_with_9_days);