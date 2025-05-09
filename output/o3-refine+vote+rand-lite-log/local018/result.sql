WITH year_data AS (
    SELECT 
        ci.db_year AS year,
        c.pcf_violation_category
    FROM collisions AS c
    JOIN case_ids  AS ci ON c.case_id = ci.case_id
    WHERE ci.db_year IN (2011, 2021)
),
year_totals AS (
    SELECT 
        year,
        COUNT(*) AS total_collisions
    FROM year_data
    GROUP BY year
),
top_cat AS (                -- most common violation category in 2021
    SELECT 
        pcf_violation_category
    FROM year_data
    WHERE year = 2021
      AND pcf_violation_category IS NOT NULL
    GROUP BY pcf_violation_category
    ORDER BY COUNT(*) DESC
    LIMIT 1
),
cat_counts AS (             -- counts of that category in 2011 & 2021
    SELECT 
        yd.year,
        COUNT(*) AS cat_collisions
    FROM year_data AS yd
    JOIN top_cat  AS tc 
         ON yd.pcf_violation_category = tc.pcf_violation_category
    GROUP BY yd.year
)
SELECT
    ROUND(
        (COALESCE((SELECT cat_collisions FROM cat_counts WHERE year = 2011),0)*100.0 /
         (SELECT total_collisions   FROM year_totals WHERE year = 2011))
        -
        (COALESCE((SELECT cat_collisions FROM cat_counts WHERE year = 2021),0)*100.0 /
         (SELECT total_collisions   FROM year_totals WHERE year = 2021))
    , 4)  AS percentage_point_decrease;