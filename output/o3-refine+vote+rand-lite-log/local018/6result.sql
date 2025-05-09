WITH year_counts AS (
    SELECT 
        ci.db_year AS year,
        c."pcf_violation_category" AS category,
        COUNT(*) AS cnt
    FROM collisions AS c
    JOIN case_ids AS ci
        ON ci.case_id = c.case_id
    WHERE ci.db_year IN (2011, 2021)
          AND c."pcf_violation_category" IS NOT NULL
    GROUP BY ci.db_year, c."pcf_violation_category"
),
total_per_year AS (
    SELECT year, SUM(cnt) AS total_cnt
    FROM year_counts
    GROUP BY year
),
shares AS (
    SELECT 
        y.year,
        y.category,
        1.0 * y.cnt / t.total_cnt AS share
    FROM year_counts AS y
    JOIN total_per_year AS t
        ON t.year = y.year
),
top_cat_2021 AS (
    SELECT category
    FROM shares
    WHERE year = 2021
    ORDER BY share DESC
    LIMIT 1
)
SELECT 
    ROUND(
        100.0 * (
            (SELECT share FROM shares 
             WHERE year = 2011 
               AND category = (SELECT category FROM top_cat_2021))
          -
            (SELECT share FROM shares 
             WHERE year = 2021 
               AND category = (SELECT category FROM top_cat_2021))
        ), 4
    ) AS percentage_point_decrease;