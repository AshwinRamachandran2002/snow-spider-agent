WITH jan_cities AS (        -- all rows inserted during January-2022
    SELECT *
    FROM   cities
    WHERE  insert_date BETWEEN '2022-01-01' AND '2022-01-31'
),
/* 1. Country that has data on exactly NINE different January-2022 days */
country_nine AS (
    SELECT country_code_2
    FROM   jan_cities
    GROUP  BY country_code_2
    HAVING COUNT(DISTINCT insert_date) = 9
),
/* 2. Distinct insertion dates for that country */
country_dates AS (
    SELECT DISTINCT DATE(insert_date) AS d
    FROM   jan_cities
    WHERE  country_code_2 = (SELECT country_code_2 FROM country_nine)
),
/* 3. Build consecutive-day groups */
numbered AS (
    SELECT d,
           julianday(d) - ROW_NUMBER() OVER (ORDER BY d) AS grp
    FROM   country_dates
),
streaks AS (
    SELECT MIN(d) AS start_date,
           MAX(d) AS end_date,
           COUNT(*) AS day_len
    FROM   numbered
    GROUP  BY grp
),
/* 4. Longest consecutive insertion period */
longest AS (
    SELECT *
    FROM   streaks
    ORDER  BY day_len DESC, start_date
    LIMIT  1
)
/* 5. Rows & capital-city share within that longest period */
SELECT COUNT(*)                                                        AS total_rows,
       SUM(CASE WHEN c.capital = 1 THEN 1 ELSE 0 END)                 AS capital_rows,
       ROUND(1.0 * SUM(CASE WHEN c.capital = 1 THEN 1 ELSE 0 END)
             / COUNT(*), 4)                                           AS capital_ratio
FROM   cities  AS c
JOIN   country_nine AS cn   ON c.country_code_2 = cn.country_code_2
JOIN   longest      AS l    ON DATE(c.insert_date) BETWEEN l.start_date AND l.end_date;