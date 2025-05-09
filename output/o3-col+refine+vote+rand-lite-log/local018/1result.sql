WITH year_category_counts AS (
    -- Crash counts per Primary Collision Factor (PCF) category for 2011 & 2021
    SELECT
        substr("collision_date", 1, 4)            AS yr,
        "pcf_violation_category"                  AS cat,
        COUNT(*)                                  AS cnt
    FROM   "collisions"
    WHERE  "collision_date" IS NOT NULL
      AND  substr("collision_date", 1, 4) IN ('2011','2021')
      AND  "pcf_violation_category" IS NOT NULL
      AND  "pcf_violation_category" <> ''
    GROUP BY yr, cat
),
year_totals AS (
    -- Total crashes for each of the two years
    SELECT
        substr("collision_date", 1, 4) AS yr,
        COUNT(*)                       AS total_cnt
    FROM   "collisions"
    WHERE  "collision_date" IS NOT NULL
      AND  substr("collision_date", 1, 4) IN ('2011','2021')
    GROUP BY yr
),
top_cat_2021 AS (
    -- Identify 2021’s most frequent PCF category
    SELECT cat
    FROM   year_category_counts
    WHERE  yr = '2021'
    ORDER BY cnt DESC
    LIMIT 1
)
-- Calculate the share in each year and the percentage-point decrease
SELECT
    t.cat                                         AS "pcf_violation_category",
    ROUND(100.0 * c21.cnt / y21.total_cnt, 2)     AS "share_2021(%)",
    ROUND(100.0 * c11.cnt / y11.total_cnt, 2)     AS "share_2011(%)",
    ROUND( (100.0 * c11.cnt / y11.total_cnt) -
           (100.0 * c21.cnt / y21.total_cnt), 2)  AS "percentage_point_decrease"
FROM   top_cat_2021 t
JOIN   year_category_counts c21 ON c21.cat = t.cat AND c21.yr = '2021'
JOIN   year_category_counts c11 ON c11.cat = t.cat AND c11.yr = '2011'
JOIN   year_totals y21          ON y21.yr         = '2021'
JOIN   year_totals y11          ON y11.yr         = '2011';