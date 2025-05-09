WITH  max_date_cte AS (               -- latest transaction date in the table
        SELECT MAX("date") AS max_date
        FROM   IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
     ),

      last_full_month_cte AS (        -- first day of the last fully-completed month
        SELECT DATE_TRUNC(
                 'month',
                 CASE WHEN max_date = LAST_DAY(max_date)
                      THEN max_date
                      ELSE DATEADD(month, -1, max_date)
                 END)        AS last_full_month_start
        FROM   max_date_cte
     ),

/* --------------------------------------------------------------------------
   Build month-by-category percentages (share of litres sold each month)
   for all data from 1-Jan-2022 through the last fully-completed month.
-------------------------------------------------------------------------- */
      monthly_pct AS (
        SELECT
               DATE_TRUNC('month', s."date")                        AS month,
               s."category_name",
               SUM(s."volume_sold_liters")                          AS category_volume,
               SUM(SUM(s."volume_sold_liters"))
                 OVER (PARTITION BY DATE_TRUNC('month', s."date"))  AS month_total_volume,
               SUM(s."volume_sold_liters") /
               SUM(SUM(s."volume_sold_liters"))
                 OVER (PARTITION BY DATE_TRUNC('month', s."date"))  AS pct_of_month
        FROM   IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES s
        CROSS  JOIN last_full_month_cte lfm
        WHERE  s."date" >= '2022-01-01'
          AND  s."date" <  DATEADD(month, 1, lfm.last_full_month_start)
        GROUP  BY month, s."category_name"
     ),

/* --------------------------------------------------------------------------
   Keep only the categories that
   • appear in at least 24 months, and
   • average at least 1 % of total monthly volume.
-------------------------------------------------------------------------- */
      eligible_categories AS (
        SELECT  "category_name",
                COUNT(*)      AS months_present,
                AVG(pct_of_month) AS avg_monthly_pct
        FROM    monthly_pct
        GROUP   BY "category_name"
        HAVING  months_present >= 24
           AND  avg_monthly_pct >= 0.01              -- 1 %
     ),

/* --------------------------------------------------------------------------
   Monthly percentage table restricted to those eligible categories.
-------------------------------------------------------------------------- */
      filtered AS (
        SELECT  mp.month,
                mp."category_name",
                mp.pct_of_month
        FROM    monthly_pct mp
        JOIN    eligible_categories ec
          ON    mp."category_name" = ec."category_name"
     ),

/* --------------------------------------------------------------------------
   Pairwise Pearson correlations of monthly shares.
-------------------------------------------------------------------------- */
      pair_correlations AS (
        SELECT
               f1."category_name"                      AS category_1,
               f2."category_name"                      AS category_2,
               CORR(f1.pct_of_month, f2.pct_of_month)  AS pearson_corr
        FROM   filtered f1
        JOIN   filtered f2
               ON f1.month = f2.month
              AND f1."category_name" < f2."category_name"  -- avoid duplicates/self-join
        GROUP  BY category_1, category_2
     )

/* --------------------------------------------------------------------------
   Return the pair with the lowest correlation.
-------------------------------------------------------------------------- */
SELECT  category_1, category_2
FROM    pair_correlations
ORDER BY pearson_corr ASC NULLS LAST
LIMIT 1;