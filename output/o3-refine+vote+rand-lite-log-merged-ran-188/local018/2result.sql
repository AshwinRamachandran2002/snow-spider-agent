WITH collisions_by_year AS (
    SELECT 
        c.case_id,
        c.pcf_violation_category,
        ci.db_year
    FROM collisions AS c
    JOIN case_ids  AS ci
         ON ci.case_id = c.case_id
    WHERE c.pcf_violation_category IS NOT NULL
),

-- 1. Most frequent violation category in 2021
top_category_2021 AS (
    SELECT pcf_violation_category AS category
    FROM   collisions_by_year
    WHERE  db_year = 2021
    GROUP  BY pcf_violation_category
    ORDER  BY COUNT(*) DESC, pcf_violation_category
    LIMIT 1
),

-- 2. Counts needed for 2011 and 2021
counts AS (
    SELECT
        SUM(CASE WHEN db_year = 2021 THEN 1 END)                                             AS total_2021,
        SUM(CASE WHEN db_year = 2021 
                 AND pcf_violation_category = tc.category THEN 1 END)                        AS cat_2021,
        SUM(CASE WHEN db_year = 2011 THEN 1 END)                                             AS total_2011,
        SUM(CASE WHEN db_year = 2011 
                 AND pcf_violation_category = tc.category THEN 1 END)                        AS cat_2011
    FROM collisions_by_year
    CROSS JOIN top_category_2021 AS tc
)

-- 3. Percentage‑point decrease from 2011 to 2021
SELECT 
    ROUND(
        (cat_2011 * 1.0 / total_2011 - cat_2021 * 1.0 / total_2021) * 100.0,
        4
    ) AS percentage_point_decrease
FROM counts;