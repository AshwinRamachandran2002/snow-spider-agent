WITH dates AS (
    -- keep one record per country & day for June 2022
    SELECT DISTINCT
           country_code_2,
           DATE(insert_date) AS insert_date
    FROM cities
    WHERE insert_date >= '2022-06-01'
      AND insert_date <  '2022-07-01'
),
ordered AS (
    -- give each country's dates a sequential number
    SELECT  country_code_2,
            insert_date,
            ROW_NUMBER() OVER (PARTITION BY country_code_2
                               ORDER BY insert_date) AS rn
    FROM dates
),
streak_groups AS (
    -- identical (julianday – rn) means the dates are consecutive
    SELECT  country_code_2,
            julianday(insert_date) - rn AS grp_id,
            COUNT(*)                  AS streak_len
    FROM ordered
    GROUP BY country_code_2, grp_id
),
country_max AS (
    -- longest streak length per country
    SELECT  country_code_2,
            MAX(streak_len) AS max_streak
    FROM streak_groups
    GROUP BY country_code_2
),
overall_max AS (
    SELECT MAX(max_streak) AS longest_streak
    FROM country_max
)
-- countries whose longest streak equals the overall longest
SELECT cm.country_code_2
FROM   country_max  cm
JOIN   overall_max  om  ON cm.max_streak = om.longest_streak
ORDER BY cm.country_code_2;