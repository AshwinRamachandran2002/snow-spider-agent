WITH base AS (   -- keep only 2011 & 2021 crashes
    SELECT  "pcf_violation_category",
            SUBSTR("collision_date",1,4) AS yr
    FROM    "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."COLLISIONS"
    WHERE   "collision_date" LIKE '2011%' 
       OR   "collision_date" LIKE '2021%'
),
top_2021 AS (    -- most common 2021 violation category
    SELECT  "pcf_violation_category"
    FROM    base
    WHERE   yr = '2021'
    GROUP BY "pcf_violation_category"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),
shares AS (      -- crashes for that category in each year
    SELECT  b.yr,
            b."pcf_violation_category",
            COUNT(*) AS cnt
    FROM    base b
    JOIN    top_2021 t
           ON b."pcf_violation_category" = t."pcf_violation_category"
    GROUP BY b.yr, b."pcf_violation_category"
),
totals AS (      -- total crashes per year
    SELECT  yr,
            COUNT(*) AS tot_cnt
    FROM    base
    GROUP BY yr
),
pct AS (         -- percentage shares
    SELECT  s.yr,
            s."pcf_violation_category",
            s.cnt * 100.0 / t.tot_cnt AS share_pct
    FROM    shares s
    JOIN    totals t USING (yr)
)
SELECT  "pcf_violation_category",
        MAX(CASE WHEN yr = '2011' THEN share_pct END) AS share_2011_pct,
        MAX(CASE WHEN yr = '2021' THEN share_pct END) AS share_2021_pct,
        MAX(CASE WHEN yr = '2011' THEN share_pct END)
      - MAX(CASE WHEN yr = '2021' THEN share_pct END) AS percentage_point_decrease
FROM    pct
GROUP BY "pcf_violation_category";