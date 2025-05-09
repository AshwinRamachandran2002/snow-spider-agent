WITH
-- boundaries of the analysis window
params AS (
    SELECT 
        TO_DATE('2022-01-01')                                             AS start_date ,
        DATEADD(month , -1 , DATE_TRUNC('month', CURRENT_DATE()))         AS end_month_firstday
),
-- generate one row per month between start-date and last completed month
months AS (
    SELECT DATEADD(month, g.seq, p.start_date) AS month_start
    FROM   params p
    JOIN   (SELECT SEQ4() AS seq 
            FROM TABLE(GENERATOR(ROWCOUNT => 100))) g                    -- 100 months is more than enough
      ON   DATEADD(month, g.seq, p.start_date) <= p.end_month_firstday
),
-- total liters sold (all categories) each month
total_month AS (
    SELECT  m.month_start ,
            SUM(COALESCE(s."volume_sold_liters",0)) AS total_liters
    FROM    months                                     m
    LEFT JOIN IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES."SALES" s
           ON DATE_TRUNC('month', s."date") = m.month_start
    GROUP BY m.month_start
),
-- liters sold per category per month
raw_cat_month AS (
    SELECT  s."category_name" ,
            DATE_TRUNC('month', s."date")       AS month_start ,
            SUM(s."volume_sold_liters")         AS cat_liters
    FROM    IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES."SALES" s
    WHERE   s."date" >= '2022-01-01'
      AND   s."date" <  DATE_TRUNC('month', CURRENT_DATE())  -- exclude current partial month
      AND   s."category_name" IS NOT NULL
    GROUP BY s."category_name" , DATE_TRUNC('month', s."date")
),
-- percentage share of each category every month (fill 0 when no sales that month)
cat_pct AS (
    SELECT  c."category_name" ,
            m.month_start ,
            CASE WHEN tm.total_liters = 0 THEN 0
                 ELSE COALESCE(rcm.cat_liters , 0) / tm.total_liters
            END                                              AS pct
    FROM  (SELECT DISTINCT "category_name" FROM raw_cat_month) c
          CROSS JOIN months m
          JOIN  total_month          tm  ON tm.month_start     = m.month_start
          LEFT JOIN raw_cat_month   rcm  ON rcm."category_name" = c."category_name"
                                        AND rcm.month_start     = m.month_start
),
-- keep categories averaging ≥1 % share and appearing in ≥24 months
qual_categories AS (
    SELECT  "category_name"
    FROM    cat_pct
    GROUP BY "category_name"
    HAVING  AVG(pct) >= 0.01
       AND  COUNT(*) >= 24
),
-- monthly percentage series for qualified categories
qualified_pct AS (
    SELECT cp.*
    FROM   cat_pct cp
    JOIN   qual_categories qc
      ON   cp."category_name" = qc."category_name"
),
-- pair-wise Pearson correlations between category share series
pair_corr AS (
    SELECT  q1."category_name"            AS cat1 ,
            q2."category_name"            AS cat2 ,
            CORR(q1.pct , q2.pct)         AS corr_val
    FROM    qualified_pct q1
    JOIN    qualified_pct q2
           ON q1.month_start   = q2.month_start
          AND q1."category_name" < q2."category_name"
    GROUP BY q1."category_name" , q2."category_name"
)
-- two categories with the lowest correlation in monthly share
SELECT  cat1 ,
        cat2
FROM    pair_corr
ORDER BY corr_val ASC NULLS LAST
LIMIT 1;