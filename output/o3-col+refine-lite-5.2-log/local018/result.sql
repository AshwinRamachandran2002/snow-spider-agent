WITH yr_data AS (   -- collisions from 2011 and 2021 with their PCF‑violation category
    SELECT substr(collision_date,1,4) AS yr,
           pcf_violation_category     AS cat
    FROM   collisions
    WHERE  substr(collision_date,1,4) IN ('2011','2021')
),
top21 AS (          -- most common violation category in 2021
    SELECT cat
    FROM   yr_data
    WHERE  yr = '2021'
    GROUP  BY cat
    ORDER  BY COUNT(*) DESC
    LIMIT 1
),
counts AS (         -- counts for that category in both years
    SELECT
        SUM(CASE WHEN yr='2021' THEN 1 END) AS cnt_2021,
        SUM(CASE WHEN yr='2011' THEN 1 END) AS cnt_2011
    FROM   yr_data
    WHERE  cat = (SELECT cat FROM top21)
),
totals AS (         -- total collisions in each year
    SELECT
        SUM(CASE WHEN yr='2021' THEN 1 END) AS tot_2021,
        SUM(CASE WHEN yr='2011' THEN 1 END) AS tot_2011
    FROM   yr_data
)
SELECT ROUND(100.0*cnt_2011/tot_2011 - 100.0*cnt_2021/tot_2021, 2) 
       AS pct_point_decrease
FROM   counts, totals;