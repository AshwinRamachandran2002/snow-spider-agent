/*  Average projected monthly sales (USD) for France – Year 2021  */
WITH france           AS (  -- France’s country_id
    SELECT "country_id"
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE.COUNTRIES
    WHERE  "country_name" = 'France'
), sales_19_20 AS (        -- historical sales 2019-2020 (France, promo_total_id=1, channel_total_id=1)
    SELECT
           s."prod_id",
           t."calendar_month_number"                           AS "month_no",
           t."calendar_month_name"                             AS "month_name",
           SUM(CASE WHEN t."calendar_year" = 2019 THEN s."amount_sold" ELSE 0 END) AS "sales_2019",
           SUM(CASE WHEN t."calendar_year" = 2020 THEN s."amount_sold" ELSE 0 END) AS "sales_2020"
    FROM   COMPLEX_ORACLE.COMPLEX_ORACLE.SALES      s
           JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS   cu ON cu."cust_id"   = s."cust_id"
           JOIN france                                      f ON f."country_id" = cu."country_id"
           JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.PROMOTIONS  p  ON p."promo_id"   = s."promo_id"
                                                            AND p."promo_total_id" = 1
           JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.CHANNELS    ch ON ch."channel_id" = s."channel_id"
                                                            AND ch."channel_total_id" = 1
           JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES       t  ON t."time_id"    = s."time_id"
    WHERE  t."calendar_year" IN (2019,2020)
    GROUP BY
           s."prod_id",
           t."calendar_month_number",
           t."calendar_month_name"
), projected_local AS (     -- 2021 projection in local currency
    SELECT
           "prod_id",
           "month_no",
           "month_name",
           CASE
              WHEN NVL("sales_2019",0) = 0
                 THEN NVL("sales_2020",0)                                   -- no 2019 base: keep 2020 value
              ELSE NVL("sales_2020",0) *
                   (1 + (NVL("sales_2020",0) - NVL("sales_2019",0))
                          / NULLIF("sales_2019",0) )                         -- growth applied
           END AS "proj_2021_local"
    FROM   sales_19_20
), projected_usd AS (       -- convert to USD with 2021 FX rates
    SELECT
           pl."prod_id",
           pl."month_no",
           pl."month_name",
           pl."proj_2021_local"
           * NVL(cur."to_us",1)                                             -- default rate =1 when missing
             AS "proj_2021_usd"
    FROM   projected_local                       pl
           LEFT JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.CURRENCY cur
             ON cur."country" = 'France'
             AND cur."year"  = 2021
             AND cur."month" = pl."month_no"
)
SELECT
       "month_no",
       "month_name",
       ROUND(AVG("proj_2021_usd"),2) AS "avg_projected_monthly_sales_usd"
FROM   projected_usd
GROUP  BY "month_no","month_name"
ORDER  BY "month_no";