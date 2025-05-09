WITH year_tagged AS (                 -- tag each crash with calendar year
    SELECT
        CAST(substr("collision_date", 1, 4) AS INTEGER) AS yr,
        "pcf_violation_category"
    FROM   "collisions"
    WHERE  substr("collision_date", 1, 4) IN ('2011', '2021')
),
top_2021 AS (                         -- most common PCF category in 2021
    SELECT "pcf_violation_category" AS target_cat
    FROM   year_tagged
    WHERE  yr = 2021
    GROUP  BY "pcf_violation_category"
    ORDER  BY COUNT(*) DESC
    LIMIT 1
),
counts AS (                           -- crashes & target-category crashes by year
    SELECT
        yt.yr,
        COUNT(*)                                                        AS total_crashes,
        SUM(CASE WHEN yt."pcf_violation_category" = t.target_cat
                 THEN 1 ELSE 0 END)                                     AS target_crashes
    FROM year_tagged AS yt
    CROSS JOIN top_2021  AS t
    GROUP BY yt.yr
)
SELECT
    ROUND(
        100.0 * MAX(CASE WHEN yr = 2011 THEN target_crashes END) /
               MAX(CASE WHEN yr = 2011 THEN total_crashes  END)
      - 100.0 * MAX(CASE WHEN yr = 2021 THEN target_crashes END) /
               MAX(CASE WHEN yr = 2021 THEN total_crashes  END)
    , 4) AS "percentage_point_decrease"
FROM counts;