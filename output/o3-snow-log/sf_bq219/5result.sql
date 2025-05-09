/*  1.  Parameters – analysis starts 2022-01-01 and ends with the last day of the
        most recently finished month (i.e., the day before the current month).   */
WITH params AS (
    SELECT
        DATE '2022-01-01'                               AS start_date ,
        LAST_DAY( DATEADD( MONTH , -1 , CURRENT_DATE ) ) AS end_date
),

/*  2.  All month-starts in the analysis window                                          */
months AS (
    SELECT DATE_TRUNC(
               'month',
               DATEADD( MONTH , seq4() , (SELECT start_date FROM params) )
           ) AS month_start
    FROM TABLE( GENERATOR( ROWCOUNT => 120 ) )              -- covers up to 10 years
    WHERE DATE_TRUNC(
              'month',
              DATEADD( MONTH , seq4() , (SELECT start_date FROM params) )
          ) <= DATE_TRUNC( 'month', (SELECT end_date FROM params) )
),

/*  3.  Volume per category per month                                                   */
sales_base AS (
    SELECT
        DATE_TRUNC( 'month', "date" )       AS month_start ,
        "category_name"                     AS category_name ,
        SUM( "volume_sold_liters" )         AS vol_liters
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
    WHERE "date" BETWEEN (SELECT start_date FROM params)
                     AND (SELECT end_date   FROM params)
      AND "category_name" IS NOT NULL
    GROUP BY 1, 2
),

/*  4.  Monthly total volume                                                            */
monthly_totals AS (
    SELECT month_start,
           SUM( vol_liters ) AS total_vol
    FROM sales_base
    GROUP BY month_start
),

/*  5.  Ensure every category has a row for every month (fill zeroes)                   */
cat_month_expanded AS (
    SELECT
        m.month_start ,
        c.category_name ,
        COALESCE( sb.vol_liters , 0 ) AS vol_liters
    FROM months m
    CROSS JOIN ( SELECT DISTINCT category_name FROM sales_base ) c
    LEFT JOIN  sales_base sb
           ON  sb.month_start   = m.month_start
           AND sb.category_name = c.category_name
),

/*  6.  Percentage share each month                                                     */
cat_pct AS (
    SELECT
        cm.category_name ,
        cm.month_start ,
        cm.vol_liters / mt.total_vol AS pct_of_month
    FROM cat_month_expanded cm
    JOIN monthly_totals  mt
      ON cm.month_start = mt.month_start
),

/*  7.  Categories that (a) appear in ≥24 months  (b) average ≥1 % share                */
valid_categories AS (
    SELECT category_name
    FROM   cat_pct
    GROUP  BY category_name
    HAVING COUNT(*)              >= 24
       AND AVG( pct_of_month )   >= 0.01
),

filtered_pct AS (
    SELECT cp.*
    FROM   cat_pct cp
    JOIN   valid_categories vc
      ON   cp.category_name = vc.category_name
),

/*  8.  Pairwise Pearson correlations                                                   */
pair_correlations AS (
    SELECT
        a.category_name AS category_1 ,
        b.category_name AS category_2 ,
        CORR( a.pct_of_month , b.pct_of_month ) AS corr_coef
    FROM  filtered_pct a
    JOIN  filtered_pct b
          ON  a.month_start   = b.month_start
          AND a.category_name < b.category_name      -- avoid duplicates/self pairs
    GROUP BY
        a.category_name ,
        b.category_name
)

/*  9.  Return the pair with the lowest correlation                                     */
SELECT
    category_1 ,
    category_2
FROM pair_correlations
ORDER BY corr_coef ASC NULLS LAST
LIMIT 1;