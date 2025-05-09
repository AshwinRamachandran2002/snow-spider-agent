WITH filtered AS (
    SELECT 
        CAST(substr(collision_date, 1, 4) AS INTEGER) AS year,
        pcf_violation_category                         AS category
    FROM collisions
    WHERE collision_date IS NOT NULL
      AND pcf_violation_category IS NOT NULL
      AND substr(collision_date, 1, 4) IN ('2011','2021')
),
year_totals AS (
    SELECT year, COUNT(*) AS total
    FROM filtered
    GROUP BY year
),
cat_counts AS (
    SELECT year, category, COUNT(*) AS cnt
    FROM filtered
    GROUP BY year, category
),
top_cat AS (               -- most common category in 2021
    SELECT category
    FROM cat_counts
    WHERE year = 2021
    ORDER BY cnt DESC
    LIMIT 1
),
shares AS (                -- percentage share of that category in each year
    SELECT 
        cc.year,
        cc.category,
        100.0 * cc.cnt / yt.total AS pct
    FROM cat_counts cc
    JOIN year_totals yt ON yt.year = cc.year
    JOIN top_cat tc     ON tc.category = cc.category
)
SELECT
    (SELECT category FROM top_cat) AS violation_category,
    ROUND(
        (SELECT pct FROM shares WHERE year = 2011) -
        (SELECT pct FROM shares WHERE year = 2021),
        4
    ) AS percentage_point_decrease;