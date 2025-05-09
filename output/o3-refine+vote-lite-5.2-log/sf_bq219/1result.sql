WITH date_bounds AS (   -- analysis window
    SELECT 
        TO_DATE('2022-01-01')                               AS start_date ,
        DATEADD(day,-1 , DATE_TRUNC(month , CURRENT_DATE())) AS end_date   -- last fully–completed month
),
--------------------------------------------------------------------
-- 1.  Monthly litres per category (only inside the window)
base AS (
    SELECT 
        DATE_TRUNC('month', "date")                  AS month ,
        "category_name"                              AS category_name ,
        SUM("volume_sold_liters")                    AS cat_litres
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES s
    JOIN date_bounds b
          ON s."date" BETWEEN b.start_date AND b.end_date
    GROUP BY month , category_name
),
--------------------------------------------------------------------
-- 2.  Total litres each month
monthly_totals AS (
    SELECT month,
           SUM(cat_litres) AS tot_litres
    FROM base
    GROUP BY month
),
--------------------------------------------------------------------
-- 3.  Category share (ratio 0‑1) each month
monthly_pct AS (
    SELECT 
        b.month ,
        b.category_name ,
        b.cat_litres / t.tot_litres  AS pct
    FROM base b
    JOIN monthly_totals t USING (month)
),
--------------------------------------------------------------------
-- 4.  Complete grid of months × categories (fill 0 when absent)
months_list  AS (SELECT DISTINCT month FROM monthly_totals),
cats_list    AS (SELECT DISTINCT category_name FROM monthly_pct),
cat_monthly_filled AS (
    SELECT 
        m.month ,
        c.category_name ,
        COALESCE(mp.pct , 0)::FLOAT  AS pct        -- zero if no sales that month
    FROM months_list m
    CROSS JOIN cats_list c
    LEFT JOIN monthly_pct mp
           ON mp.month = m.month
          AND mp.category_name = c.category_name
),
--------------------------------------------------------------------
-- 5.  Keep categories averaging ≥1 % and present in ≥24 months
eligible_cats AS (
    SELECT 
        category_name ,
        AVG(pct)                                            AS avg_pct ,
        COUNT_IF(pct IS NOT NULL)                           AS months_present
    FROM cat_monthly_filled
    GROUP BY category_name
    HAVING avg_pct >= 0.01
       AND months_present >= 24
),
filtered AS (
    SELECT f.*
    FROM cat_monthly_filled f
    JOIN eligible_cats  e USING (category_name)
),
--------------------------------------------------------------------
-- 6.  Pairwise correlation of monthly percentages
pair_data AS (
    SELECT 
        a.month ,
        a.category_name              AS cat1 ,
        b.category_name              AS cat2 ,
        a.pct                        AS pct1 ,
        b.pct                        AS pct2
    FROM filtered a
    JOIN filtered b
         ON a.month = b.month
        AND a.category_name < b.category_name          -- unique unordered pairs
),
pair_corr AS (
    SELECT 
        cat1 ,
        cat2 ,
        CORR(pct1 , pct2) AS corr_coef
    FROM pair_data
    GROUP BY cat1 , cat2
),
--------------------------------------------------------------------
-- 7.  Lowest correlation pair
min_pair AS (
    SELECT *
    FROM pair_corr
    QUALIFY corr_coef = MIN(corr_coef) OVER ()
)
--------------------------------------------------------------------
SELECT 
       cat1 AS category_name_1 ,
       cat2 AS category_name_2
FROM   min_pair;