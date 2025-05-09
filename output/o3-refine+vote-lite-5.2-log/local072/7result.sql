WITH jan_2022 AS (          -- all January‑2022 city records
    SELECT city_id,
           city_name,
           country_code_2,
           capital,
           DATE(insert_date)          AS d
    FROM   cities
    WHERE  insert_date BETWEEN '2022-01-01' AND '2022-01-31'
),
country_9_days AS (         -- country inserted on 9 different days
    SELECT country_code_2
    FROM   jan_2022
    GROUP  BY country_code_2
    HAVING COUNT(DISTINCT d) = 9
),
dated_rows AS (             -- distinct days for that country
    SELECT DISTINCT
           country_code_2,
           d,
           julianday(d) -
           ROW_NUMBER() OVER (PARTITION BY country_code_2 ORDER BY d) AS grp
    FROM   jan_2022
    WHERE  country_code_2 IN (SELECT country_code_2 FROM country_9_days)
),
streaks AS (                -- consecutive‑day streaks
    SELECT country_code_2,
           MIN(d) AS start_date,
           MAX(d) AS end_date,
           COUNT(*) AS len
    FROM   dated_rows
    GROUP  BY country_code_2, grp
),
longest AS (                -- longest consecutive period
    SELECT *
    FROM   streaks
    WHERE  len = (SELECT MAX(len) FROM streaks)
),
period_cities AS (          -- all city rows within that longest period
    SELECT c.*
    FROM   cities c
    JOIN   longest l
           ON c.country_code_2 = l.country_code_2
          AND DATE(c.insert_date) BETWEEN l.start_date AND l.end_date
)
SELECT  cc.country_name,
        l.start_date,
        l.end_date,
        COUNT(*)                                                   AS total_entries,
        SUM(CASE WHEN pc.capital = 1 THEN 1 ELSE 0 END)            AS capital_entries,
        1.0 * SUM(CASE WHEN pc.capital = 1 THEN 1 ELSE 0 END)
             / COUNT(*)                                            AS capital_proportion
FROM    period_cities pc
JOIN    longest l   ON pc.country_code_2 = l.country_code_2
JOIN    cities_countries cc ON cc.country_code_2 = pc.country_code_2
GROUP   BY cc.country_name, l.start_date, l.end_date;