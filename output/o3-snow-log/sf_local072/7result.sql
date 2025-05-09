/*  1. find the country that has rows recorded on exactly nine
        different days in January-2022 in the CITIES table
    2. inside that country’s January-2022 data determine the
        longest streak of consecutive insert-dates
    3. within that streak compute the share of rows that are
        the capital city (capital = 1)                                           */

WITH jan_cities AS (   -- all January-2022 rows
    SELECT  "country_code_2",
            "capital",
            TO_DATE("insert_date")        AS insert_dt
    FROM    CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE   "insert_date" BETWEEN '2022-01-01' AND '2022-01-31'
),

country_with_9_days AS (         -- country that appears on 9 distinct days
    SELECT  "country_code_2"
    FROM    jan_cities
    GROUP BY 1
    HAVING COUNT(DISTINCT insert_dt) = 9
),

target_rows AS (      -- keep only that country’s rows
    SELECT  jc.*
    FROM    jan_cities jc
    JOIN    country_with_9_days c
           ON jc."country_code_2" = c."country_code_2"
),

-- find consecutive-day groups ----------------------------------------------
distinct_days AS (
    SELECT DISTINCT insert_dt
    FROM   target_rows
),
ordered_days AS (
    SELECT  insert_dt,
            ROW_NUMBER() OVER(ORDER BY insert_dt)                       AS rn,
            DATEADD(day, -ROW_NUMBER() OVER(ORDER BY insert_dt), insert_dt) AS grp_key
    FROM    distinct_days
),
streaks AS (
    SELECT  MIN(insert_dt)  AS start_date,
            MAX(insert_dt)  AS end_date,
            COUNT(*)        AS streak_len
    FROM    ordered_days
    GROUP BY grp_key
),
longest_streak AS (
    SELECT *
    FROM   streaks
    ORDER BY streak_len DESC, start_date
    LIMIT 1
),

-- aggregate rows that fall inside the longest streak ------------------------
agg AS (
    SELECT  tr."country_code_2",
            ls.start_date,
            ls.end_date,
            COUNT(*)                                           AS total_rows,
            SUM(CASE WHEN tr."capital" = 1 THEN 1 ELSE 0 END) AS capital_rows
    FROM    target_rows tr
    JOIN    longest_streak ls
           ON tr.insert_dt BETWEEN ls.start_date AND ls.end_date
    GROUP BY tr."country_code_2", ls.start_date, ls.end_date
)

SELECT  cc."country_name",
        a."country_code_2",
        a.start_date,
        a.end_date,
        a.capital_rows,
        a.total_rows,
        ROUND(a.capital_rows::FLOAT / a.total_rows, 4) AS proportion_capital
FROM    agg a
LEFT JOIN CITY_LEGISLATION.CITY_LEGISLATION.CITIES_COUNTRIES cc
       ON cc."country_code_2" = a."country_code_2";