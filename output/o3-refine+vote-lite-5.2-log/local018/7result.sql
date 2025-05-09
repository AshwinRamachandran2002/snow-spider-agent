WITH collisions_year AS (
    SELECT 
        c.pcf_violation_category AS category,
        ci.db_year AS year
    FROM collisions AS c
    JOIN case_ids AS ci
        ON ci.case_id = c.case_id
    WHERE ci.db_year IN (2011, 2021)
),
year_totals AS (
    SELECT 
        year,
        COUNT(*) AS total_collisions
    FROM collisions_year
    GROUP BY year
),
category_counts AS (
    SELECT
        category,
        year,
        COUNT(*) AS cat_count
    FROM collisions_year
    GROUP BY category, year
),
top_category_2021 AS (           -- most common category in 2021
    SELECT 
        category
    FROM category_counts
    WHERE year = 2021
    ORDER BY cat_count DESC, category
    LIMIT 1
),
shares AS (                      -- percentage share of that category in each year
    SELECT 
        cc.year,
        100.0 * cc.cat_count / yt.total_collisions AS share
    FROM category_counts AS cc
    JOIN year_totals     AS yt  ON yt.year = cc.year
    JOIN top_category_2021 AS tc ON tc.category = cc.category
)
SELECT 
    ROUND( COALESCE((SELECT share FROM shares WHERE year = 2011),0)
         - COALESCE((SELECT share FROM shares WHERE year = 2021),0), 4) 
    AS percentage_point_decrease;