WITH "FRANCE"            AS (  -- get France country_id once
        SELECT "country_id"
        FROM   "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES"
        WHERE  "country_name" = 'France' ),

/*--------------------------------------------------------------------
  1)  Sales made in France only, through channels with CHANNEL_TOTAL_ID = 1
      and promotions with PROMO_TOTAL_ID = 1, for the years 2019-2020.
--------------------------------------------------------------------*/
     "FILTERED_SALES" AS (
        SELECT  s."prod_id",
                t."calendar_month_number"              AS "month_num",
                t."calendar_year"                      AS "year",
                s."amount_sold"
        FROM   "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES"       s
        JOIN   "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS"   c
               ON  s."cust_id" = c."cust_id"
        JOIN   "FRANCE" f
               ON  c."country_id" = f."country_id"
        JOIN   "COMPLEX_ORACLE"."COMPLEX_ORACLE"."PROMOTIONS"  p
               ON  s."promo_id" = p."promo_id"
               AND p."promo_total_id" = 1
        JOIN   "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CHANNELS"    ch
               ON  s."channel_id" = ch."channel_id"
               AND ch."channel_total_id" = 1
        JOIN   "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES"       t
               ON  s."time_id" = t."time_id"
        WHERE  t."calendar_year" IN (2019, 2020)
     ),

/*--------------------------------------------------------------------
  2)  Aggregate 2019 & 2020 sales per product and month.
--------------------------------------------------------------------*/
     "AGG" AS (
        SELECT  "prod_id",
                "month_num",
                SUM(CASE WHEN "year" = 2019 THEN "amount_sold" END)  AS "sales_2019",
                SUM(CASE WHEN "year" = 2020 THEN "amount_sold" END)  AS "sales_2020"
        FROM    "FILTERED_SALES"
        GROUP BY "prod_id", "month_num"
     ),

/*--------------------------------------------------------------------
  3)  Project 2021 sales using the provided formula.
--------------------------------------------------------------------*/
     "PROJECTION" AS (
        SELECT  "prod_id",
                "month_num",
                /* (((2020-2019)/2019) * 2020) + 2020 */
                CASE 
                     WHEN "sales_2019" IS NULL 
                          OR "sales_2019" = 0 THEN NULL      -- avoid div/0
                     ELSE  "sales_2020" 
                           + ( ("sales_2020" - "sales_2019") / "sales_2019") 
                             * "sales_2020"
                END                                           AS "proj_2021_local"
        FROM    "AGG"
        WHERE   "sales_2020" IS NOT NULL
     ),

/*--------------------------------------------------------------------
  4)  2021 FX rates (to USD).  Default to 1 when missing.
--------------------------------------------------------------------*/
     "USD_RATES" AS (
        SELECT  "month", "to_us"
        FROM    "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CURRENCY"
        WHERE   "country" = 'France'
          AND   "year"    = 2021
     ),

/*--------------------------------------------------------------------
  5)  Convert projected amounts to USD.
--------------------------------------------------------------------*/
     "PROJECTION_USD" AS (
        SELECT  p."month_num",
                COALESCE(u."to_us",1) * p."proj_2021_local"   AS "proj_2021_usd"
        FROM    "PROJECTION" p
        LEFT JOIN "USD_RATES" u
               ON p."month_num" = u."month"
        WHERE   p."proj_2021_local" IS NOT NULL
     )

/*--------------------------------------------------------------------
  6)  Average projected sales per month (across products).
--------------------------------------------------------------------*/
SELECT   "month_num"                                    AS "MONTH",
         ROUND( AVG("proj_2021_usd"), 2 )               AS "AVG_PROJECTED_SALES_USD"
FROM     "PROJECTION_USD"
GROUP BY "month_num"
ORDER BY "month_num";