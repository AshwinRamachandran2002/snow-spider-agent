/*  Percentage-point decrease in 2021 (vs. 2011) for the
    primary-collision-factor (PCF) violation category that was
    most common in 2021                                          */

WITH collisions_yr AS (          -- keep only 2011 & 2021 records
    SELECT 
        SUBSTR("collision_date",1,4)        AS "year",
        "pcf_violation_category"
    FROM "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."COLLISIONS"
    WHERE "collision_date" IS NOT NULL
      AND SUBSTR("collision_date",1,4) IN ('2011','2021')
),
cnts AS (                        -- crash counts per (year, PCF)
    SELECT 
        "year",
        "pcf_violation_category",
        COUNT(*)                  AS "cnt"
    FROM collisions_yr
    GROUP BY "year","pcf_violation_category"
),
totals AS (                      -- total crashes per year
    SELECT "year", SUM("cnt")    AS "total_cnt"
    FROM   cnts
    GROUP  BY "year"
),
shares AS (                      -- share (%) per (year, PCF)
    SELECT 
        c."year",
        c."pcf_violation_category",
        100.0 * c."cnt" / t."total_cnt"  AS "share_pct"
    FROM   cnts   c
    JOIN   totals t  USING("year")
),
top_2021 AS (                    -- most frequent PCF category in 2021
    SELECT "pcf_violation_category"
    FROM   cnts
    WHERE  "year" = '2021'
    ORDER  BY "cnt" DESC NULLS LAST
    LIMIT 1
)
SELECT
    s11."pcf_violation_category"                              AS "pcf_category",
    ROUND(s11."share_pct",4)                                  AS "share_2011_pct",
    ROUND(s21."share_pct",4)                                  AS "share_2021_pct",
    ROUND(s11."share_pct" - s21."share_pct",4)                AS "pct_point_decrease_2021_vs_2011"
FROM   shares s11
JOIN   shares s21
       ON s11."pcf_violation_category" = s21."pcf_violation_category"
JOIN   top_2021 t
       ON s11."pcf_violation_category" = t."pcf_violation_category"
WHERE  s11."year" = '2011'
  AND  s21."year" = '2021';