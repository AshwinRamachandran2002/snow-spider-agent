WITH date_bounds AS (
    -- analysis period: 1 Jan 2022  →  last day of the last fully‑completed month
    SELECT 
        DATE '2022-01-01'           AS start_dt ,
        DATEADD(
            day , -1 , 
            DATE_TRUNC(month , CURRENT_DATE)    -- first day of current month
        )                            AS end_dt
),

-- 1. monthly litres per category
month_cat_vol AS (
    SELECT 
        DATE_TRUNC(month , "date")          AS month_start ,
        "category_name"                     AS category_name ,
        SUM("volume_sold_liters")           AS litres
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES  s
    JOIN date_bounds                           db
      ON s."date" BETWEEN db.start_dt AND db.end_dt
    GROUP BY 1 , 2
),

-- 2. total litres per month
month_tot AS (
    SELECT 
        month_start ,
        SUM(litres) AS tot_litres
    FROM month_cat_vol
    GROUP BY 1
),

-- 3. percentage of monthly total for each category
month_cat_pct AS (
    SELECT
        mcv.month_start ,
        mcv.category_name ,
        mcv.litres / mt.tot_litres            AS pct_of_month
    FROM month_cat_vol  mcv
    JOIN month_tot      mt
      ON mcv.month_start = mt.month_start
),

-- 4. keep categories that (a) appear ≥24 months and (b) avg ≥1 % of monthly volume
eligible_cats AS (
    SELECT 
        category_name
    FROM month_cat_pct
    GROUP BY category_name
    HAVING COUNT(*) >= 24
       AND AVG(pct_of_month) >= 0.01      -- 1 % expressed as proportion
),

-- 5. percentages only for eligible categories
ec_pct AS (
    SELECT mcp.*
    FROM   month_cat_pct  mcp
    JOIN   eligible_cats  ec
      ON   mcp.category_name = ec.category_name
),

-- 6. pair‑wise Pearson correlations between category percentage time‑series
pair_corr AS (
    SELECT
        a.category_name        AS cat1 ,
        b.category_name        AS cat2 ,
        CORR(a.pct_of_month , b.pct_of_month) AS corr_coeff
    FROM ec_pct  a
    JOIN ec_pct  b
      ON  a.month_start   = b.month_start
     AND  a.category_name < b.category_name      -- canonical ordering, avoids duplicates & self‑join
    GROUP BY cat1 , cat2
),

-- 7. the pair with the lowest correlation coefficient
lowest_corr_pair AS (
    SELECT  cat1 , cat2
    FROM    pair_corr
    QUALIFY corr_coeff = MIN(corr_coeff) OVER ()
)

SELECT cat1 AS category_name_1 ,
       cat2 AS category_name_2
FROM   lowest_corr_pair
LIMIT 1;