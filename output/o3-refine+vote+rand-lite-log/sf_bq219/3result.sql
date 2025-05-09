/*  Two liquor categories (category_name) whose monthly share of total sales dollars
    from Jan‑2022 through the most recently finished month are
    both    – present in at least 24 months
    – average at least 1 % of monthly sales volume
    and whose monthly percentage series have the lowest Pearson correlation          */

WITH date_bounds AS (          -- analysis window
    SELECT
        DATE '2022-01-01'                     AS start_date ,
        DATEADD( day , -1 ,
                 DATE_TRUNC( 'month' , CURRENT_DATE ) ) AS end_date   -- last full month
),

/* list of every month in the window                                              */
months AS (
    SELECT DATEADD( month , seq4() ,
                    DATE_TRUNC('month', db.start_date) )  AS month_start
    FROM   date_bounds db ,
           TABLE( GENERATOR( ROWCOUNT => 120 ) )                 -- enough months
    WHERE  DATEADD( month , seq4() ,
                    DATE_TRUNC('month', db.start_date) ) <= db.end_date
),

/* dollars sold per category per month                                            */
sales_filtered AS (
    SELECT
        DATE_TRUNC( 'month', s."date")         AS month_start ,
        s."category_name"                      AS category_name ,
        SUM( s."sale_dollars")                 AS monthly_sales
    FROM   IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES  s
           ,date_bounds db
    WHERE  s."date" >= db.start_date
      AND  s."date" <= db.end_date
    GROUP  BY 1,2
),

/* total dollars per month (all categories)                                       */
monthly_totals AS (
    SELECT month_start , SUM( monthly_sales ) AS total_sales
    FROM   sales_filtered
    GROUP  BY month_start
),

/* category share (%) of monthly total                                            */
category_month_pct AS (
    SELECT
        sf.month_start ,
        sf.category_name ,
        sf.monthly_sales / mt.total_sales     AS pct
    FROM   sales_filtered sf
    JOIN   monthly_totals  mt USING ( month_start )
),

/* every category x every month (missing months → 0)                              */
category_month_full AS (
    SELECT
        m.month_start ,
        c.category_name ,
        COALESCE( cmp.pct , 0 )               AS pct
    FROM  ( SELECT DISTINCT category_name FROM category_month_pct ) c
    CROSS JOIN months m
    LEFT  JOIN category_month_pct cmp
           ON  cmp.category_name = c.category_name
           AND cmp.month_start   = m.month_start
),

/* keep categories that satisfy the 1 % & 24‑month rules                          */
qualified_categories AS (
    SELECT
        category_name ,
        SUM( CASE WHEN pct>0 THEN 1 ELSE 0 END )         AS months_positive ,
        AVG( pct )                                       AS avg_pct
    FROM   category_month_full
    GROUP  BY category_name
    HAVING months_positive >= 24
       AND avg_pct        >= 0.01          -- ≥ 1 %
),

qualified_data AS (
    SELECT  cmf.month_start , cmf.category_name , cmf.pct
    FROM    category_month_full cmf
    JOIN    qualified_categories qc
           ON cmf.category_name = qc.category_name
),

/* Pearson correlation between every qualified category pair                      */
pair_correlations AS (
    SELECT
        d1.category_name        AS cat1 ,
        d2.category_name        AS cat2 ,
        CORR( d1.pct , d2.pct ) AS corr_coeff
    FROM   qualified_data d1
    JOIN   qualified_data d2
           ON  d1.month_start   = d2.month_start
           AND d1.category_name < d2.category_name        -- unique ordered pairs
    GROUP  BY cat1 , cat2
    ORDER  BY corr_coeff ASC NULLS LAST
    LIMIT  1                                                -- lowest correlation
)

SELECT cat1  AS category_name_1 ,
       cat2  AS category_name_2
FROM   pair_correlations;