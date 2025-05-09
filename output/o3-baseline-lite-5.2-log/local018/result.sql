WITH year_data AS (
    SELECT c.case_id,
           ci.db_year,
           c."pcf_violation_category"
    FROM collisions AS c
    JOIN case_ids  AS ci
      ON ci.case_id = c.case_id
),
top_cat AS (          -- most common PCF violation category in 2021
    SELECT "pcf_violation_category" AS category
    FROM   year_data
    WHERE  db_year = 2021
    GROUP BY "pcf_violation_category"
    ORDER BY COUNT(*) DESC
    LIMIT 1
),
stats AS (            -- counts and shares for 2011 and 2021 for that category
    SELECT yd.db_year,
           SUM(CASE WHEN yd."pcf_violation_category" = tc.category THEN 1 ELSE 0 END) AS cat_cnt,
           COUNT(*) AS total_cnt
    FROM   year_data AS yd
    CROSS JOIN top_cat AS tc
    WHERE  yd.db_year IN (2011, 2021)
    GROUP BY yd.db_year
)
SELECT ROUND(        -- decrease in percentage points
       (MAX(CASE WHEN db_year = 2011 THEN cat_cnt * 100.0 / total_cnt END) -
        MAX(CASE WHEN db_year = 2021 THEN cat_cnt * 100.0 / total_cnt END)
       ), 4) AS percentage_point_decrease
FROM   stats;