WITH french_sales AS (   -- ❶  France sales (2019-2020) that met the promo & channel filters
    SELECT
        s."prod_id",
        s."amount_sold",
        t."calendar_year"          AS "year",
        t."calendar_month_number"  AS "month"
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE."SALES"      s
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS"  c   ON s."cust_id"  = c."cust_id"
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES"  co  ON c."country_id" = co."country_id"
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE."PROMOTIONS" p   ON s."promo_id" = p."promo_id"
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE."CHANNELS"   ch  ON s."channel_id" = ch."channel_id"
    JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES"      t   ON s."time_id"  = t."time_id"
    WHERE  co."country_name"  = 'France'          --  France only
      AND  p."promo_total_id" = 1                 --  required promotions
      AND  ch."channel_total_id" = 1              --  required channels
      AND  t."calendar_year" IN (2019,2020)       --  history years
),  
agg_sales AS (         -- ❷  monthly product totals for 2019 & 2020
    SELECT
        "prod_id",
        "month",
        SUM(CASE WHEN "year" = 2019 THEN "amount_sold" END) AS "sales_2019",
        SUM(CASE WHEN "year" = 2020 THEN "amount_sold" END) AS "sales_2020"
    FROM french_sales
    GROUP BY "prod_id","month"
),    
proj_local AS (        -- ❸  project 2021 sales in original (local) currency
    SELECT
        "prod_id",
        "month",
        CASE
             WHEN "sales_2020" IS NULL                                 THEN NULL                -- no 2020 data
             WHEN "sales_2019" IS NULL OR "sales_2019" = 0             THEN "sales_2020"        -- cannot calc growth
             ELSE "sales_2020" * ( 1 + ( "sales_2020" - "sales_2019") / "sales_2019" )
        END AS "proj_2021_local"
    FROM agg_sales
),    
proj_usd AS (          -- ❹  convert projection to USD using 2021 FX rate
    SELECT
        pl."prod_id",
        pl."month",
        pl."proj_2021_local" * COALESCE(cu."to_us",1) AS "proj_2021_usd"
    FROM  proj_local pl
    LEFT JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CURRENCY" cu
           ON cu."country" = 'France'
          AND cu."year"    = 2021
          AND cu."month"   = pl."month"
)
-- ❺  average projected 2021 USD sales per month
SELECT
    pu."month"                                    AS "MONTH_NUMBER",
    MIN(t."calendar_month_name")                  AS "MONTH_NAME",
    ROUND(AVG(pu."proj_2021_usd"),2)              AS "AVG_PROJECTED_SALES_USD"
FROM   proj_usd                    pu
JOIN   COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES" t
       ON t."calendar_year"        = 2021
      AND t."calendar_month_number"= pu."month"
GROUP  BY pu."month"
ORDER  BY pu."month" ASC NULLS LAST;