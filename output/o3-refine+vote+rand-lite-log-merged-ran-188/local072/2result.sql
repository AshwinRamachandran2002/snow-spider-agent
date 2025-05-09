WITH jan22 AS (               -- keep only January-2022 rows
    SELECT *
    FROM   cities
    WHERE  insert_date BETWEEN '2022-01-01' AND '2022-01-31'
),

-- 1. country that has data on exactly nine different January-2022 days
country_9_days AS (
    SELECT country_code_2
    FROM   jan22
    GROUP  BY country_code_2
    HAVING COUNT(DISTINCT insert_date) = 9
),

-- 2. partition that country’s January-2022 dates into consecutive-day blocks
consec_dates AS (
    SELECT  d.country_code_2,
            d.insert_date,
            JULIANDAY(d.insert_date) 
            - ROW_NUMBER() OVER (ORDER BY d.insert_date)           AS grp_key
    FROM   (
            SELECT DISTINCT insert_date, country_code_2
            FROM   jan22
            WHERE  country_code_2 IN (SELECT country_code_2 FROM country_9_days)
          ) AS d
),

-- 3. derive each consecutive-day period’s start, end, and size
periods AS (
    SELECT  country_code_2,
            grp_key,
            MIN(insert_date) AS start_date,
            MAX(insert_date) AS end_date,
            COUNT(*)         AS num_days
    FROM    consec_dates
    GROUP BY country_code_2, grp_key
),

-- 4. keep the single longest consecutive period
longest AS (
    SELECT *
    FROM   periods
    ORDER  BY num_days DESC
    LIMIT  1
),

-- 5. calculate capital-city proportion within that longest window
result AS (
    SELECT  l.country_code_2                AS country,
            l.start_date,
            l.end_date,
            l.num_days,
            COUNT(*)                        AS total_rows,
            SUM(CASE WHEN capital = 1 THEN 1 ELSE 0 END) AS capital_rows,
            ROUND(
                1.0 * SUM(CASE WHEN capital = 1 THEN 1 ELSE 0 END) / COUNT(*),
                3
            )                               AS capital_ratio
    FROM   cities  c
    JOIN   longest l
           ON  c.country_code_2 = l.country_code_2
           AND c.insert_date   BETWEEN l.start_date AND l.end_date
    GROUP  BY l.country_code_2, l.start_date, l.end_date, l.num_days
)

SELECT *
FROM   result;