WITH nine_day_country AS (          -- 1. country that has 9 distinct January-2022 insert days
    SELECT country_code_2
    FROM   cities
    WHERE  insert_date BETWEEN '2022-01-01' AND '2022-01-31'
    GROUP  BY country_code_2
    HAVING COUNT( DISTINCT insert_date ) = 9
    LIMIT 1
),
distinct_dates AS (                -- 2. every distinct insertion date for that country in Jan-2022
    SELECT DISTINCT
           insert_date,
           ROW_NUMBER() OVER (ORDER BY insert_date) AS rn,
           julianday(insert_date)                   AS jd
    FROM   cities
    WHERE  country_code_2 = (SELECT country_code_2 FROM nine_day_country)
      AND  insert_date BETWEEN '2022-01-01' AND '2022-01-31'
),
grp_dates AS (                     -- 3. build keys to spot consecutive-day blocks
    SELECT insert_date,
           rn - jd AS grp_key
    FROM   distinct_dates
),
longest_run AS (                   -- 4. pick the longest consecutive block
    SELECT MIN(insert_date) AS start_d,
           MAX(insert_date) AS end_d
    FROM   grp_dates
    GROUP  BY grp_key
    ORDER  BY COUNT(*) DESC, start_d
    LIMIT 1
),
capital_ratio AS (                 -- 5. rows, capital rows, proportion inside longest block
    SELECT
        SUM(CASE WHEN c.capital = 1 THEN 1 ELSE 0 END) AS capital_rows,
        COUNT(*)                                       AS total_rows
    FROM   cities c
    CROSS  JOIN longest_run l
    WHERE  c.country_code_2 = (SELECT country_code_2 FROM nine_day_country)
      AND  c.insert_date BETWEEN l.start_d AND l.end_d
)
SELECT  cc.country_name,
        cr.capital_rows,
        cr.total_rows,
        ROUND(1.0 * cr.capital_rows / cr.total_rows, 3) AS capital_proportion
FROM    cities_countries  cc
JOIN    nine_day_country  nc  ON cc.country_code_2 = nc.country_code_2
CROSS   JOIN capital_ratio cr;